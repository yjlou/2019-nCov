// Used to generate meta file (for nodejs) and load meta files (for web).
//
"use strict";

// JS code used in both broswer and nodejs
(function(exports){
  exports.boundingBox = boundingBox;
}(typeof exports === 'undefined' ? this.meta = {} : exports));

// Class BoundingBox
//
//  Given lat/lng pairs, this class populates a bounding box that contains all points.
var boundingBox = function() {
  let top = undefined;     // lat
  let left = undefined;    // lng
  let right = undefined;   // lng
  let bottom = undefined;  // lat

  return {
    insert: function(lat, lng) {
      if (top === undefined || lat > top) { top = lat; }
      if (bottom === undefined || lat < bottom) { bottom = lat; }
      if (right === undefined || lng > right) { right = lng; }
      if (left === undefined || lng < left) { left = lng; }
    },

    get: function() {
      return {
        top: top,
        left: left,
        right: right,
        bottom: bottom,
      };
    },
  };
};

function testBoundingBox() {
  let bb = boundingBox();
  bb.insert(1, 2);
  bb.insert(-3, -4);
  EXPECT_EQ({
    top: 1,
    left: -4,
    right: 2,
    bottom: -3,
  }, bb.get());
}
