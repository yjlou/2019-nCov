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
    var latlng = "";
    var time_begin = "";
    var time_end = "";
    var name = "";

    // TODO: support 'address' type
    // TODO: support 'linestring' type
    var point = placemark.getElementsByTagName("Point");
    if (point.length == 0) {
      // Not point data. Maybe LineString data. Discard.
      continue;
    } else if (point.length == 1) {
      latlng = point[0].children[0].innerHTML;
    } else {
      console.error("Invalid point data: ", placemark);
      continue;
    }

    var name_elem = placemark.getElementsByTagName("name");
    if (name_elem.length == 1) {
      name = name_elem[0].innerHTML;
    } else {
      console.error("Too many names: ", name_elem);
    }

    var timespan = placemark.getElementsByTagName("TimeSpan");
    if (timespan.length == 1) {
      time_begin = timespan[0].children[0].innerHTML;
      time_end = timespan[0].children[1].innerHTML;
    } else {
      console.error("Invalid timespan data: ", placemark);
      continue;
    }

    // Point data: (-122.02223289999999,37.338164,0) 2020-02-07T16:14:56.673Z~2020-02-07T16:20:34.000Z
    output.push({
      'lat': parseFloat(latlng.split(",")[1].trim()),
      'lng': parseFloat(latlng.split(",")[0].trim()),
      'begin': parseFloat(convKmlDateToTimestamp(time_begin.trim())),
      'end': parseFloat(convKmlDateToTimestamp(time_end.trim())),
      'name': name.trim(),
    });
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
