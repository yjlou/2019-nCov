#!/bin/bash
#
# Download data from coronamap.site and convert it to Takeout JSON format.
#
# Due to the nodejs require path restriction, this script must be run under
# countries/korea.
#

PREFIX="coronavirus-dataset"
INPUT="${PREFIX}-input.csv"
OUTPUT="${PREFIX}-output.json"
URL="https://raw.githubusercontent.com/jihoo-kim/Coronavirus-Dataset/master/route.csv"

# Download the data file and manipulate a little bit.
wget "${URL}" -O "${INPUT}"

nodejs "${PREFIX}"-converter.js \
    -i "${INPUT}" \
    -o "${OUTPUT}"
