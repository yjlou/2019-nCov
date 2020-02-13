// String.trim(): remove whitespace in string
//
if(typeof(String.prototype.trim) === "undefined")
{
    String.prototype.trim = function() 
    {
        return String(this).replace(/^\s+|\s+$/g, '');
    };
}

// Returns the timestamp (#seconds since 1970/01/01)
//
// kml_date format: 2020-01-30T22:00:00.000Z
//   https://developers.google.com/kml/documentation/kmlreference#timespan
//
function convKmlDateToTimestamp(kml_date) {
  var [date, time] = kml_date.split("T");
  var [year, month, day] = date.split("-");
  var [hour, minute, second] = time.split("Z")[0].split(":");
  var datum = new Date(Date.UTC(parseInt(year), parseInt(month) - 1, parseInt(day),
                                parseInt(hour), parseInt(minute), parseFloat(second)));
  return datum.getTime() / 1000.0;
}

function testConvKmlDateToTimestamp() {
  EXPECT_EQ(0, convKmlDateToTimestamp("1970-01-01T00:00:00.000Z"));
  EXPECT_EQ(1581226749, convKmlDateToTimestamp("2020-02-09T05:39:09.123Z"));
}

// Shuffle some digits of a float number
//
// Args:
//   num: the float number to shuffle
//   start: location to start shuffle. 0 means the first digit above point.
//                                     negative means the digit below point.
//   stop: ending location of the shuffle (inclusive).
//   stuffing: optional. a char used for testing to mark the shuffle part.
//
// For example, for a number, 123.456789:
//
//   start  stop          new value
//  --------------      -------------
//     3      2    ==>  xx
//     2      0    ==>   xxx
//     0     -2    ==>   12x.xx
//    -1     -3    ==>   123.xxx
//    -4     -6    ==>   123.456xxx
//    -3     -8    ==>   123.45xxxxxx
//
// Returns:
//   string
//
function shuffleFloat(num, start, stop, stuffing) {
  let str = num.toString();
  let pt_pos = str.indexOf(".");
  if (pt_pos == -1) {
    pt_pos = str.length;
    str += ".";
  }

  // start must be smaller than 'end'.
  if (start < stop) {
    [start, stop] = [stop, start];
  }

  // insert zero-es if digits before point is not long enough.
  let to_insert = (start + 1) - pt_pos;
  if (start >= 0 && to_insert > 0) {
    str = "0".repeat(to_insert) + str;
    pt_pos += to_insert;
    start = 0;
  } else {
    if (start < 0) {
      start = pt_pos - start;
    } else {
      start = pt_pos - start - 1;
    }
  }
  // 'start' value now is formalized as string offset.

  // append zero-es if digits after point is not long enough.
  let to_append = (-stop) - (str.length - pt_pos - 1)
  if (stop < 0 && to_append > 0) {
    str += "0".repeat(to_append);
  }
  // formalize the 'stop' value to string offset.
  if (stop >= 0) {
    stop = pt_pos - stop - 1;
  } else {
    stop = pt_pos - stop;
  }

  for(let i = start; i <= stop; i++) {
    if (i == pt_pos) { continue; }
    str = str.substr(0, i) +
          (stuffing != undefined ? stuffing : Math.floor(Math.random() * 10).toString()) +
          str.substr(i + 1);
  }

  return str.substr(0, stop + 1);
}

function testShuffleFloat() {
  EXPECT_EQ("xx", shuffleFloat(123.456789, 3, 2, 'x'));
  EXPECT_EQ("xxx", shuffleFloat(123.456789, 2, 0, 'x'));
  EXPECT_EQ("12x.xx", shuffleFloat(123.456789, 0, -2, 'x'));
  EXPECT_EQ("123.xxx", shuffleFloat(123.456789, -1, -3, 'x'));
  EXPECT_EQ("123.456xxx", shuffleFloat(123.456789, -4, -6, 'x'));
  EXPECT_EQ("123.45xxxxxx", shuffleFloat(123.456789, -3, -8, 'x'));
}
