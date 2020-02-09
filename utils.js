// String.trim(): remove whitespace in string
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
