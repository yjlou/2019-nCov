import 'dart:convert';

import 'http_utils.dart';
import 'sync_service.dart';

class PatientsData {
  // The string shown to user
  String desc;
  // The meta file path. It contains bounding box and last-updated info.
  String meta;
  // The point data path.
  String path;
  // URL string pointing to the data source.
  String src;

  // This will be set after fetch() is called.
  List<PlaceVisit> points;
  BoundingBox boundingBox;
  int timestamp;
  bool fetched;

  PatientsData._(this.desc, this.meta, this.path, this.src);

  factory PatientsData.fromJson(Map<dynamic, dynamic> json) {
    return PatientsData._(json['desc'], json['meta'], json['path'], json['src']);
  }

  Future<bool> fetch() async {
    if (fetched) {
      return true;
    }

    try {
      String patientsStr = await fetchHttpFile(
          '${SyncService.SERVER_URL}/${path}');
      var jsonObj = json.decode(patientsStr);
      var points = PlaceVisit.parseGoogleTakeoutFormat(jsonObj);
      PatientsMetadata metadata;

      try {
        if (meta != null) {
          String metaStr = await fetchHttpFile(
              '${SyncService.SERVER_URL}/${meta}');
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
      this.boundingBox = metadata.boundingBox;
      this.timestamp = metadata.timestamp;

      return true;
    } catch (error) {
      print(error);
      return false;
    }
  }
}

class BoundingBox {
  double top;
  double left;
  double right;
  double bottom;

  BoundingBox._(this.top, this.left, this.right, this.bottom);
  factory BoundingBox.fromJson(Map<dynamic, dynamic> json) {
    return BoundingBox._(json['top'], json['left'], json['right'], json['bottom']);
  }
}

class PatientsMetadata {
  int numOfPoints;
  int timestamp;
  BoundingBox boundingBox;

  PatientsMetadata._(this.numOfPoints, this.timestamp, this.boundingBox);

  factory PatientsMetadata.fromJson(Map<dynamic, dynamic> json) {
    var boundingBox = BoundingBox.fromJson(json['bounding_box']);
    return PatientsMetadata._(json['num_of_points'], json['timestamp'], boundingBox);
  }
}

class PlaceVisit {
  String name;
  // in degrees
  double lat;
  // in degrees
  double lng;
  // timestamp, in seconds
  int begin;
  // timestamp, in seconds
  int end;

  PlaceVisit._(this.name, this.lat, this.lng, this.begin, this.end);

  factory PlaceVisit.fromJson(json) {
    return PlaceVisit._(
        json['name'], json['lat'], json['lng'], json['begin'], json['end']);
  }

  static List<PlaceVisit> parseGoogleTakeoutFormat(json) {
    List<Map<dynamic, dynamic>> objs = json['timelineObjects'];
    if (objs == null) {
      print('Cannot find timelineObjects...');
      return null;
    }

    List<PlaceVisit> output = [];
    for (var i = 0; i < objs.length; i++) {
      var obj = objs[i];
      Map<dynamic, dynamic> placeVisit = obj['placeVisit'];
      if (placeVisit == null) {
        continue;
      }

      output.add(PlaceVisit.fromJson({
        'name': placeVisit['location']['name'],
        'lat': placeVisit['location']['latitudeE7'] / 10000000.0,
        'lng': placeVisit['location']['longitudeE7'] / 10000000.0,
        'begin': (placeVisit['duration']['startTimestampMs'] / 1000.0).floor(),
        'end': (placeVisit['duration']['endTimestampMs'] / 1000.0).floor(),
      }));
    }
    return output;
  }
}
