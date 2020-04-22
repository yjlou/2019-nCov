import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'sync_service.dart';

// This is the entry point when Workmanager plugin initialize flutter engine in
// the background.
void callbackDispatcher() {
  Workmanager.executeTask((String task, dynamic inputData) async {
    print('task: ${task}');
    switch (task) {
      case SyncService.TASK_NAME:
        // Avoid making synchronize call.
        await SyncService().tick();
        break;
      case Workmanager.iOSBackgroundTask:
        // iOS always run with Workmanager.iOSBackgroundTask.
        await SyncService().tick();
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

    await Workmanager.initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  }
}
