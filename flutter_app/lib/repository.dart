

import 'dart:convert';
import 'dart:math';

import 'package:covid19/location_collector.dart';
import 'package:json_store/json_store.dart';
import 'package:location/location.dart';
import 'package:synchronized/synchronized.dart';

abstract class Repository {
  // Save location to repository.
  Future<void> saveLocation(LocationData locationData);

  // Get location records from repository.
  // We use a python-like array indexing, e.g.
  //   getLocation(beginIndex: 0)  ==> get all
  //   getLocation(beginIndex: -1) ==> get last one
  //   getLocation(lastIndex: 4) ==> get first 4
  //   getLocation(lastIndex: -4) ==> get all, except the last 4
  // Returns elements [beginIndex, lastIndex)
  Future<List<LocationData>> getLocation({int beginIndex, int lastIndex});

  Future<void> clear();
}


class RepositoryImpl implements Repository {
  static RepositoryImpl _instance;
  static String NEXT_INDEX_KEY = "NEXT_INDEX_KEY";

  factory RepositoryImpl() {
    if (_instance == null) {
      _instance = RepositoryImpl.private();
    }
    return _instance;
  }

  JsonStore _jsonStore;
  Lock _lock;

  RepositoryImpl.private() {
    _jsonStore = JsonStore(
        dbName: 'events_pandemic_covid19_location_history',
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

  @override
  Future<List<LocationData>> getLocation({int beginIndex, int lastIndex}) async {
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

      List<LocationData> result = [];
      // TODO improve this...
      for (int index = beginIndex; index < lastIndex; index++) {
        String key = "record-${index}-%";
        var json = await _jsonStore.getItemLike(key);
        if (json == null) {
          print("Cannot find record with key: ${key}");
          continue;
        }
        result.add(LocationCollector.mapToLocationData(json));
      }
      return result;
    });
  }

  @override
  Future<void> saveLocation(LocationData locationData) async {
    await _lock.synchronized(() async {
      int next_index = await _getNextIndex();
      var batch = await _jsonStore.startBatch();
      await _jsonStore.setItem(
        _makeLocationDataKey(locationData, next_index),
        _locationDataToMap(locationData),
        batch: batch
      );

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

  String _makeLocationDataKey(LocationData data, int index) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(data.time.toInt());
    var key = "record-${index}-${dateTime.year}-${dateTime.month}-${dateTime.day}";
//    var key = "record-${index}";
    print("key: ${key}");
    return key;
  }

  Map<String, dynamic> _locationDataToMap(LocationData data) {
    return {
      'latitude': data.latitude,
      'longitude': data.longitude,
      'altitude': data.altitude,
      'time': data.time,
      'accurity': data.accuracy,
     };
  }
}