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

    // TODO: support 'address' type
    // TODO: support 'linestring' type
    let retval = tryParsePoint(placemark);
    if (retval !== null) {
      console.info(retval);
      output.concat(retval);
      continue;
    }

  }

  return output;
}
