// Spacetime hash functions
//
// This library is used to hash a location and a time into a hash value.
// The main purpose is to determine whether 2 spacetime records are approximate
// while privacy is a concern.
//
// A spacetime record contains a time duration and a lat/lng.
//
//   begin: timestamp
//   end: timestamp
//   lat: float
//   lng: float
//
// Those values will be first quantified so that they can be mapped to
// discrete points. Then they will be populated to multiple points
// for approximation check.
//
// For time duration, more points can be added between 'begin' and 'end'
// depending on the quantification scale. Example below is 5-min.
//
//        begin                               end
//     1581378989                         1581379321
//          | Math.floor()                     | Math.ceil()
//          v                                  v
//     1581378900        1581379200       1581379500
//                            ^
//                            | newly added point
//
// For lat/lng, they will be quantified first, then populated with nearby
// points:
//
//          *--------*--------*
//          |        |        |
//          *---- lat/lng ----*
//          |        |        |
//          *--------*--------*
//
// The 8 asterisks are nearby points.
//
// Then, all combination of above timestamps and lat/lng will be hashed
// to its value for future comparison.
//
// TODO: sthash.js generates 0-level spread-out; web matching uses N-level spread-out.
//
"use strict";

var DEFAULT_HASH_KEY = "JuliaWu";
var HASH_VALUE_LEN = 16;  // 16 * 4 = 64 bits should be long enough.

if (this.sha256 == undefined) {
  var sha256 = require("js-sha256");
  var utils = require("./utils.js");
}

// JS code used in both broswer and nodejs
(function(exports){
  exports.DEFAULT_HASH_KEY = DEFAULT_HASH_KEY;
  exports.hashSpacetime = hashSpacetime;
}(typeof exports === 'undefined' ? this.sthash = {} : exports));

//
function quantifyDuration(begin_, end_, time_step_in_mins) {
  let step = time_step_in_mins * 60;
  let begin = Math.floor(begin_ / step) * step;
  let end = Math.ceil(end_ / step) * step;

  let ret = [];
  for(let t = begin; t <= end; t += step) {
    ret.push(t);
  }

  return ret;
}

function testQuantifyDuration() {
  EXPECT_EQ([0, 600, 1200], quantifyDuration(123, 601, 10));
}

// Quantify a lat/lng to ~100 meters scale
//
// For example, 25.123456, 122.123456 ==> 25.123000, 122.123000
//
// Returns:
//   [lat, lng, lat_step, lng_step]
//
function quantifyLatLng(lat, lng, latlng_precision) {
  // TODO: more precise steps by considering the lat.
  var lat_step = 10 ** latlng_precision;
  var lng_step = 10 ** latlng_precision;

  return [parseFloat(utils.shuffleFloat(lat, latlng_precision - 1, latlng_precision - 1, '0')),
          parseFloat(utils.shuffleFloat(lng, latlng_precision - 1, latlng_precision - 1, '0')),
          lat_step,
          lng_step];
}

function testQuantifyLatLng() {
  EXPECT_EQ([25.123000, 122.123000, 0.001, 0.001], quantifyLatLng(25.123456, 122.123456, -3));
}

function HMAC(key) {
  return function(timestamp, lat, lng) {
    var msg = timestamp.toString() + lat.toString() + lng.toString();
    return sha256.hmac(key, msg).substr(0, HASH_VALUE_LEN);
  };
}

function testHmac() {
  var hmac = HMAC("abc");
  EXPECT_EQ("bfa8c5bc764321ac", hmac(123, 25.123, 122.123));
}

// Hash a spacetime point
//
// Args:
//   key: str. hash key
//   begin: timestamp
//   end: timestamp
//   lat: float
//   lng: float
//   time_step_in_mins: number. in minutes.
//   latlng_precision: int. truncate to the least-significant digit. negative means digits after point.
//   spread_out: int. the level number to populate nearby points.
//
// Returns:
//   Array of hash
//
function hashSpacetime(key, begin, end, lat, lng, time_step_in_mins, latlng_precision, spread_out){
  var hmac = HMAC(key);
  var q = quantifyLatLng(lat, lng, latlng_precision);
  var lat = q[0];
  var lng = q[1];
  var lat_step = q[2];
  var lng_step = q[3];

  var ret = Array();
  for(let t of quantifyDuration(begin, end, time_step_in_mins)) {
    for(let lat_i = spread_out; lat_i >= -spread_out; lat_i--) {
      for(let lng_i = -spread_out; lng_i <= spread_out; lng_i++) {
        ret.push(hmac(t, lat + lat_i * lat_step, lng + lng_i * lng_step));
      }
    }
  }

  return ret;
}

function testHashSpacetime() {
  EXPECT_EQ([
    // timestamp 0
    "c382a0e3cb70d994", "c70af5fb7b8fde48", "9eb8bf971bd6a5c4",
    "3edfc9c2b1918d94", "6d01141a9aa0ccfa", "b677765bc46e842c",
    "4bc38a6e7d6ff3b1", "bb10b2665ae6ddfb", "3221754cc20782e2",
    // timestamp 600
    "514f818e18001c56", "6d196070385fb881", "3354367bcca7a39a",
    "38df5a16e00b8fdd", "2d2423974df2968c", "dc37d585fefe04e2",
    "1d4093fde8022368", "e3c6e6e96e94d4be", "0cefa29f531ab9a5",
    // timestamp 1200
    "85ec3daafd12a580", "546835556647f287", "46b4b9f876166efe",
    "8f72ee403295fa96", "29dd5053e89e18e7", "e086767349312bc8",
    "f003d1589b89a76c", "435ce8b5b333c9b0", "0a79fc6b39705be6",
  ], hashSpacetime("abc", 100, 700, 25.123456, 122.123000, 10, -3, 1));
}
