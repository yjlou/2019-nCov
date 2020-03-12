// Data from https://services5.arcgis.com/dlrDjz89gx9qyfev/arcgis/rest/services/Corona_Exposure_View/FeatureServer/0/query?f=json&where=1%3D1&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&maxRecordCountFactor=4&outSR=4326&resultOffset=0&resultRecordCount=8000&cacheHint=true
//

// TODO(stimim): rename utils files...
const common_utils = require("../../utils.js");
const fs = require("fs");
const time_utils = require("./utils");
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
const json_obj = common_utils.myJsonParse(input_text);

let out_obj = [];
for(let record of json_obj['features']) {
  // record = {
  //   u'attributes': {
  //     u'Comments': u'...',
  //     u'Name': u'\u05d7\u05d5\u05dc\u05d4 15',
  //     u'OBJECTID': 1201,
  //     u'POINT_X': 34.80773124,
  //     u'POINT_Y': 32.11549963,
  //     u'Place': u'...',
  //     u'fromTime': 1583144100000,  // this is 10:15
  //     u'sourceOID': 1,
  //     u'stayTimes': u'10:15-11:15',
  //     u'toTime': 1583147700000  // this is 11:15
  //   },
  //   u'geometry': {u'x': 34.807731241000056, u'y': 32.115499628000066}}
  // }
  const attributes = record.attributes;
  const geometry = record.geometry;

  const lat = parseFloat(geometry.y);
  const lng = parseFloat(geometry.x);

  // TODO(stimim): Should we add some margin before and after the record day?
  const start = attributes.fromTime - time_utils.TIME_OFFSET;
  const end = attributes.toTime - time_utils.TIME_OFFSET;

  out_obj.push({
    placeVisit: {
      location: {
        latitudeE7: lat * 10000000,
        longitudeE7: lng * 10000000,
        name : `ID=${attributes.OBJECTID} ${attributes.Name} ${attributes.Comments}`,
      },
      duration: {
        startTimestampMs: start,
        endTimestampMs: end,
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
