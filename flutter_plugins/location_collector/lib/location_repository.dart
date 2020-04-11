import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_locator/location_dto.dart';
import 'package:json_store/json_store.dart';
import 'package:location_collector/patients_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';


abstract class Repository {
  // Save location to repository.
  Future<void> saveLocation(Location locationData);

  // Get location records from repository.
  // We use a python-like array indexing, e.g.
  //   getLocation(beginIndex: 0)  ==> get all
  //   getLocation(beginIndex: -1) ==> get last one
  //   getLocation(lastIndex: 4) ==> get first 4
  //   getLocation(lastIndex: -4) ==> get all, except the last 4
  // Returns elements [beginIndex, lastIndex)
  Future<List<Location>> getLocation({int beginIndex, int lastIndex});

  Future<void> clear();
}


class SqliteRepository implements Repository {
  static SqliteRepository _instance;
  static String NEXT_INDEX_KEY = 'NEXT_INDEX_KEY';
  static String DB_NAME = 'events_pandemic_covid19_location_history';

  factory SqliteRepository() {
    if (_instance == null) {
      _instance = SqliteRepository._make();
    }
    return _instance;
  }

  JsonStore _jsonStore;
  Lock _lock;

  SqliteRepository._make() {
    _jsonStore = JsonStore(
        dbName: DB_NAME,
        inMemory: false);
    _lock = new Lock(reentrant: true);
  }

  Future<int> _getNextIndex() async {
    return await _lock.synchronized(() async {
      Map<String, dynamic> json = await _jsonStore.getItem(NEXT_INDEX_KEY);
      return json == null ? 0 : json['value'] as int;
    });
  }

  @override
  Future<void> clear() async {
    return await _lock.synchronized(() async {
      await _jsonStore.clearDataBase();
    });
  }

  Future<String> getDatabasePath() async {
    final Directory path = await getApplicationDocumentsDirectory();
    return '${path.path}/${DB_NAME}.db';
  }

  Future<void> export(String filePath) async {
    var records = await _jsonStore.getListLike('record-%');
    var outObj = [];
    for (var i = 0; i < records.length; i++) {
      final t = records[i]['time'] as double;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(t.toInt());
      outObj.add(
        {
          'placeVisit': {
            'location': {
              'latitudeE7': records[i]['latitude'] * 1e7,
              'longitudeE7': records[i]['longitude'] * 1e7,
              'name': dateTime.toIso8601String(),
            },
            'duration': {
              // let's mark a 10 minutes duration.
              'startTimestampMs': t - 5 * 60 * 1000,
              'endTimestampMs': t + 5 * 60 * 1000,
            }
          }
        }
      );
    }
    String encoded = json.encode({
      'timelineObjects': outObj
    });
    final file = new File(filePath);
    await file.writeAsString(encoded);
  }

  @override
  Future<List<Location>> getLocation({int beginIndex, int lastIndex}) async {
    return await _lock.synchronized(() async {
      int count = await _getNextIndex();

      if (beginIndex == null) {
        beginIndex = 0;
      } else if (beginIndex < 0) {
        beginIndex = max(0, beginIndex + count);
      }

      if (lastIndex == null) {
        lastIndex = count;
      } else if (lastIndex < 0) {
        lastIndex = max(0, lastIndex + count);
      }

      List<Location> result = [];
      // TODO improve this...
      for (int index = beginIndex; index < lastIndex; index++) {
        String key = "record-${index}-%";
        var json = await _jsonStore.getItemLike(key);
        if (json == null) {
          print("Cannot find record with key: ${key}");
          continue;
        }
        result.add(Location.fromJson(json));
      }
      print("getLocation: return ${result.length} elements");
      return result;
    });
  }

  @override
  Future<void> saveLocation(Location location) async {
    await _lock.synchronized(() async {
      int next_index = await _getNextIndex();
      var batch = await _jsonStore.startBatch();
      try {
        await _jsonStore.setItem(
            _makeLocationDataKey(location, next_index),
            location.toJson(),
            encrypt: true, // turn this on in production.
            batch: batch,
            timeToLive: Duration(days: 28),  // technically, we only need 14 days.
        );
      } catch (error) {
        print(error);
        throw error;
      }

      next_index ++;
      await _jsonStore.setItem(
          NEXT_INDEX_KEY,
          { 'value': next_index },
          batch: batch
      );
      await _jsonStore.commitBatch(batch);

      print("saved to database! Next index: ${next_index}");
    });
  }

  String _makeLocationDataKey(Location data, int index) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(data.time.toInt());
    var key = "record-${index}-${dateTime.year}-${dateTime.month}-${dateTime.day}";
    print("key: ${key}");
    return key;
  }
}


class Location {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final double time;

  Location._(this.latitude, this.longitude, this.accuracy, this.altitude,
      this.speed, this.speedAccuracy, this.heading, this.time);

  factory Location.fromJson(Map<dynamic, dynamic> json) {
    return Location._(
        toDouble(json['latitude']),
        toDouble(json['longitude']),
        toDouble(json['accuracy']),
        toDouble(json['altitude']),
        toDouble(json['speed']),
        toDouble(json['speed_accuracy']),
        toDouble(json['heading']),
        toDouble(json['time']));
  }
  
  factory Location.fromLocationDto(LocationDto locationDto) {
    return Location.fromJson(locationDto.toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': this.latitude,
      'longitude': this.longitude,
      'accuracy': this.accuracy,
      'altitude': this.altitude,
      'speed': this.speed,
      'speed_accuracy': this.speedAccuracy,
      'heading': this.heading,
      'time': this.time,
    };
  }

  PlaceVisit toPlaceVisit() {
    return PlaceVisit.fromJson({
      'name': DateTime.fromMillisecondsSinceEpoch(this.time.toInt()).toIso8601String(),
      'lat': this.latitude,
      'lng': this.longitude,
      'begin': this.time / 1000 - 5 * 60,
      'end': this.time / 1000 + 5 * 60,
    });
  }

  static double toDouble(dynamic x) {
    if (x is double) {
      return x;
    }
    if (x is int) {
      return x + 0.0;
    }
    return null;
  }
}
