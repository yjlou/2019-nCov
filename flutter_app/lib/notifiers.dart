import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:location_collector/location_collector.dart';
import 'package:location_collector/location_repository.dart';
import 'package:location_collector/matched_result.dart';
import 'package:location_collector/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsModel extends ChangeNotifier {
  Locale _locale;

  get locale => _locale;

  AppSettingsModel() {
    _locale = window.locale;
    if (!supportedLocales.contains(_locale)) {
      _locale = supportedLocales[0];
    }
  }

  void setLocale(BuildContext context, Locale locale) {
    // FIXME: this won't redraw all widgets.
    _locale = locale;
    FlutterI18n.refresh(context, _locale);
    notifyListeners();
  }

  static final List<Locale> supportedLocales = [
    Locale('en', 'US'), // this is the default value.
    // TODO: add i18n support
    // Locale('zh', 'TW'),
  ];
}

class LocationCollectorModel extends ChangeNotifier {
  bool _isRecordingLocation;
  Location _lastRecordedLocation;

  bool get isRecordingLocation => _isRecordingLocation;

  Location get lastRecordedLocation => _lastRecordedLocation;

  LocationCollectorModel() {
    BackgroundLocatorLocationCollector()
        .registerOnReceiveLocation((Location location) {
      _lastRecordedLocation = location;
      notifyListeners();
    });
    BackgroundLocatorLocationCollector().isRunning().then(
      (isRunning) {
        _isRecordingLocation = isRunning;
        notifyListeners();
      },
    );
    SqliteRepository().getLocation(beginIndex: -1).then(
      (locationList) {
        if (locationList != null && locationList.length > 0) {
          _lastRecordedLocation = locationList[0];
          notifyListeners();
        }
      },
    );
  }

  void toggleRecordingLocation() {
    if (_isRecordingLocation == null) {
      // We are not sure if location collector is running or not, please try again later...
      return;
    }
    if (_isRecordingLocation) {
      BackgroundLocatorLocationCollector().stop();
      _isRecordingLocation = false;
    } else {
      BackgroundLocatorLocationCollector().start();
      _isRecordingLocation = true;
    }
    notifyListeners();
  }
}

enum RecordedLocationCheckerStatus {
  IDLE,
  CHECKING,
  FAILED,
}

class RecordedLocationCheckerModel extends ChangeNotifier {
  static const KEY_IS_CHECKER_RUNNING = 'IS_CHECKER_RUNNING';

  MatchedResultMetadata _metadata;
  String _lastCheckerMessage;
  RecordedLocationCheckerStatus _checkerStatus =
      RecordedLocationCheckerStatus.IDLE;
  List<MatchedPoint> _matchedPointList = [];
  bool _isRunning;

  RecordedLocationCheckerModel() {
    SqliteRepository().getMatchedResultMetadata().then(
      (metadata) {
        _metadata = metadata;
        notifyListeners();
      },
    );
    SqliteRepository().getMatchedResult().then((matchedPointList) {
      _matchedPointList = matchedPointList;
      notifyListeners();
    });
    SharedPreferences.getInstance().then((instance) {
      _isRunning = instance.getBool(KEY_IS_CHECKER_RUNNING);
      if (_isRunning == null) {
        _isRunning = false;
      }
      notifyListeners();
    });
  }

  int get matchedCount => _metadata.count;

  DateTime get lastCheckedTime => _metadata.time;

  String get lastCheckerMessage => _lastCheckerMessage;

  get checkerStatus => _checkerStatus;

  get metadata => _metadata;

  get matchedPointList => _matchedPointList;

  get isRunning => _isRunning;

  void togglePerioidChecker() {
    if (_isRunning) {
      SyncService().stop();
      _isRunning = false;
    } else {
      SyncService().start();
      _isRunning = true;
    }
    SharedPreferences.getInstance().then((instance) {
      instance.setBool(KEY_IS_CHECKER_RUNNING, _isRunning);
    });
    notifyListeners();
  }

  void check() {
    StreamController streamController = StreamController();
    streamController.stream.listen(
      (data) {
        _lastCheckerMessage = data;
        notifyListeners();
      },
      onDone: () {
        _lastCheckerMessage = null;
        _checkerStatus = RecordedLocationCheckerStatus.IDLE;
        notifyListeners();
      },
      onError: (error) {
        _lastCheckerMessage = error.toString();
        _checkerStatus = RecordedLocationCheckerStatus.FAILED;
        notifyListeners();
      },
    );

    _lastCheckerMessage = 'Checking...';
    _checkerStatus = RecordedLocationCheckerStatus.CHECKING;
    _metadata = null;
    notifyListeners();

    SyncService().tick(stream: streamController).then((unused) {
      SqliteRepository().getMatchedResultMetadata().then(
        (metadata) {
          _metadata = metadata;
          notifyListeners();
        },
      );
      SqliteRepository().getMatchedResult().then(
        (matchedPointList) {
          _matchedPointList = matchedPointList;
          notifyListeners();
        },
      );
    });
  }
}

enum AppPageEnum {
  HOME,
  RECORDED_LOCATION,
  MATCHED_RESULT,
  SETTINGS,
}

class AppPageModel extends ChangeNotifier {
  AppPageEnum _currentPage = AppPageEnum.HOME;

  AppPageEnum get currentPage => _currentPage;

  void goto(AppPageEnum newPage) {
    if (newPage == _currentPage) {
      return;
    }

    _currentPage = newPage;
    notifyListeners();
  }
}