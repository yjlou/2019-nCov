import 'package:workmanager/workmanager.dart';

import 'location_collector.dart';

// This is the entry point when Workmanager plugin initialize flutter engine in
// the background.
void callbackDispatcher() {
  Workmanager.executeTask((String task, dynamic inputData) async {
    print('task: ${task}');
    switch (task) {
      case LocationCollector.TASK_TICK:
        await LocationCollector().tick();
        // print('PlatformVersion: ${await lc_plugin.LocationCollector.platformVersion}');
        break;
      case LocationCollector.TASK_GET_LOCATION_CALLBACK:
//        print(inputData);
//        print('Callback: ${await LocationCollector().platformVersion}');
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
  bool _initialized = false;

  void initialize() async {
    if (_initialized) return;

    Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
  }
}