/**
 * Given multiple input files (JSON/KML), merge them into one large JSON file (the Takeout format).
 *
 * An example to use this script:
 *
 *   % find DIR -name "*.json" -o -name ""*.kml" -exec echo -n '"{}" ' \; |  \
 *       xargs nodejs merge.js -o OUT_FILE.json
 *
 */

const fs = require("fs");
const yargs = require("yargs");
const xml_parser = require('fast-xml-parser');
const file_parser = require('../parsers.js');

const STDOUT = process.stdout;
const STDERR = process.stderr;

const argv = yargs
    .demandCommand(1)
    .option('output', {
      alias: 'o',
      description: 'Specify the output filename',
      type: 'string',
    })
    .option('pretty', {
      description: 'pretty output',
      type: 'boolean',
    })
    .usage('Usage: $0 input_file ... [options]')
    .help().alias('help', 'h')
    .argv;


function main() {
  // Read inputs from each file listed in arguments.
  let all_points = [];
  argv._.forEach((input_filename) => {
    const input_text = fs.readFileSync(input_filename, 'utf-8');
    const ps = file_parser.parseFile(input_filename, input_text);
    console.log(`Loaded ${ps.length} points from ${input_filename}`);
    all_points = all_points.concat(ps);
  });

  // Convert it to Takeout format
  let out_obj = [];
  for (let p of all_points) {
    if (p.type === 'polygon') {
      out_obj.push({
        placeVisit: {
          polygon: {
            outer_boundary: p.outer_boundary,
            name: p.name,
          },
          duration: {
            startTimestampMs: p.begin * 1000,
            endTimestampMs: p.end * 1000,
          }
        }
      });
    } else {
      out_obj.push({
        placeVisit: {
          location: {
            latitudeE7: p.lat * 1e7,
            longitudeE7: p.lng * 1e7,
            name: p.name,
          },
          duration: {
            startTimestampMs: p.begin * 1000,
            endTimestampMs: p.end * 1000,
          }
        }
      });
    }
  }

  // Output to file (or STDOUT)
  let out_file = argv.output ? argv.output : "/dev/stdout";
  let space = argv.pretty ? 2 : 0;
  let out_text = JSON.stringify({
    timelineObjects: out_obj,
  }, null, space);
  fs.writeFile(out_file, out_text, function (err) {
    if (err) throw err;
  });
}

main();
