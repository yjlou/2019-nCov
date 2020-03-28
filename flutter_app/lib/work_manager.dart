import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'location_collector.dart';

void callbackDispatcher() {
  Workmanager.executeTask((String task, dynamic inputData) async {
    print(task);
    switch (task) {
      case LocationCollector.TASK_TICK:
        await LocationCollector().tick();
        break;
      case LocationCollector.TASK_GET_LOCATION_CALLBACK:
        // print(inputData);
        await LocationCollector().getLocationCallback(inputData);
        break;
      case "sync_server":
        break;
    }
    return Future.value(true);
  });
}

class WorkManager {
  factory WorkManager() {
    if (_instance == null) {
      _instance = WorkManager._makeInstance();
    }
    return _instance;
  }

  WorkManager._makeInstance() {
    // pass
  }

  static WorkManager _instance;
  static const MethodChannel _channel = MethodChannel('events.pandemic.covid19/location_plugin');

  bool _initialized = false;


  void initialize() async {
    if (_initialized) return;

    Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
  }

  MethodChannel getLocationChannel() {
    return _channel;
  }
}