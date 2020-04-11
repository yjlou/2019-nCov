import 'dart:convert';
import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'http_utils.dart';
import 'location_repository.dart';
import 'patients_data.dart';
import 'work_manager.dart';

// Get update from backend service
class SyncService {
  static const TASK_NAME =
      'events.pandemic.plugins.location_collector/sync_service';
  static const SERVER_URL = 'https://stimim.github.io/2019-nCov';
  static const ROOT_META_PATH = 'meta.json';
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
    try {
      final metadata =
          json.decode(await fetchHttpFile('${SERVER_URL}/${ROOT_META_PATH}'));

      final defaultPatientsData = metadata['defaultPatientsData'] as List;
      if (defaultPatientsData == null) {
        return;
      }

      List<PatientsData> patientsDataList = [];
      for (var i = 0; i < defaultPatientsData.length; i++) {
        final patientsData = PatientsData.fromJson(defaultPatientsData[i]);
        patientsDataList.add(patientsData);
      }

      final List<Location> locationList =
          await SqliteRepository().getLocation();
      print('Loaded ${locationList.length} points from local database');

      final List<PlaceVisit> placeVisitList = locationList.map((it) {
        return it.toPlaceVisit();
      });
      BoundingBox boundingBox = BoundingBox.fromPlaceVisitList(placeVisitList);

      patientsDataList.forEach((it) async {
        if (!(await it.fetch())) {
          print(
              'Cannot fetch patients data: desc=${it.desc}, path=${it.path}, meta=${it.meta}');
          return;
        }

        print(
            'Checking patients data: desc=${it.desc}, size=${it.points.length}');
        // Compare it with all data points.
        if (!boundingBox.isOverlapped(it.boundingBox)) {
          return;
        }
        List<MatchedPoint> ret = [];
        placeVisitList.forEach((userPlaceVisit) {
          it.points.forEach((patientPlaceVisit) {
            if (userPlaceVisit.isOverlapped(patientPlaceVisit)) {
              ret.add(MatchedPoint.make(userPlaceVisit, patientPlaceVisit));
            }
          });
        });
        print('Found ${ret.length} matches');

        if (ret.length > 0) {
          // TODO: store matched points
        }
      });
    } on HttpException catch (error) {
      print(error.message);
    } catch (error) {
      print(error);
    }
  }
}
