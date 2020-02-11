"use strict";

var sthash = require("../lib_sthash.js");
var parsers = require("../parsers.js");
var fs = require("fs");

var json_text = fs.readFileSync("/dev/stdin", 'utf-8');
var points = parsers.parseJson(json_text);
console.log(points);
