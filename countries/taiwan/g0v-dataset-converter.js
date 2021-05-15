const fs = require('fs');
const yargs = require('yargs');

const meta = require('../../meta');
const parser = require('../../parsers');


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
  .option('meta', {
      alias: 'm',
      description: 'Specify the metadata filename',
      type: 'string',
  })
  .option('pretty', {
      description: 'Pretty output',
      type: 'boolean',
  })
  .help()
  .alias('help', 'h')
  .argv;

const input_filename = (argv.input === undefined) ? '/dev/stdin' : argv.input;
const input_text = fs.readFileSync(input_filename, 'utf-8');
const input_object = JSON.parse(input_text);

const output_object = []
const meta_file = meta.Meta(argv.meta);

function ConvertName(props) {
  return {
    'zh-TW': `${props.name} ${props['duration (text)']}`,
    'en-US': `${props.name_en} ${props['duration (text)']}`,
  }
}

function ConvertPoint(geometry, props) {
  const lng = Math.round(geometry.coordinates[0] * 1e7);
  const lat = Math.round(geometry.coordinates[1] * 1e7);
  meta_file.insert_bounding_box(lat, lng);
  return {
    placeVisit: {
      location: {
        latitudeE7: lat,
        longitudeE7: lng,
        name: ConvertName(props),
      },
      duration: {
        startTimestampMs: props.begin,
        endTimestampMs: props.end,
      },
    }
  };
}

function ConvertLineString(geomtry, props) {
  const coords = [];
  for (let e of geomtry.coordinates) {
    coords.push({lng: e[0], lat: e[1]});
  }
  const points = intrapolateCoords(coords, props, ConvertName(props));
  return points.map(p => {
    const lng = Math.round(p.lng * 1e7);
    const lat = Math.round(p.lat * 1e7);
    meta_file.insert_bounding_box(lat, lng);
    return {
      placeVisit: {
        location: {
          latitudeE7: lat,
          longitudeE7: lng,
          name: p.name,
        },
        duration: {
          duration: p.begin,
          duration: p.end,
        }
      }
    }
  });
}

function ConvertPolygon(geomtry, props) {
  const name = ConvertName(props);
  const results = [];
  for (let i = 0; i < geomtry.coordinates.length; i++) {
    const source = geomtry.coordinates[i];
    const coords = [];
    for (let j = 0; j < source.length; j++) {
      let lng = Math.round(source[j][0] * 1e7);
      let lat = Math.round(source[j][1] * 1e7);
      meta_file.insert_bounding_box(lat, lng);
      coords.push({lng: source[j][0], lat: source[j][1]});
    }
    results.push({
      placeVisit: {
        polygon: {
          outer_boundary: coords,
          name: name,
        },
        duration: {
          begin: props.begin,
          end: props.end,
        }
      },
    });
  }
  return results;
}

function main() {
  if (input_object.type !== 'FeatureCollection') {
    console.error('Root type should be FeatureCollection');
    return;
  }

  const features = input_object.features;
  console.log(features.length);
  for (let feature of features) {
    if (feature.type !== 'Feature') {
      console.error('Incorrect feature type, ', feature);
      continue;
    }

    const geometry = feature.geometry;
    const props = feature.properties;

    props.begin = (new Date(props.begin)).getTime();
    props.end = (new Date(props.end)).getTime();

    //console.log(properties['duration (text)'], properties.begin);
    switch (geometry.type) {
      case 'Point':
        output_object.push(ConvertPoint(geometry, props));
        break;
      case 'LineString':
        output_object.push(...ConvertLineString(geomtry, props));
        break;
      case 'Polygon':
        output_object.push(...ConvertPolygon(geometry, props));
        break;
    }
  }

  let space = argv.pretty ? 2 : 0;
  let out_text = JSON.stringify({
    timelineObjects: output_object,
  }, null, space);
  fs.writeFile(argv.output, out_text, function (err) {
    if (err) throw err;
  });

  // Output meta data
  meta_file.output();
}

main();
