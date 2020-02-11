"use strict";

// JS code used in both broswer and nodejs
(function(exports){
  exports.parseKml = parseKml;
  exports.parseJson = parseJson;
}(typeof exports === 'undefined' ? this.parsers = {} : exports));

function tryParseName(placemark) {
  const name_elem = placemark.getElementsByTagName("name");
  if (name_elem.length == 1) {
    return name_elem[0].innerHTML.trim();
  }

  console.error("Too many names: ", name_elem);
  return "";
}

function tryParseTimeSpan(placemark) {
  const timespan = placemark.getElementsByTagName("TimeSpan");
  if (timespan.length == 1) {
    const time_begin = timespan[0].children[0].innerHTML;
    const time_end = timespan[0].children[1].innerHTML;
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

  const point = placemark.getElementsByTagName("Point");

  if (point.length == 0) {
    // Not point data. Maybe LineString data. Discard.
    return null;
  }
  if (point.length != 1) {
    console.error("Invalid point data: ", placemark);
    return null;
  }

  latlng = point[0].children[0].innerHTML;

  const name = tryParseName(placemark);
  const timespan = tryParseTimeSpan(placemark);
  if (timespan === null) {
    return null;
  }

  // Point data: (-122.02223289999999,37.338164,0) 2020-02-07T16:14:56.673Z~2020-02-07T16:20:34.000Z
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
  const line_string = placemark.getElementsByTagName("LineString");

  if (line_string.length == 0) {
    // Not a LineString, does nothing.
    return null;
  }
  if (line_string.length != 1) {
    console.error("Invalid LineString data: ", placemark);
    return null;
  }

  // TODO: check altitudeMode?
  let coords_elements = line_string[0].getElementsByTagName("coordinates");
  if (coords_elements.length != 1) {
    console.error("Invalid LineString data: ", placemark);
    return null;
  }

  const coords = [];
  for (let coord_string of coords_elements[0].innerHTML.trim().split(" ")) {
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

// Given a KML text, returns an array of Point data.
//
function parseKml(text) {
  var parser = new DOMParser();
  var kml = parser.parseFromString(text,"text/xml");
  var output = Array();

  console.log(kml);
  var placemarks = kml.getElementsByTagName("Placemark");
  console.log(placemarks);
  for(var i = 0; i < placemarks.length; i++) {
    var placemark = placemarks[i];

    let retval = tryParsePoint(placemark);
    if (retval !== null) {
      console.info(retval);
      output.push(...retval);
      continue;
    }

    retval = tryParseLineString(placemark);
    if (retval !== null) {
      console.info(retval);
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

  var json = JSON.parse(json_text);
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
