TIME_OFFSET = 2 * 60 * 60 * 1000;  // GTM+2

// Convert Israel date to UTC timestamp (in msecs).
//
function IlDateToTimestampMs(year, month, day) {
  return (new Date(year, month - 1, day)).getTime() - TIME_OFFSET;
}

module.exports.IlDateToTimestampMs = IlDateToTimestampMs;
module.exports.TIME_OFFSET = TIME_OFFSET;
