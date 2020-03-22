import 'package:flutter/services.dart';

// Corresponds to BackgroundLocationHandler
class BackgroundLocation {
  // This is also defined in BackgroundLocationHandler.kt
  static const CHANNEL_NAME = 'events.pandemic.covid19/background_location';
  static const MethodChannel _channel = MethodChannel(CHANNEL_NAME);

  static stop() {
    _channel.invokeMethod('stop');
  }

  static start() {
    _channel.invokeMethod('start');
  }
}