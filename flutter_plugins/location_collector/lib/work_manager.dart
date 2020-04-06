import 'package:workmanager/workmanager.dart';


// This is the entry point when Workmanager plugin initialize flutter engine in
// the background.
void callbackDispatcher() {
  Workmanager.executeTask((String task, dynamic inputData) async {
    print('task: ${task}');
    switch (task) {
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