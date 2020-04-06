import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:location_collector/location_collector_provider.dart';

import 'location_repository.dart';

//class WorkManagerLocationCollector extends LocationCollector {
//  static const String TAG = 'events.pandemic.plugins.location_collector';
//  static const String CHANNEL_NAME = 'events.pandemic.plugins.location_collector';
//
//  static const String TASK_TICK = '${TAG}/tick';
//  static const String TASK_GET_LOCATION_CALLBACK = '${TAG}/get_location_callback';
//
//  static WorkManagerLocationCollector _instance;
//
//  factory WorkManagerLocationCollector() {
//    if (_instance == null) {
//      _instance = WorkManagerLocationCollector._make();
//    }
//    return _instance;
//  }
//
//  MethodChannel _channel = const MethodChannel(CHANNEL_NAME);
//
//  WorkManagerLocationCollector._make() {
//    // pass
//  }
//
//  // API for testing.
//  Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }
//
//  @override
//  Future<bool> start() async {
//    await WorkManager().initialize();
//
//    // Let's make sure we have permission of location service.
//    if (!await checkLocationPermission()) {
//      return false;
//    }
//
//    // Default duration is 15 minutes. First event should be fired immediately.
//    await Workmanager.registerPeriodicTask(TASK_TICK, TASK_TICK,
//        existingWorkPolicy: ExistingWorkPolicy.replace);
//
//    return true;
//  }
//
//  @override
//  Future<bool> stop() async {
//    await Workmanager.cancelByUniqueName(TASK_TICK);
//    await Workmanager.cancelByUniqueName(TASK_GET_LOCATION_CALLBACK);
//    return true;
//  }
//
//  Future<bool> tick() async {
//    try {
//      await _channel.invokeMethod("get_location");
//    } catch (error) {
//      print('Failed in tick: ${error}');
//    }
//    return true;
//  }
//
//  Future<void> getLocationCallback(dynamic data) async {
//    // This function is called in another context (engine), so the _location is not shared with UI thread...
//    try {
//      print("1");
//      Location location = Location.fromJson(data);
//      print("2");
//      // _location.add(location);
//      print("3");
//      double dt = location.time;
//      print("4");
//      DateTime t = DateTime.fromMillisecondsSinceEpoch(dt.toInt());
//      print("5");
//      print(
//          "getLocation: ${t.toLocal()} ${location.latitude} ${location.longitude}");
//      await SqliteRepository().saveLocation(location);
//      print("6");
//    } catch (error) {
//      print('Failed in getLocationCallback: ${error}');
//    }
//  }
//}


class BackgroundLocatorLocationCollector extends LocationCollector {
  static BackgroundLocatorLocationCollector _instance;
  static final _ISOLATE_NAME = 'LocatorIsolate';

  factory BackgroundLocatorLocationCollector() {
    if (_instance == null) {
      _instance = BackgroundLocatorLocationCollector._make();
      _instance.init();
    }
    return _instance;
  }

  ReceivePort _port = ReceivePort();

  BackgroundLocatorLocationCollector._make() {
    // pass
  }

  static void callback(LocationDto locationDto) async {
    print('location in dart: ${locationDto.toString()}');
    final location = Location.fromLocationDto(locationDto);
    SqliteRepository().saveLocation(location);
    final SendPort send = IsolateNameServer.lookupPortByName(_ISOLATE_NAME);
    send?.send(locationDto);
  }

  static void notificationCallback() {
    print('notificationCallback');
  }

  Future<bool> init() async {
    if (IsolateNameServer.lookupPortByName(_ISOLATE_NAME) != null) {
      IsolateNameServer.removePortNameMapping(_ISOLATE_NAME);
    }
    IsolateNameServer.registerPortWithName(_port.sendPort, _ISOLATE_NAME);
    _port.listen((dynamic data) async {
      print('_port.listen!');
      // TODO: do something with data?
    });

    print('Initializing BackgroundLocator...');
    await BackgroundLocator.initialize();
    print('Initialization done.');
    var isRunning = await BackgroundLocator.isRegisterLocationUpdate();
    print('BackgroundLocator Running ${isRunning.toString()}');
  }

  @override
  Future<bool> isRunning() async {
    return await BackgroundLocator.isRegisterLocationUpdate();
  }

  @override
  Future<bool> start() async {
      if (!await checkLocationPermission()) {
      return false;
    }

    await BackgroundLocator.registerLocationUpdate(
      callback,
      androidNotificationCallback: notificationCallback,
      settings: LocationSettings(
        notificationTitle: "covid19 is running...",
        notificationMsg: "covid19 is tracking your location in the background",
        wakeLockTime: 20,  // unit: minutes
        autoStop: false,
        interval: 60, // unit: seconds
      ),
    );
    print('LocationCollector.start: BackgroundLocator registered');
    return true;
  }

  @override
  Future<bool> stop() async {
    await BackgroundLocator.unRegisterLocationUpdate();
    return true;
  }

}