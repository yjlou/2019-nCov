import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_collector/location_collector.dart';

void main() {
  const MethodChannel channel = MethodChannel('location_collector');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await LocationCollector.platformVersion, '42');
  });
}
