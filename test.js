var FAILED = 0;

function EXPECT_GE(a, b, msg) {
  if (msg === undefined) { msg = "";}
  if (a < b) {
    console.error("EXPECT_GE: Expected: (" + a + ") >= (" + b + "), but not. " + msg);
    console.error(new Error().stack);
    FAILED++;
  }
}

function EXPECT_LE(a, b, msg) {
  if (msg === undefined) { msg = "";}
  if (a > b) {
    console.error("EXPECT_LE: Expected: (" + a + ") <= (" + actual + "), but not. " + msg);
    console.error(new Error().stack);
    FAILED++;
  }
}

function EXPECT_EQ(expected, actual, msg) {
  if (msg === undefined) { msg = "";}
  if (JSON.stringify(expected) != JSON.stringify(actual)) {
    console.error("EXPECT_EQ: Expected: " + JSON.stringify(expected, null, 2) +
                  ", but actual: " + JSON.stringify(actual, null, 2) + ". " + msg);
    console.error(new Error().stack);
    FAILED++;
  }
}

function test() {
  FAILED = 0;

  // alogos.js
  testGetOverlappedDuration();
  testGetDistanceFromLatLonInMeters();
  testGetRisk();
  testCheckContact();

  // utils.js
  testConvKmlDateToTimestamp();

  // lib_sthash.js
  testQuantifyDuration();
  testQuantifyLatLng();
  testHmac();
  testHashSpacetime();

  // parsers.js
  testIntrapolateCoords();

  if (FAILED) {
    console.error("[FAIL]");
  } else {
    console.log("[PASS]");
  }
}
