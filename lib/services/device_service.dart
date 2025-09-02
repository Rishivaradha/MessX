import 'dart:io';
import 'package:flutter/services.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  static const MethodChannel _channel = MethodChannel('device_info');

  String? _deviceId;
  String? _deviceName;

  String get deviceId => _deviceId ?? 'unknown';
  String get deviceName => _deviceName ?? 'Unknown Device';

  Future<void> initialize() async {
    await _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        _deviceId = await _channel.invokeMethod('getAndroidId');
        _deviceName = await _channel.invokeMethod('getDeviceName');
      } else if (Platform.isIOS) {
        _deviceId = await _channel.invokeMethod('getIOSId');
        _deviceName = await _channel.invokeMethod('getDeviceName');
      }
    } catch (e) {
      _deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      _deviceName = Platform.isAndroid ? 'Android Device' : 'iOS Device';
    }
  }

  // Removed Bluetooth-related methods - using Internet-based chat now
}
