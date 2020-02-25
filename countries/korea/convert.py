import argparse
import datetime
import json
import time

class KoreanTimeZone(datetime.tzinfo):
  def utcoffset(self, dt):
    return datetime.timedelta(hours=9)

  def dst(self, dt):
    return datetime.timedelta(0)

  def tzname(self, dt):
    return '+0900'


def Main(input_file, output_file):
  with open(input_file) as f:
    cases = json.load(f)

  # a timeline object should be like:
  # {
  #   "placeVisit" : {
  #     "location" : {
  #       "latitudeE7" : 374000000,                    # *
  #       "longitudeE7" : -1220000000,                 # *
  #       "placeId" : "ChIJKesZhf65j4ARxoBh866SiDM",
  #       "address" : "N Shoreline Blvd\nMountain View, CA 94043\nUSA",
  #       "name" : "US-MTV-9999",                      # *
  #       "semanticType" : "TYPE_WORK",
  #       "sourceInfo" : {
  #         "deviceTag" : 999999999
  #       },
  #       "locationConfidence" : 98.11278
  #     },
  #     "duration" : {                                 # *
  #       "startTimestampMs" : "1577980781680",
  #       "endTimestampMs" : "1577994830225"
  #     },
  #     "placeConfidence" : "HIGH_CONFIDENCE",
  #     "centerLatE7" : 374000000,
  #     "centerLngE7" : -1220000000,
  #     "visitConfidence" : 87,
  #     "otherCandidateLocations" : [ { ... } ],
  #     "editConfirmationStatus" : "NOT_CONFIRMED"
  #   }
  # }
  # What we care:
  #   'lat': place_visit.location.latitudeE7 / 10000000,
  #   'lng': place_visit.location.longitudeE7 / 10000000,
  #   'begin': Math.floor(place_visit.duration.startTimestampMs / 1000),
  #   'end': Math.floor(place_visit.duration.endTimestampMs / 1000),
  #   'name':place_visit.location.name,
  results = []
  tz = KoreanTimeZone()
  for k, e in cases.items():
    places = e['data']['data']

    for idx, place in enumerate(places):
      # place = {
      #   "address": {...},
      #   "date": "2020-02-13T00:00:00.000Z",
      #   "latlng": {
      #     "x": 127.102292,
      #     "y": 35.817177,
      #     "_lng": 127.102292,
      #     "_lat": 35.817177,
      #   }
      # }
      x = place['latlng']['x']
      y = place['latlng']['y']
      d = place['date']
      name = str(e['data']['name'])
      if not d:
        print('!!! Unknown date !!!')
        print(name)
        print(place)
        print('!!!!!!!!!!!!!!!!!!!!')
        continue

      # The time is basically meaningless, just discard it.
      d = d.split('T')[0]
      d = datetime.datetime.strptime(d, "%Y-%m-%d")
      d = d.replace(tzinfo=tz)
      t = int(time.mktime(d.timetuple())) * 1000

      results.append(
          {
            "placeVisit" : {
              "location" : {
                "latitudeE7" : int(y * (10 ** 7)),
                "longitudeE7" : int(x * (10 ** 7)),
                "name" : name,
              },
              "duration" : {
                "startTimestampMs" : str(t),
                "endTimestampMs" : str(t + 86400 * 1000),
              },
            }
          }
      )

  with open(output_file, 'w') as f:
    json.dump({
      'timelineObjects': results
    }, f, sort_keys=True)


if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('--input', '-i', default='input.json')
  parser.add_argument('--output', '-o', default='output.json')

  args = parser.parse_args()

  Main(args.input, args.output)
