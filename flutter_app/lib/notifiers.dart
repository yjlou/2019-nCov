import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:location_collector/location_collector.dart';
import 'package:location_collector/location_repository.dart';
import 'package:location_collector/matched_result.dart';
import 'package:location_collector/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleModel extends ChangeNotifier {
  static const String KEY_LOCALE = 'LOCALE';
  Locale _locale;

  get locale => _locale;

  static Future<Locale> loadLocaleFromSharedPreferences() async {
    final instance = await SharedPreferences.getInstance();
    final strLocale = instance.getString(KEY_LOCALE);
    Locale locale;
    try {
      final tokens = strLocale.split('_');
      if (tokens.length == 1) {
        locale = Locale(tokens[0]);
      } else {
        locale = Locale(tokens[0], tokens[1]);
      }
      return locale;
    } catch (error) {
      // does nothing
    }
    return null;
  }

  AppLocaleModel() {
    loadLocaleFromSharedPreferences().then(
      (locale) {
        if (locale == null) {
          locale = window.locale;
        }
        print('${locale.languageCode}_${locale.countryCode}');
        if (!supportedLocales.contains(locale)) {
          _locale = supportedLocales[0];
        } else {
          _locale = locale;
        }
        notifyListeners();
      },
    );
  }

  void setLocale(BuildContext context, Locale locale) {
    _locale = locale;
    FlutterI18n.refresh(context, _locale);
    SharedPreferences.getInstance().then((instance) {
      instance.setString(
          KEY_LOCALE, '${_locale.languageCode}_${_locale.countryCode}');
    });
    notifyListeners();
  }

  static final List<Locale> supportedLocales = [
    Locale('en', 'US'), // this is the default value.
    Locale('zh', 'TW'),
    // TODO: add more locales
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
    _getMatchedResultMetadata();
    _getMatchedResult();
    SharedPreferences.getInstance().then((instance) {
      _isRunning = instance.getBool(KEY_IS_CHECKER_RUNNING);
      if (_isRunning == null) {
        _isRunning = false;
      }
      notifyListeners();
    });

    Timer.periodic(
      Duration(minutes: 5),
      (timer) {
        print('Checking if metadata has been updated...');
        SqliteRepository().getMatchedResultMetadata().then(
          (metadata) {
            print('new: ${metadata.time}, old: ${_metadata.time}');
            if (metadata.time == _metadata.time) {
              return;
            }
            _metadata = metadata;
            _getMatchedResult();
          },
        );
      },
    );
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
      _getMatchedResultMetadata();
      _getMatchedResult();
    });
  }

  void _getMatchedResult() {
    SqliteRepository().getMatchedResult().then(
      (matchedPointList) {
        _matchedPointList = matchedPointList;
        notifyListeners();
      },
    );
  }

  _getMatchedResultMetadata() {
    SqliteRepository().getMatchedResultMetadata().then(
      (metadata) {
        _metadata = metadata;
        notifyListeners();
      },
    );
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
