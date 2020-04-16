import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:location_collector/location_collector_provider.dart';

import 'location_repository.dart';

class BackgroundLocatorLocationCollector extends LocationCollector {
  static BackgroundLocatorLocationCollector _instance;
  static const _ISOLATE_NAME = 'LocatorIsolate';

  factory BackgroundLocatorLocationCollector() {
    if (_instance == null) {
      _instance = BackgroundLocatorLocationCollector._make();
      _instance.init();
    }
    return _instance;
  }

  ReceivePort _port = ReceivePort();
  void Function(Location) _onReceivedLocation;

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

  void registerOnReceiveLocation(void Function(Location) callback) {
    _onReceivedLocation = callback;
  }

  Future<void> init() async {
    if (IsolateNameServer.lookupPortByName(_ISOLATE_NAME) != null) {
      IsolateNameServer.removePortNameMapping(_ISOLATE_NAME);
    }
    IsolateNameServer.registerPortWithName(_port.sendPort, _ISOLATE_NAME);
    _port.listen((dynamic data) async {
      if (data == null) {
        return;
      }
      if (_onReceivedLocation != null) {
        try {
          final location = Location.fromLocationDto(data);
          _onReceivedLocation(location);
        } catch (error) {
          print(error);
        }
      }
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
    // somehow we cannot await this function call.
    BackgroundLocator.registerLocationUpdate(
      callback,
      androidNotificationCallback: notificationCallback,
      settings: LocationSettings(
        notificationTitle: "covid19 is running...",
        notificationMsg: "covid19 is tracking your location in the background",
        // unit: minutes
        wakeLockTime: 20,
        autoStop: false,
        // unit: seconds
        interval: 5 * 60,
      ),
    );
    print('LocationCollector.start: BackgroundLocator registered');
    return true;
  }

  @override
  Future<bool> stop() async {
    // somehow we can't await this function call.
    BackgroundLocator.unRegisterLocationUpdate();
    return true;
  }
}
