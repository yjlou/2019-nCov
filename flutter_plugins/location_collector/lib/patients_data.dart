import 'dart:convert';
import 'dart:math';

import 'http_utils.dart';
import 'location_repository.dart';
import 'sync_service.dart';

class PatientsData {
  // The string shown to user
  final String desc;

  // The meta file path. It contains bounding box and last-updated info.
  final String meta;

  // The point data path.
  final String path;

  // URL string pointing to the data source.
  final String src;

  // This will be set after fetch() is called.
  List<PlaceVisit> points;
  BoundingBox boundingBox;
  int timestamp;
  bool fetched = false;

  PatientsData._(this.desc, this.meta, this.path, this.src);

  factory PatientsData.fromJson(Map<dynamic, dynamic> json) {
    return PatientsData._(
        json['desc'], json['meta'], json['path'], json['src']);
  }

  Future<bool> fetch() async {
    if (fetched) {
      return true;
    }

    try {
      String patientsStr =
          await fetchHttpFile('${SyncService.SERVER_URL}/${path}');
      var jsonObj = json.decode(patientsStr);
      var points = PlaceVisit.parseGoogleTakeoutFormat(jsonObj);
      PatientsMetadata metadata;

      try {
        if (meta != null) {
          String metaStr =
              await fetchHttpFile('${SyncService.SERVER_URL}/${meta}');
          jsonObj = json.decode(metaStr);
          metadata = PatientsMetadata.fromJson(jsonObj);
        }
      } catch (error) {
        print('Warning: ${error}');
      } finally {
        if (metadata == null) {
          metadata = PatientsMetadata.fromJson({
            'bounding_box': {
              'top': 90 * 1e7,
              'right': 180 * 1e7,
              'bottom': -90 * 1e7,
              'left': -180 * 1e7
            },
            'num_of_points': points.length,
          });
        }
      }

      this.points = points;
      boundingBox = metadata.boundingBox;
      timestamp = metadata.timestamp;

      fetched = true;
      return true;
    } catch (error) {
      print(error);
      return false;
    }
  }
}

class BoundingBox {
  // lat * 1e7, topE7 <= bottomE7
  final double topE7;

  // lat * 1e7
  final double bottomE7;

  // lng * 1e7, leftE7 <= rightE7
  final double leftE7;

  // lng * 1e7
  final double rightE7;

  BoundingBox._(this.topE7, this.leftE7, this.rightE7, this.bottomE7);

  factory BoundingBox.fromJson(Map<dynamic, dynamic> json) {
    return BoundingBox._(
        json['top'], json['left'], json['right'], json['bottom']);
  }

  bool isOverlapped(BoundingBox other) {
    return min(topE7, other.topE7) - max(bottomE7, other.bottomE7) > 0 &&
        min(rightE7, other.rightE7) - max(leftE7, other.leftE7) > 0;
  }

  factory BoundingBox.fromPlaceVisitList(List<PlaceVisit> placeVisitList) {
    double top;
    double left;
    double right;
    double bottom;

    placeVisitList.forEach((p) {
      var lat = p.lat * 1e7;
      var lng = p.lng * 1e7;
      if (top == null || top < lat) {
        top = lat;
      }
      if (bottom == null || lat < bottom) {
        bottom = lat;
      }
      if (left == null || left > lng) {
        left = lng;
      }
      if (right == null || lng > right) {
        right = lng;
      }
    });

    return BoundingBox._(top + 1E6, left - 1E6, right + 1E6, bottom - 1E6);
  }
}

class PatientsMetadata {
  final int numOfPoints;
  final int timestamp;
  final BoundingBox boundingBox;

  PatientsMetadata._(this.numOfPoints, this.timestamp, this.boundingBox);

  factory PatientsMetadata.fromJson(Map<dynamic, dynamic> json) {
    var boundingBox = BoundingBox.fromJson(json['bounding_box']);
    return PatientsMetadata._(
        json['num_of_points'], json['timestamp'], boundingBox);
  }
}

class PlaceVisit {
  final String name;

  // in degrees
  final double lat;

  // in degrees
  final double lng;

  // timestamp, in seconds
  final int begin;

  // timestamp, in seconds
  final int end;

  PlaceVisit._(this.name, this.lat, this.lng, this.begin, this.end);

  factory PlaceVisit.fromJson(json) {
    return PlaceVisit._(
        json['name'],
        json['lat'],
        json['lng'],
        json['begin'].toInt(),
        json['end'].toInt());
  }

  static List<PlaceVisit> parseGoogleTakeoutFormat(Map<dynamic, dynamic> json) {
    final timelineObjects = json['timelineObjects'];
    if (timelineObjects == null) {
      print('Cannot find timelineObjects...');
      return null;
    }

    List<PlaceVisit> output = [];
    for (var i = 0; i < timelineObjects.length; i++) {
      var obj = timelineObjects[i];
      final placeVisit = obj['placeVisit'];
      if (placeVisit == null) {
        continue;
      }

      output.add(PlaceVisit.fromJson({
        'name': placeVisit['location']['name'],
        'lat': placeVisit['location']['latitudeE7'] / 1e7,
        'lng': placeVisit['location']['longitudeE7'] / 1e7,
        'begin': (placeVisit['duration']['startTimestampMs'] / 1e3).floor(),
        'end': (placeVisit['duration']['endTimestampMs'] / 1e3).floor(),
      }));
    }
    return output;
  }

  bool isOverlapped(PlaceVisit o) {
    final duration = getOverlappedLength(begin, end, o.begin, o.end);
    if (duration > 0) {
      final distance = getDistanceFromLatLonInMeters(lat, lng, o.lat, o.lng);
      return distance < 100;
    }
    return false;
  }

  static int getOverlappedLength(int begin0, int end0, int begin1, int end1) {
    if (end0 < begin0) {
      print('Invalid interval [${begin0}, ${end0}]');
      return 0;
    }
    if (end1 < begin1) {
      print('Invalid interval [${begin1}, ${end1}]');
      return 0;
    }

    return max(0, min(end0, end1) - max(begin0, begin1));
  }

  static double getDistanceFromLatLonInMeters(
      double lat0, double lng0, double lat1, double lng1) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat1 - lat0); // deg2rad below
    var dLon = deg2rad(lng1 - lng0);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(deg2rad(lat0)) * cos(deg2rad(lat1)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // Distance in km
    return d * 1000; // Convert to meters
  }
}

class MatchedPoint {
  final String patientDesc;
  final String userDesc;
  final double userLat;
  final double userLng;
  final int userBegin;
  final int userEnd;

  // Link back to PatientsData?
  // final PatientsData patientsData;

  MatchedPoint._(this.patientDesc, this.userDesc, this.userLat, this.userLng,
      this.userBegin, this.userEnd);

  factory MatchedPoint.make(PlaceVisit user, PlaceVisit patient) {
    return MatchedPoint._(
        patient.name, user.name, user.lat, user.lng, user.begin, user.end);
  }
}

double deg2rad(double deg) {
  // 180 deg = pi rad
  return deg * pi / 180.0;
}
