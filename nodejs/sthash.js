// To protect patient's privacy, we employ a simple hash algorithm called ST hash (SpaceTime hash)
// to hash (time point, lat, lng) into a 64-bit value. Then, when user wants to compare their
// historical track, they follow the same hash algorithm. If a conflict happens, it means the user
// and the patient have had met at a particular spacetime point.
//
// The following commands are used to generate the hashed JSON file.
//
// ```
//   # Node.js v12.x:
//   curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
//   sudo apt-get install -y nodejs
//   npm install js-sha256 fs yargs fast-xml-parser csv-parse
//
//   node nodejs/sthash.js
//   node nodejs/sthash.js -d "your description" --remove_top 3
//                         -i INPUT_FILE.{kml|json} -o OUTPUT_FILE-hashed.json
// ```
//
// Once the hashed JSON is generated, host it in somewhere (remember to enable Allow- headers
// so that it follows the CORS policy), and use hashes= parameter in the URL to load it:
//
// ```
//   https://pandemic.events/?hashes=YOUR_HASHED_FILE_URL
// ```
//
// TODO: --remove-weekdays --timezone
// TODO: --compress: to use gzip to compress data.
//
"use strict";

const fs = require("fs");
const yargs = require("yargs");

const sthash = require("../lib_sthash.js");
const parsers = require("../parsers.js");
const utils = require("../utils.js");

const STDOUT = process.stdout;
const STDERR = process.stderr;

const argv = yargs
    .option('input', {
        alias: 'i',
        description: 'Specify the input filename',
        type: 'string',
    })
    .option('output', {
        alias: 'o',
        description: 'Specify the output filename',
        type: 'string',
    })
    .option('desc', {
        alias: 'd',
        description: 'Description for hash value',
        type: 'string',
    })
    .option('key', {
        alias: 'k',
        description: 'Hash key',
        type: 'string',
    })
    .option('remove_top', {
        alias: 'r',
        description: 'Remove top visited N places',
        type: 'number',
    })
    .option('pretty', {
        description: 'Pretty output',
        type: 'boolean',
    })
    .option('time_quan', {
        description: 'Time quantization duration (in mins)',
        type: 'number',
        default: 10,
    })
    .option('shuffle', {
        description: 'Shuffle location (default: -5: ~15 meters)',
        type: 'number',
        default: -5,
    })
    .option('latlng_quan', {
        description: 'lat/lng quantization scale (default: -4)',
        type: 'number',
        default: -4,
    })
    .option('spread_out', {
        description: 'spread_out (default: 5)',
        type: 'number',
        default: 5,
    })
    .help()
    .alias('help', 'h')
    .argv;

let desc = argv.desc;
if (desc == undefined) {
  desc = "";
}

let hash_key;
if (argv.key != undefined) {
  hash_key = argv.key;
} else {
  hash_key = sthash.DEFAULT_HASH_KEY;
}

let input_filename = (argv.input != undefined) ? argv.input : "/dev/stdin";
let text = fs.readFileSync(input_filename, 'utf-8');
var points = parsers.parseFile(undefined, text);

if (argv.remove_top) {
  // Count all of them.
  let counts = {};
  for (let point of points) {
    let latlng = point.lat + "," + point.lng;
    if (counts[latlng] != undefined) {
      counts[latlng]++;
    } else {
      counts[latlng] = 1;
    }
  }

  // Convert to an array for sorting
  let top_n = Array();
  for(let [latlng, count] of Object.entries(counts)) {
    top_n.push([count, latlng]);
  }
  top_n.sort(function(a, b) { return b[0] - a[0]; });
  top_n = top_n.slice(0, argv.remove_top);

  // remove from the list
  for(let [_, latlng] of top_n) {
    let [lat, lng] = latlng.split(",");

    let shown = false;
    let new_points = Array();
    for(let point of points) {
      if (lat == point.lat.toString() && lng == point.lng.toString()) {
        // ignore
        if (!shown) {
          STDERR.write("REMOVED: " + latlng + " \"" + point.name + "\"\n");
          shown = true;
        }
      } else {
        new_points.push(point);
      }
    }
    points = new_points;
  }
}

// First hash all points in a dictionary (for dedup). Then abstract the dict keys.
let all_hashes_dict = {};
for (let point of points) {
  let lat = utils.shuffleFloat(point.lat, argv.shuffle, argv.shuffle - 3);
  let lng = utils.shuffleFloat(point.lng, argv.shuffle, argv.shuffle - 3);
  let hashes = sthash.hashSpacetime(hash_key, point.begin, point.end, lat, lng,
                                    argv.time_quan, argv.latlng_quan, argv.spread_out);
  for (let hash of hashes) {
    all_hashes_dict[hash] = 1;
  }
}
let all_hashes = Object.keys(all_hashes_dict);

// Generate the output data.
let space = argv.pretty ? 2 : 0;
let out_data = JSON.stringify({
        desc: desc,
        hashes: all_hashes,
    }, null, space);

// Output to medium.
if (argv.output != undefined) {
  fs.writeFile(argv.output, out_data, function (err) {
    if (err) throw err;
  });
} else {
  STDOUT.write(out_data);
}

// Show some numbers.
STDERR.write("OUTPUT: " + points.length + " points, " +
                          Object.values(all_hashes).length + " hashes, and " +
                          out_data.length + " bytes.\n");
