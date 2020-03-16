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

  // Build a bounding box from user's points. Note that in the meta file, the bounding box
  // is in 1e7 format.
  //
  function buildBoundingBox(user_points) {
    let bounding_box = BoundingBox();
    user_points.forEach(user_point => bounding_box.insert(user_point.lat * 1e7,
                                                          user_point.lng * 1e7));
    return bounding_box;
  }

  // Returns true if 2 given bounding boxes are overlapped.
  //
  function isOverlapped(bb0, bb1) {
    // Handle the corner case that the bounding box (assuming user's) is just a point.
    if (bb0.top == bb0.bottom) { bb0.top += 1; }
    if (bb0.left == bb0.right) { bb0.right += 1; }

    return Math.max(0, Math.min(bb0.top, bb1.top) - Math.max(bb0.bottom, bb1.bottom)) &&
           Math.max(0, Math.min(bb0.right, bb1.right) - Math.max(bb0.left, bb1.left));
  }

  let ret = Array();

  let bounding_box = buildBoundingBox(user_points);

  for (let user_point of user_points) {
    for(let patient of patients) {
      if (!isOverlapped(bounding_box.get(), patient.bounding_box)) {
        console.log(`Out of bounding box of ${patient.desc}. Skipped.`);
        continue;
      }

      for(let patient_point of patient.points) {
        var risk = getRisk(user_point, patient_point);
        if (risk >= 0.8) {
          ret.push({
            'patient_desc': patient_point.name,
            'user_desc': user_point.name,
            'lat': user_point.lat,
            'lng': user_point.lng,
            'begin': user_point.begin,
            'end': user_point.end,
            'meta_info': patient_point.meta_info,
          });
        }
      }
    }
  }

  return ret;
}

function checkHashes(user_points, knwon_hashes) {
  let ret = Array();
  if (Object.keys(knwon_hashes).length == 0) { return ret; }

  var dedup = {};
  for(let user_point of user_points) {
    hashes = hashSpacetime(DEFAULT_HASH_KEY, user_point.begin, user_point.end, user_point.lat, user_point.lng, 10, -4, 5);
    for(let hash of hashes) {
      let found = knwon_hashes[hash];
      if (found) {
        ret.push({
          patient_desc: found.desc,
          user_desc: user_point.name,
          begin: user_point.begin,
          end: user_point.end,
          lat: user_point.lat,
          lng: user_point.lng,
        });
        break;  // For each user point, we only need to return a found point.
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
