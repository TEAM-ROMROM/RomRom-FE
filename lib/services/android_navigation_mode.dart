import 'package:flutter/services.dart';

class AndroidNavigationMode {
  static const MethodChannel _channel = MethodChannel('romrom/navigation_mode');

  static Future<bool> isGestureMode() async {
    final result = await _channel.invokeMethod<bool>('isGesture');
    return result ?? false;
  }
}
