import 'package:workmanager/workmanager.dart';

import 'location_collector.dart';

// This is the entry point when Workmanager plugin initialize flutter engine in
// the background.
void callbackDispatcher() {
  Workmanager.executeTask((String task, dynamic inputData) async {
    print('task: ${task}');
    switch (task) {
      case LocationCollector.TASK_TICK:
        // tick() function makes another MethodChannel call, we cannot await
        // tick() function, otherwise current evaluation won't be finished.
        // This is why we got "cancelled" error / warning previously.
        LocationCollector().tick();
//        print('Finish tick');
        break;
      case LocationCollector.TASK_GET_LOCATION_CALLBACK:
        await LocationCollector().getLocationCallback(inputData);
//        print('Finish get_location_callback');
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

  Future<void> initialize() async {
    if (_initialized) return;

    await Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
  }
}