// Command line tools to generate hashed point data.
//
// TODO: support parseKml
// TODO: --remove-weekdays --timezone
// TODO: --compress: to use gzip to compress data.
//
"use strict";

const fs = require("fs");
const yargs = require("yargs");

const sthash = require("../lib_sthash.js");
const parsers = require("../parsers.js");

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
var points = parsers.parseJson(text);

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
          STDERR.write("IGNORED: " + latlng + " \"" + point.name + "\"\n");
          shown = true;
        }
      } else {
        new_points.push(point);
      }
    }
    points = new_points;
  }
}

let all_hashes = {};
for (let point of points) {
  var hashes = sthash.hashSpacetime(hash_key, point.begin, point.end, point.lat, point.lng);
  for (let hash of hashes) {
    all_hashes[hash] = desc;
  }
}

let space = argv.pretty ? 2 : 0;
let out_data = JSON.stringify(all_hashes, null, space);

if (argv.output != undefined) {
  fs.writeFile(argv.output, out_data, function (err) {
    if (err) throw err;
  });
} else {
  STDOUT.write(out_data);
}
