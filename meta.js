// Used to generate meta file (for nodejs) and load meta files (for web).
//
"use strict";

// JS code used in both broswer and nodejs
(function(exports){
  exports.boundingBox = boundingBox;
}(typeof exports === 'undefined' ? this.meta = {} : exports));

// Global variable
//

// The list of default patients data. Each entry is a dict:
//
//   desc: The string shown to user
//   meta: The meta file path. It contains bounding box and last-updated info.
//   path: The point data path.
//   src: URL string pointing to the data source.
//
// This structure is used to indicate where data are located. They will be loaded to PATIENT somehow.
//
var DEFAULT_PATIENTS_DATA = [
  // Taiwan case 32
  {
    desc: 'Taiwan 台灣 [案32]',
    meta: "countries/taiwan/case-32.meta.json",
    path: "countries/taiwan/case-32.output.json",
    src: 'https://drive.google.com/open?id=1QYAkgHR5yykzsVZnTitfEFkNpNd6Ragn&usp=sharing',
  },

  // coronamap.site
  {
    desc: 'Korea data [https://coronamap.site]',
    meta: "countries/korea/coronamap.site-meta.json",
    path: "countries/korea/coronamap.site-output.json",
    src: 'https://coronamap.site',
  },

  // corona
  {
    desc: 'Korea data [Coronavirus Dataset]',
    meta: 'countries/korea/coronavirus-dataset-meta.json',
    path: 'countries/korea/coronavirus-dataset-output.json',
    src: 'https://github.com/jihoo-kim/Coronavirus-Dataset/',
  },

  // Israel government GIS
  {
    desc: 'Israel cases',
    meta: "countries/israel/meta.json",
    path: "countries/israel/output.json",
    src: 'https://imoh.maps.arcgis.com/apps/webappviewer/index.html?id=20ded58639ff4d47a2e2e36af464c36e&locale=he&/',
  },
];

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
