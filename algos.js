// Start of distance helper (http://stackoverflow.com/questions/27928/calculate-distance-between-two-latitude-longitude-points-haversine-formula)
function getDistanceFromLatLonInMeters(lat1, lon1, lat2, lon2) {
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2-lat1);  // deg2rad below
  var dLon = deg2rad(lon2-lon1);
  var a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
    ;
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  var d = R * c; // Distance in km
  return d * 1000;  // Convert to meters
}

function deg2rad(deg) {
  return deg * (Math.PI/180)
}
// End of distance helper

// Given 2 sections of time duration, returns the overlapped duration.
function getOverlappedDuration(begin0, end0, begin1, end1) {
  EXPECT_LE(begin0, end0);
  EXPECT_LE(begin1, end1);

  return Math.max(0, Math.min(end0, end1) - Math.max(begin0, begin1));
}

// Given 2 points and returns the risk.
//
//  TODO: improve the calculation.
//
function getRisk(p0, p1) {
  var duration = getOverlappedDuration(p0.begin, p0.end, p1.begin, p1.end);
  if (duration > 0) {
    var meters = getDistanceFromLatLonInMeters(p0.lat, p0.lng, p1.lat, p1.lng);
    if (meters < 100) {
      return 1.0;
    }
  }
  return 0.0;
}

// Given the user's point data and known patient data, return the possible contact spots.
//
// Args:
//  user_points: Array of user's Point data.
//  patients: Array of {
//    'desc': patient info
//    'points': Array of Point data
//  }
//
// Returns:
//
//  Array of {
//    'desc': the description of possible contact.
//    'risk': float, score between 0 and 1. 1.0 means high risk.
//    'point': {
//      'user_desc': str, user's description.
//      'patient_desc': str, patient's description.
//      'lat': float
//      'lng': float
//      'begin':  float
//      'end': float
//    }
//  }
//
function checkContact(user_points, patients) {
  var ret = Array();

  for (var idxUserPoint = 0; idxUserPoint < user_points.length; idxUserPoint++) {
    for(var idxPatient = 0; idxPatient < patients.length; idxPatient++) {
      for(var idxPatientPoint = 0; idxPatientPoint < patients[idxPatient].points.length; idxPatientPoint++) {
        var patient_point = patients[idxPatient].points[idxPatientPoint];
        var risk = getRisk(user_points[idxUserPoint], patient_point);
        if (risk >= 0.8) {
          ret.push({
            'patient_desc': patients[idxPatient].desc + ":" + patient_point.name,
            'user_desc': user_points[idxUserPoint].name,
            'lat': user_points[idxUserPoint].lat,
            'lng': user_points[idxUserPoint].lng,
            'begin': user_points[idxUserPoint].begin,
            'end': user_points[idxUserPoint].end,
          });
        }
      }
    }
  }

  return ret;
}

function testGetDistanceFromLatLonInMeters() {
  var d = getDistanceFromLatLonInMeters(37.339084, -122.048175, 37.341971, -122.035795);
  // d = 1140.5617662522875
  EXPECT_LE(d, 1141);
  EXPECT_GE(d, 1140);
}

function testGetOverlappedDuration() {
  EXPECT_EQ(0, getOverlappedDuration(10, 15, 20, 30));
  EXPECT_EQ(0, getOverlappedDuration(10, 20, 20, 30));
  EXPECT_EQ(1, getOverlappedDuration(10, 21, 20, 30));
  EXPECT_EQ(5, getOverlappedDuration(10, 30, 20, 25));
  EXPECT_EQ(5, getOverlappedDuration(25, 30, 20, 35));
  EXPECT_EQ(10, getOverlappedDuration(25, 35, 20, 35));

  EXPECT_EQ(0, getOverlappedDuration(20, 30, 10, 15));
  EXPECT_EQ(0, getOverlappedDuration(20, 30, 10, 20));
  EXPECT_EQ(1, getOverlappedDuration(20, 30, 10, 21));
  EXPECT_EQ(5, getOverlappedDuration(20, 25, 10, 30));
  EXPECT_EQ(5, getOverlappedDuration(20, 35, 25, 30));
  EXPECT_EQ(10, getOverlappedDuration(20, 35, 25, 35));
}

function testGetRisk() {
  {  // same location, same time
    var p0 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 100,
      'end': 200,
    };
    var p1 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 100,
      'end': 200,
    };
    EXPECT_EQ(1.0, getRisk(p0, p1));
  }

  {  // same location, diff time
    var p0 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 100,
      'end': 200,
    };
    var p1 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 200,
      'end': 300,
    };
    EXPECT_EQ(0.0, getRisk(p0, p1));
  }

  {  // nearby location, overlapped time
    var p0 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 100,
      'end': 200,
    };
    var p1 = {
      'lat': 25.032503,
      'lng': 121.522376,
      'begin': 150,
      'end': 250,
    };
    EXPECT_EQ(1.0, getRisk(p0, p1));
  }

  {  // far-away location, same time
    var p0 = {
      'lat': 25.0,
      'lng': 121.0,
      'begin': 100,
      'end': 200,
    };
    var p1 = {
      'lat': 25.032444,
      'lng': 121.522806,
      'begin': 100,
      'end': 200,
    };
    EXPECT_EQ(0.0, getRisk(p0, p1));
  }
}

function testCheckContact() {
}
