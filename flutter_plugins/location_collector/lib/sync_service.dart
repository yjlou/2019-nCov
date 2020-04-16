import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'http_utils.dart';
import 'location_repository.dart';
import 'matched_result.dart';
import 'patients_data.dart';
import 'work_manager.dart';

// Get update from backend service
class SyncService {
  static const TASK_NAME =
      'events.pandemic.plugins.location_collector/sync_service';
  static const SERVER_URL = 'https://pandemic.events';
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

  Future<void> tick({StreamController stream}) async {
    void _notify(String message) {
      if (stream != null) {
        stream.add(message);
      }
      print(message);
    }

    try {
      _notify('Downloading metadata from server...');
      final metadata =
      json.decode(await fetchHttpFile('${SERVER_URL}/${ROOT_META_PATH}'));

      final defaultPatientsData = metadata['defaultPatientsData'] as List;
      if (defaultPatientsData == null) {
        _notify('No patients data found, done.');
        return;
      }

      final List<PatientsData> patientsDataList = [
        for (var it in defaultPatientsData) PatientsData.fromJson(it)
      ];

      _notify('Loading user data from local database...');
      final List<Location> locationList = await SqliteRepository()
          .getLocation();
      if (locationList.length == 0) {
        _notify('No data found, please enable location recording...');
        return;
      } else {
        _notify('Loaded ${locationList.length} points from local database');
      }
      final List<PlaceVisit> placeVisitList = [
        for (var location in locationList) location.toPlaceVisit()
      ];
      BoundingBox boundingBox = BoundingBox.fromPlaceVisitList(placeVisitList);
      // TODO: merge placeVisit if the user didn't move?

      List<MatchedPoint> ret = [];
      for (var it in patientsDataList) {
        if (!(await it.fetch())) {
          _notify(
              'Cannot fetch patients data: desc=${it.desc}, path=${it
                  .path}, meta=${it.meta}');
          continue;
        }

        _notify(
            'Checking patients data: desc=${it.desc}, size=${it.points
                .length}');

        // Compare it with all data points.
        if (!boundingBox.isOverlapped(it.boundingBox)) {
          _notify('Bounding box does not overlap, skip.');
          continue;
        }

        for (var patientPlaceVisit in it.points) {
          for (var userPlaceVisit in placeVisitList) {
            if (userPlaceVisit.isOverlapped(patientPlaceVisit)) {
              ret.add(MatchedPoint.make(userPlaceVisit, patientPlaceVisit));
            }
          }
        }
      }
      _notify('Found ${ret.length} matches.');
      _notify('Saving ${ret.length} records to database...');
      SqliteRepository().setMatchedResult(ret);
      _notify('Done.');
    } on HttpException catch (error) {
      _notify(error.message);
    } catch (error) {
      _notify(error);
    } finally {
      if (stream != null) {
        stream.close();
      }
    }
  }
}
