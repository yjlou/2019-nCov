#!/bin/bash
#
# Download data from coronamap.site and convert it to Takeout JSON format.
#
# Due to the nodejs require path restriction, this script must be run under
# countries/korea.
#

INPUT="coronamap.site-input.js"
META="coronamap.site-meta.json"
OUTPUT="coronamap.site-output.json"

# Download the data file and manipulate a little bit.
wget https://coronamap.site/javascripts/ndata.js -O "${INPUT}"
echo "module.exports.position = position;" >> "${INPUT}"

nodejs coronamap.site-converter.js \
    -i "${INPUT}" \
    -m "${META}" \
    -o "${OUTPUT}"
