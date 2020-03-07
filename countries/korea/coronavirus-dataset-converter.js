// Convert data from https://github.com/jihoo-kim/Coronavirus-Dataset/
//

const csv_parse = require("csv-parse/lib/sync");
const fs = require("fs");
const utils = require("./utils");
const yargs = require("yargs");

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
    .option('pretty', {
        description: 'Pretty output',
        type: 'boolean',
    })
    .help()
    .alias('help', 'h')
    .argv;

///// Start of program //////

const input_filename = (argv.input === undefined) ? '/dev/stdin' : argv.input;
const input_text = fs.readFileSync(input_filename, 'utf-8');
const records = csv_parse(input_text, {
  bom: true,  // currently the CSV doesn't have BOM, just in case.
  columns: true,
  skip_empty_lines: true,
});

let out_obj = [];
for(let record of records) {
  // columns should be: id,date,province,city,visit,latitude,longitude
  //   id: the ID of the patient (n-th confirmed patient)
  //   date: Year-Month-Day
  //   province: Special City / Metropolitan City / Province(-do)
  //   city: City(-si) / Country (-gun) / District (-gu)
  //   visit: the type of place visited
  //   latitude
  //   longitude
  const lat = parseFloat(record['latitude']);
  const lng = parseFloat(record['longitude']);

  const date = record['date'];  // should be YYYY-mm-dd
  const [year, month, day] = date.split('-').map(s => parseInt(s, 10));
  const timestamp = utils.KrDateToTimestampMs(year, month, day);

  out_obj.push({
    placeVisit: {
      location: {
        latitudeE7: lat * 10000000,
        longitudeE7: lng * 10000000,
        // Should we remove case ID?
        name : `Case#${record.id} ${record.province} ${record.city} ${record.visit}`,
      },
      duration: {
        startTimestampMs: timestamp,
        endTimestampMs: timestamp + 24 * 60 * 60 * 1000,  // The whole day.
      },
    }
  });
}

let space = argv.pretty ? 2 : 0;
let out_text = JSON.stringify({
  timelineObjects: out_obj,
}, null, space);

// Output to medium.
if (argv.output != undefined) {
  fs.writeFile(argv.output, out_text, function (err) {
    if (err) throw err;
  });
} else {
  STDOUT.write(out_text);
}

// Show some numbers.
STDERR.write("OUTPUT: " + out_obj.length + " records, " +
                          out_text.length + " bytes.\n");
