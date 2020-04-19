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

  Future<bool> tick({StreamController stream}) async {
    void info(String message) {
      if (stream != null) {
        stream.add(message);
      }
      print(message);
    }

    void die(String message) {
      // TODO: abort the function??
      // Currently this is not an issue because we only call this function in error handler.
      if (stream != null) {
        stream.addError(message);
      }
      print('ERROR: $message');
    }

    try {
      info('Downloading metadata from server...');
      final rawMetadata =
          await fetchHttpFile('${SERVER_URL}/${ROOT_META_PATH}');
      final metadata = json.decode(rawMetadata);

      final defaultPatientsData = metadata['defaultPatientsData'] as List;
      if (defaultPatientsData == null) {
        info('No patients data found, done.');
        return true;
      }

      final List<PatientsData> patientsDataList = [
        for (var it in defaultPatientsData) PatientsData.fromJson(it)
      ];

      info('Loading user data from local database...');
      final List<Location> locationList =
          await SqliteRepository().getLocation();
      if (locationList.length == 0) {
        info('No data found, please enable location recording...');
        return true;
      } else {
        info('Loaded ${locationList.length} points from local database');
      }
      final List<PlaceVisit> placeVisitList = [
        for (var location in locationList) location.toPlaceVisit()
      ];
      BoundingBox boundingBox = BoundingBox.fromPlaceVisitList(placeVisitList);
      // TODO: merge placeVisit if the user didn't move?

      List<MatchedPoint> ret = [];
      for (var it in patientsDataList) {
        if (!(await it.fetch())) {
          info(
              'Cannot fetch patients data:\ndesc="${it.desc}",\npath="${it.path}",\nmeta="${it.meta}"');
          continue;
        }

        info(
            'Checking patients data:\ndesc="${it.desc}",\nsize="${it.points.length}"');

        // Compare it with all data points.
        if (!boundingBox.isOverlapped(it.boundingBox)) {
          info('Bounding box does not overlap, skip.');
          continue;
        } else {
          info('M: ${boundingBox.toString()}');
          info('P: ${it.boundingBox.toString()}');
        }

        for (var patientPlaceVisit in it.points) {
          for (var userPlaceVisit in placeVisitList) {
            if (userPlaceVisit.isOverlapped(patientPlaceVisit)) {
              ret.add(MatchedPoint.make(userPlaceVisit, patientPlaceVisit));
            }
          }
        }
      }
      info('Found ${ret.length} matches,\nsaving to database...');
      SqliteRepository().setMatchedResult(ret);
      info('Done.');
      return true;
    } on HttpException catch (error) {
      die(error.message);
      return false;
    } catch (error) {
      die(error);
      return false;
    } finally {
      if (stream != null) {
        stream.close();
      }
    }
  }
}
