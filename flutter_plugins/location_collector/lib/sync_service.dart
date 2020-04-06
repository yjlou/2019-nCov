import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'work_manager.dart';

// Get update from backend service
class SyncService {
  static const TASK_NAME = 'events.pandemic.plugins.location_collector/sync_service';
  static const RESOURCE_URL = 'https://raw.githubusercontent.com/yjlou/2019-nCov/master/countries/israel/output.json';
  static SyncService _instance;

  factory SyncService() {
    if (_instance == null) {
      _instance = SyncService._make();
    }
    return _instance;
  }

  SyncService._make() {
    // pass
  }

  Future<bool> start() async {
    await WorkManager().initialize();

    final constraints = Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    );

    // Technically, we can start a one time job that starts at next 00:00,
    // and then run periodically, but let's keep it simple for now.
    await Workmanager.registerPeriodicTask(
        TASK_NAME,
        TASK_NAME,
        frequency: Duration(hours: 8),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: constraints,
    );
    return true;
  }

  Future<bool> stop() async {
    await Workmanager.cancelByUniqueName(TASK_NAME);
    return true;
  }

  Future<void> tick() async {
    http.Response response = await http.get(RESOURCE_URL);
    if (response.statusCode == 200) {
      final obj = json.decode(response.body);
      final hasKey = obj['timelineObjects'] != null;
      if (hasKey) {
        print('Has timelineObjects');
      } else {
        print('Does not have timelineObjects');
      }
    } else {
      print('Failed to get server resource ${response.statusCode}');
    }
  }
}