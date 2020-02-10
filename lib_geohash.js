// JS code used in both broswer and nodejs
var sha256 = require("js-sha256");

(function(exports){
  exports.convLatLng = convLatLng;
}(typeof exports === 'undefined' ? this.geohash = {} : exports));

// Quantify a lat/lng to ~100 meters scale
//
// For example, 25.123456, 122.123456 ==> 25.123000, 122.123000
//
// Returns:
//   [lat, lng, lat_step, lng_step]
//
function quantify(lat, lng) {
  // TODO: more precise steps by considering the lat.
  var lat_step = 0.001;
  var lng_step = 0.001;

  return [Math.round(lat / lat_step) * lat_step,
          Math.round(lng / lng_step) * lng_step,
          lat_step,
          lng_step];
}

function testQuantify() {
  EXPECT_EQ([25.123000, 122.123000, 0.001, 0.001], quantify(25.123456, 122.123456));
}

function HMAC(key) {
  return function(lat, lng) {
    var msg = JSON.stringify([lat, lng]);
    return sha256.hmac(key, msg).substr(0, 32);
  };
}

function testHmac() {
  var hmac = HMAC("abc");
  EXPECT_EQ("06bb196908455de16fa0509cd86eb6e3", hmac(25.123, 122.123));
}

function convLatLng(key, lat, lng){
  var hmac = HMAC(key);
  var q = quantify(lat, lng);
  var lat = q[0];
  var lng = q[1];
  var lat_step = q[2];
  var lng_step = q[3];

  return [
    hmac(lat + lat_step, lng - lng_step), hmac(lat + lat_step, lng), hmac(lat + lat_step, lng + lng_step),
    hmac(lat           , lng - lng_step), hmac(lat           , lng), hmac(lat           , lng + lng_step),
    hmac(lat - lat_step, lng - lng_step), hmac(lat - lat_step, lng), hmac(lat - lat_step, lng + lng_step),
  ];
}

function testConvLatLng() {
  EXPECT_EQ([
    "9478dcedae8daf06ad58016c2f81d72a", "4a133c999b7d4ecac3f51364d508133d", "a81f83c8f38b9676b367c02dfe55f616",
    "25eb9bb235803d3856ae796e760f0031", "06bb196908455de16fa0509cd86eb6e3", "328a7bda19524a10422ce3d6dc0c013f",
    "d2b1d2a9623a277d8b63182a376b1eff", "42a1519deac76761a3bc77c641615a5e", "f3496b5b458b47e642bf24dfaa87adfd",
  ], convLatLng("abc", 25.123456, 122.123000));
}
