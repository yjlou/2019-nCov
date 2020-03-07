// Convert Korean date to UTC timestamp (in msecs).
//
function KrDateToTimestampMs(year, month, day) {
  let ahead_9_hours = 9 * 60 * 60 * 1000;  // GMT+9
  return (new Date(year, month - 1, day)).getTime() - ahead_9_hours;
}

module.exports.KrDateToTimestampMs = KrDateToTimestampMs;
