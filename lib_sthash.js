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
"use strict";

var DEFAULT_HASH_KEY = "JuliaWu";
var HASH_VALUE_LEN = 16;  // 16 * 4 = 64 bits should be long enough.

var sha256 = require("js-sha256");  // This line fails at browser. So leave this at end of global variables.

// JS code used in both broswer and nodejs
(function(exports){
  exports.DEFAULT_HASH_KEY = DEFAULT_HASH_KEY;
  exports.hashSpacetime = hashSpacetime;
}(typeof exports === 'undefined' ? this.sthash = {} : exports));

//
function quantifyDuration(begin_, end_) {
  let step = 10 * 60;  // 10-mins
  let begin = Math.floor(begin_ / step) * step;
  let end = Math.ceil(end_ / step) * step;

  let ret = [];
  for(let t = begin; t <= end; t += step) {
    ret.push(t);
  }

  return ret;
}

function testQuantifyDuration() {
  EXPECT_EQ([0, 600, 1200], quantifyDuration(123, 601));
}

// Quantify a lat/lng to ~100 meters scale
//
// For example, 25.123456, 122.123456 ==> 25.123000, 122.123000
//
// Returns:
//   [lat, lng, lat_step, lng_step]
//
function quantifyLatLng(lat, lng) {
  // TODO: more precise steps by considering the lat.
  var lat_step = 0.001;
  var lng_step = 0.001;

  return [Math.round(lat / lat_step) * lat_step,
          Math.round(lng / lng_step) * lng_step,
          lat_step,
          lng_step];
}

function testQuantifyLatLng() {
  EXPECT_EQ([25.123000, 122.123000, 0.001, 0.001], quantifyLatLng(25.123456, 122.123456));
}

function HMAC(key) {
  return function(timestamp, lat, lng) {
    var msg = timestamp.toString() + lat.toString() + lng.toString();
    return sha256.hmac(key, msg).substr(0, HASH_VALUE_LEN);
  };
}

function testHmac() {
  var hmac = HMAC("abc");
  EXPECT_EQ("bfa8c5bc764321ac99301c8a616e9d96", hmac(123, 25.123, 122.123));
}

function hashSpacetime(key, begin, end, lat, lng){
  var hmac = HMAC(key);
  var q = quantifyLatLng(lat, lng);
  var lat = q[0];
  var lng = q[1];
  var lat_step = q[2];
  var lng_step = q[3];

  var ret = Array();
  for(let t of quantifyDuration(begin, end)) {
    var latlngs = [
      hmac(t, lat + lat_step, lng - lng_step), hmac(t, lat + lat_step, lng), hmac(t, lat + lat_step, lng + lng_step),
      hmac(t, lat           , lng - lng_step), hmac(t, lat           , lng), hmac(t, lat           , lng + lng_step),
      hmac(t, lat - lat_step, lng - lng_step), hmac(t, lat - lat_step, lng), hmac(t, lat - lat_step, lng + lng_step),
    ];
    ret = ret.concat(latlngs);
  }

  return ret;
}

function testHashSpacetime() {
  EXPECT_EQ([
    // timestamp 0
    "c382a0e3cb70d9944d0d8ce0b75207fd", "c70af5fb7b8fde48e4a6c663c0ac65f7", "9eb8bf971bd6a5c43ef9d72521941b23",
    "3edfc9c2b1918d943a4c66f5ec14801c", "6d01141a9aa0ccfa86a9c76a689c750a", "b677765bc46e842cc5c56c0b3738bc0d",
    "4bc38a6e7d6ff3b17c2efd9e060c108a", "bb10b2665ae6ddfb4f7ce92439ba4d26", "3221754cc20782e28bc669f87639ef53",
    // timestamp 600
    "514f818e18001c5665b0cdf52d4387d0", "6d196070385fb8812ef472263aad9bbb", "3354367bcca7a39af17b8395c14b5312",
    "38df5a16e00b8fdd22aacfbc22ba31d4", "2d2423974df2968c684d63475d8acf06", "dc37d585fefe04e2babc46eb8fdf2e2a",
    "1d4093fde802236863f7aae6a7607e4f", "e3c6e6e96e94d4be58cbfbc99fb5ac19", "0cefa29f531ab9a5bff2d2bc663e2efa",
    // timestamp 1200
    "85ec3daafd12a58088ead221ab96a1f5", "546835556647f2876724b1cad4bdc4af", "46b4b9f876166efea00c4ad837195188",
    "8f72ee403295fa96d1ecb641cbcfb6a3", "29dd5053e89e18e7bff63757c5d509ac", "e086767349312bc838a813f9fa4a98ce",
    "f003d1589b89a76c0f9766d91a265580", "435ce8b5b333c9b09d65b8aef8eb73de", "0a79fc6b39705be6817cce71182cccca",
  ], hashSpacetime("abc", 100, 700, 25.123456, 122.123000));
}
