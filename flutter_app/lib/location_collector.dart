import 'dart:math';

import 'package:covid19/work_manager.dart';
import 'package:location/location.dart';
import 'package:workmanager/workmanager.dart';

import 'repository.dart';

import 'package:location_collector/location_collector.dart' as lc_plugin;

// Corresponds to BackgroundLocationHandler
class LocationCollector {
  factory LocationCollector() {
    if (_instance == null) {
      _instance = LocationCollector._makeInstance();
    }
    return _instance;
  }

  static LocationCollector _instance;
  static const String TASK_TICK = "events.pandemic.covid19/get_location";
  static const String TASK_GET_LOCATION_CALLBACK =
      "events.pandemic.covid19/get_location_callback";

  List<LocationData> _location = [];

  LocationCollector._makeInstance() {
    // Does nothing.
  }

  Future<bool> start() async {
    WorkManager().initialize();

    // Workmanager.cancelByTag(WORKER_TAG);
    // Workmanager.cancelByTag(TASK_GET_LOCATION_CALLBACK);

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
    Workmanager.registerPeriodicTask(TASK_TICK, TASK_TICK,
        existingWorkPolicy: ExistingWorkPolicy.replace);

    return true;
  }

  Future<bool> tick() async {
    try {
      await WorkManager().getLocationChannel().invokeMethod("get_location");
    } catch (error) {
      print(error);
    }
    return true;
  }

  Future<bool> stop() async {
    Workmanager.cancelByTag(TASK_TICK);
    Workmanager.cancelByTag(TASK_GET_LOCATION_CALLBACK);
    return true;
  }

  List<LocationData> get({int size = 5}) {
    int length = _location.length;
    int start = max<int>(length - size, 0);
    return _location.sublist(start);
  }

  Future<void> getLocationCallback(dynamic location) async {
    // This function is called in another context (engine), so the _location is not shared with UI thread...
    try {
      print("1");
      LocationData locationData = mapToLocationData(location);
      print("2");
      _location.add(locationData);
      print("3");
      double dt = locationData.time;
      print("4");
      DateTime t = DateTime.fromMillisecondsSinceEpoch(dt.toInt());
      print("5");
      print(
          "getLocation: ${t.toLocal()} ${locationData.latitude} ${locationData.longitude}");
      await RepositoryImpl().saveLocation(locationData);
      print("6");
    } catch (error) {
      print(error);
    }
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
