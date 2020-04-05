import 'dart:async';

import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:workmanager/workmanager.dart';

import 'location_repository.dart';
import 'work_manager.dart';

class LocationCollector {
  static const String TAG = 'events.pandemic.plugins.location_collector';
  static const String CHANNEL_NAME = 'events.pandemic.plugins.location_collector';

  static const String TASK_TICK = '${TAG}/tick';
  static const String TASK_GET_LOCATION_CALLBACK = '${TAG}/get_location_callback';

  static LocationCollector _instance;

  factory LocationCollector() {
    if (_instance == null) {
      _instance = LocationCollector._make();
    }
    return _instance;
  }

  MethodChannel _channel = const MethodChannel(CHANNEL_NAME);

  LocationCollector._make() {
    // pass
  }

  // API for testing.
  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> start() async {
    await WorkManager().initialize();

    // Let's make sure we have permission of location service.
    Location location = new Location();
    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.DENIED) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.GRANTED) {
        return false;
      }
    }

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Default duration is 15 minutes. First event should be fired immediately.
    await Workmanager.registerPeriodicTask(TASK_TICK, TASK_TICK,
        existingWorkPolicy: ExistingWorkPolicy.replace);
  }

  Future<bool> stop() async {
    await Workmanager.cancelByUniqueName(TASK_TICK);
    await Workmanager.cancelByUniqueName(TASK_GET_LOCATION_CALLBACK);
    return true;
  }

  Future<bool> tick() async {
    try {
      await _channel.invokeMethod("get_location");
    } catch (error) {
      print('Failed in tick: ${error}');
    }
    return true;
  }

  Future<void> getLocationCallback(dynamic location) async {
    // This function is called in another context (engine), so the _location is not shared with UI thread...
    try {
      print("1");
      LocationData locationData = mapToLocationData(location);
      print("2");
      // _location.add(locationData);
      print("3");
      double dt = locationData.time;
      print("4");
      DateTime t = DateTime.fromMillisecondsSinceEpoch(dt.toInt());
      print("5");
      print(
          "getLocation: ${t.toLocal()} ${locationData.latitude} ${locationData.longitude}");
      await SqliteRepository().saveLocation(locationData);
      print("6");
    } catch (error) {
      print('Failed in getLocationCallback: ${error}');
    }
  }

  //----------------------------
  // Helper Functions
  //----------------------------

  static double toDouble(dynamic x) {
    if (x is double) {
      return x;
    }
    if (x is int) {
      return x + 0.0;
    }
    return null;
  }

  static LocationData mapToLocationData(Map<String, dynamic> location) {
    Map<String, double> m = Map<String, double>();
    m = {
      'latitude': toDouble(location['latitude']),
      'longitude': toDouble(location['longitude']),
      'altitude': toDouble(location['altitude']),
      'accuracy': toDouble(location['accuracy']),
      'speed': toDouble(location['speed']),
      'time': toDouble(location['time']),
    };
    LocationData locationData = LocationData.fromMap(m);
    return locationData;
  }
}
