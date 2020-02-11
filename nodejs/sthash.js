"use strict";

const fs = require("fs");
const yargs = require("yargs");

const sthash = require("../lib_sthash.js");
const parsers = require("../parsers.js");

const argv = yargs
    .option('desc', {
        alias: 'd',
        description: 'Description for hash value',
        type: 'string',
    })
    .option('key', {
        alias: 'k',
        description: 'Hash key',
        type: 'string',
    })
    .help()
    .alias('help', 'h')
    .argv;

let desc = argv.desc;
if (desc == undefined) {
  desc = "";
}

let hash_key;
if (argv.key != undefined) {
  hash_key = argv.key;
} else {
  hash_key = sthash.DEFAULT_HASH_KEY;
}

let json_text = fs.readFileSync("/dev/stdin", 'utf-8');
let points = parsers.parseJson(json_text);

let all_hashes = {};
for (let point of points) {
  var hashes = sthash.hashSpacetime(hash_key, point.begin, point.end, point.lat, point.lng);
  for (let hash of hashes) {
    all_hashes[hash] = desc;
  }
}
process.stdout.write(JSON.stringify(all_hashes, null, 2));
