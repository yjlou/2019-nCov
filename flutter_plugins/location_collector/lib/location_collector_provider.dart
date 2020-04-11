import 'package:location_collector/location_collector.dart';
import 'package:location_permissions/location_permissions.dart';

abstract class LocationCollector {
  Future<bool> isRunning();

  Future<bool> start();

  Future<bool> stop();

  Future<bool> checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
        break;
      case PermissionStatus.granted:
        return true;
        break;
    }
    return false;
  }
}

class LocationCollectorProvider {
  static LocationCollector getInstance() {
    return BackgroundLocatorLocationCollector();
  }
}
