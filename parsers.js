"use strict";

if (this.DOMParser == undefined) {
  // node.js
  var parser = require('fast-xml-parser');
  var utils = require('./utils.js');
  var convKmlDateToTimestamp = utils.convKmlDateToTimestamp;
  var getDistanceFromLatLonInMeters = utils.getDistanceFromLatLonInMeters;
}

// JS code used in both broswer and nodejs
(function(exports){
  exports.parseKml = parseKml;
  exports.parseJson = parseJson;
  exports.parseFile = parseFile;
}(typeof exports === 'undefined' ? this.parsers = {} : exports));

function tryParseName(placemark) {
  return placemark.name;
}

function tryParseTimeSpan(placemark) {
  const timespan = placemark.TimeSpan;
  if (timespan != undefined) {
    const time_begin = timespan.begin;
    const time_end = timespan.end;
    return {
      begin: parseFloat(convKmlDateToTimestamp(time_begin.trim())),
      end: parseFloat(convKmlDateToTimestamp(time_end.trim())),
    }
  } else {
    // TODO: How about throwing an exception instead?
    console.error("Invalid timespan data: ", placemark);
    return null;
  }
}

function tryParsePoint(placemark) {
  var latlng = "";

  const point = placemark.Point;

  if (point == undefined) {
    // Not point data. Maybe LineString data. Discard.
    return null;
  }

  // "-122.02223289999999,37.338164,0"
  latlng = point.coordinates;

  const name = tryParseName(placemark);
  const timespan = tryParseTimeSpan(placemark);
  if (timespan === null) {
    return null;
  }

  return [{
    'lat': parseFloat(latlng.split(",")[1].trim()),
    'lng': parseFloat(latlng.split(",")[0].trim()),
    'begin': timespan.begin,
    'end': timespan.end,
    'name': name,
  }];
}

function intrapolateCoords(coords, timespan, name) {
  const delta_t = timespan.end - timespan.begin;  // seconds
  let total_dist = 0;

  const segment_dist = [0];
  for (let i = 1; i < coords.length; i++) {
    const d = getDistanceFromLatLonInMeters(
      coords[i - 1].lat, coords[i - 1].lng,
      coords[i].lat, coords[i].lng
    );
    segment_dist.push(d);
    total_dist += d;
  }

  if (total_dist == 0) {
    // The user is not moving at all...
    // Return a single point.
    return [
      {
        lat: coords[0].lat,
        lng: coords[0].lng,
        begin: timespan.begin,
        end: timespan.end,
        name: name,
      }
    ];
  }

  const retval = [];
  let current_t = timespan.begin;
  // Convert the LineString into points such that point[i] and point[i + 1] are
  // at most 100 meters away.
  // Assume that the user is moving in a constant speed.
  for (let i = 1; i < coords.length; i++) {
    const segment_t = delta_t * segment_dist[i] / total_dist;

    const num_seg = Math.ceil(segment_dist[i] / 100);
    const [px, py] = [coords[i - 1].lat, coords[i - 1].lng];
    const [qx, qy] = [coords[i].lat, coords[i].lng];

    /*
     * E.g. num_seg = 6
     *
     *  p                       q  (coords[i - 1] and coords[i])
     *  |---|---|---|---|---|---|
     *    0   1   2   3   4   5
     *  b                       e  (time: begin and end)
     *
     *  Use the middle point of each segment as coordinate.
     */
    for (let j = 0; j < num_seg; ++j) {
      const r = (j + 0.5) / num_seg;
      const begin = current_t + segment_t * (j / num_seg);
      const end = current_t + segment_t * ((j + 1) / num_seg);
      retval.push({
        // Use intrapolation.
        lat: px * (1 - r) + qx * r,
        lng: py * (1 - r) + qy * r,
        // Slightly extend the interval.
        begin: begin,
        end: end,
        name: name,
      });
    }

    current_t += segment_t;
  }
  return retval;
}

function testIntrapolateCoords() {
  {
    // Case 1, user is not moving at all.
    const timespan = {
      begin: 0,
      end: 10000
    };

    const coords = [
      {
        lat: 25.083,
        lng: 121.481,
      },
      {
        lat: 25.083,
        lng: 121.481,
      }
    ];

    EXPECT_EQ(
      [{lat: 25.083, lng: 121.481, begin: 0, end: 10000, name: 'case_1'}],
      intrapolateCoords(coords, timespan, 'case_1')
    );
  }
  {
    // Case 2, user is moving, but no more than 100 meters
    const timespan = {
      begin: 0,
      end: 10000
    };

    // This should be ~75m
    const coords = [
      {
        lat: 25.083,
        lng: 121.481,
      },
      {
        lat: 25.0835,
        lng: 121.4815,
      }
    ];

    EXPECT_EQ(
      [
        {
          lat: 25.08325,
          lng: 121.48124999999999,
          begin: 0,
          end: 10000,
          name: 'case_2'
        }
      ],
      intrapolateCoords(coords, timespan, 'case_2')
    );
  }
  {
    // Case 3, user is moving, and more than 100 meters
    const timespan = {
      begin: 0,
      end: 10000
    };

    // This should be ~150m
    const coords = [
      {
        lat: 25.083,
        lng: 121.481,
      },
      {
        lat: 25.084,
        lng: 121.482,
      }
    ];

    EXPECT_EQ(
      [
        {
          lat: 25.08325,
          lng: 121.48124999999999,
          begin: 0,
          end: 5000,
          name: "case_3"
        },
        {
          lat: 25.08375,
          lng: 121.48175,
          begin: 5000,
          end: 10000,
          name: "case_3"
        }
      ],
      intrapolateCoords(coords, timespan, 'case_3')
    );
  }
  {
    // Case 3, user is moving, and more than 100 meters
    const timespan = {
      begin: 0,
      end: 10000
    };

    // This should be ~111 meters
    const coords = [
      {
        lat: 25.083,
        lng: 121.481,
      },
      {  // ~75m away from previous point
        lat: 25.0835,
        lng: 121.4815,
      },
      {  // ~150m away from previous point
        lat: 25.0845,
        lng: 121.4825,
      },
      {  // ~75m away from previous point
        lat: 25.085,
        lng: 121.483,
      }
    ];

    EXPECT_EQ(
      [
        {
          lat: 25.08325,
          lng: 121.48124999999999,
          begin: 0,
          end: 2500.00690288375,
          name: "case_4"
        },
        {
          lat: 25.083750000000002,
          lng: 121.48175,
          begin: 2500.00690288375,
          end: 5000.006902911471,
          name: "case_4"
        },
        {
          lat: 25.08425,
          lng: 121.48225,
          begin: 5000.006902911471,
          end: 7500.006902939191,
          name: "case_4"
        },
        {
          lat: 25.08475,
          lng: 121.48275000000001,
          begin: 7500.006902939191,
          end: 10000,
          name: "case_4"
        }
      ],
      intrapolateCoords(coords, timespan, 'case_4')
    );
  }
}

function tryParseLineString(placemark) {
  const line_string = placemark.LineString;

  if (line_string == undefined) {
    // Not a LineString, does nothing.
    return null;
  }

  // TODO: check altitudeMode?
  let coords_elements = line_string.coordinates;
  if (coords_elements == undefined) {
    console.error("Invalid LineString data: ", placemark);
    return null;
  }

  const coords = [];
  for (let coord_string of coords_elements.trim().split(/\s+/)) {
    // TODO: should we check the optional altitude?
    const [lng_string, lat_string] = coord_string.split(",");
    const lng = parseFloat(lng_string.trim());
    const lat = parseFloat(lat_string.trim());
    coords.push({lng, lat});
  }

  const name = tryParseName(placemark);
  const timespan = tryParseTimeSpan(placemark);
  if (timespan === null) {
    return null;
  }

  return intrapolateCoords(coords, timespan, name);
}

function getPlacemarks(jsonObj) {
  let placemarks;

  if ("Folder" in jsonObj.kml.Document) {
    let folders = jsonObj.kml.Document.Folder;
    if (!Array.isArray(folders)) {
      folders = [folders];
    }

    placemarks = [];
    for (let folder of folders) {
      let ps = folder.Placemark;
      if (ps === undefined) {
        continue;
      }
      if (Array.isArray(ps)) {
        placemarks.push(...ps);
      } else {
        placemarks.push(ps);
      }
    }
  } else {
    placemarks = jsonObj.kml.Document.Placemark;

    // If there is no Placemark, this could be an empty KML (the day without history data).
    if (placemarks === undefined) {
      placemarks = [];
    }
    // If there is only one record in that day, the placemark would be that record
    // instead of an array of records.
    else if (!Array.isArray(placemarks)) {
      placemarks = [placemarks];
    }
  }
  return placemarks;
}

// Given a KML text, returns an array of Point data.
//
function parseKml(text) {
  var output = Array();

  var jsonObj = parser.parse(text, {});
  console.log("ParseKml(): jsonObj: ", jsonObj);
  var placemarks = getPlacemarks(jsonObj);

  for(let placemark of placemarks) {

    let retval = tryParsePoint(placemark);
    if (retval !== null) {
      output.push(...retval);
      continue;
    }

    retval = tryParseLineString(placemark);
    if (retval !== null) {
      output.push(...retval);
      continue;
    }

    // TODO: support 'address' type
  }

  return output;
}

// An example of the JSON file is listed below. We only care about "placeVisit".
//
//   {
//     "timelineObjects" : [ {
//       "placeVisit" : {
//         "location" : {
//           "latitudeE7" : 374000000,
//           "longitudeE7" : -1220000000,
//           "placeId" : "ChIJKesZhf65j4ARxoBh866SiDM",
//           "address" : "N Shoreline Blvd\nMountain View, CA 94043\nUSA",
//           "name" : "US-MTV-9999",
//           "semanticType" : "TYPE_WORK",
//           "sourceInfo" : {
//             "deviceTag" : 999999999
//           },
//           "locationConfidence" : 98.11278
//         },
//         "duration" : {
//           "startTimestampMs" : "1577980781680",
//           "endTimestampMs" : "1577994830225"
//         },
//         "placeConfidence" : "HIGH_CONFIDENCE",
//         "centerLatE7" : 374000000,
//         "centerLngE7" : -1220000000,
//         "visitConfidence" : 87,
//         "otherCandidateLocations" : [ { ... } ],
//         "editConfirmationStatus" : "NOT_CONFIRMED"
//       }
//     }, {
//       "activitySegment" : {
//         ... don't care
//       }
//     },
//       ...
//   }
//
function parseJson(json_text) {
  var output = Array();

  var json = myJsonParse(json_text);
  var objs = json.timelineObjects;
  if (!objs) {
    alert("Unknown JSON file. Please download from Google Maps Timeline.", json_text);
    return;
  }

  for(var idx = 0; idx < objs.length; idx++) {
    var obj = objs[idx];
    var place_visit = obj.placeVisit;
    if (!place_visit) { continue; }

    output.push({
      'lat': place_visit.location.latitudeE7 / 10000000,
      'lng': place_visit.location.longitudeE7 / 10000000,
      'begin': Math.floor(place_visit.duration.startTimestampMs / 1000),
      'end': Math.floor(place_visit.duration.endTimestampMs / 1000),
      'name':place_visit.location.name,
    });
  }

  return output;
}


// Gien a text and returns Array of points.
//
// Args:
//   filename: undefined if it is unknown (e.g. from STDIN)
//   file_text: str, the file content.
//
// Returns:
//   Array of points.
//
function parseFile(filename, file_text) {
  if (filename && filename.endsWith(".kml")) {
    return parseKml(file_text);
  } else if (filename && filename.endsWith(".json")) {
    return parseJson(file_text);
  } else if (file_text.startsWith("<?xml ")) {
    return parseKml(file_text);
  } else if (file_text.startsWith("{")) {
    return parseJson(file_text);
  } else {
    alert("parseFile(): unsupported filename: " + filename);
  }
}
