import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class BluetoothHandler {
  static const MethodChannel _channel = MethodChannel('com.example.company_app/bluetooth');

  static bool? _lastKnownAvailability;
  static bool? _lastKnownEnabled;
  static DateTime? _lastCheck;
  static const Duration _cacheTimeout = Duration(seconds: 1);

  static Future<Map<String, dynamic>> getBluetoothInfo() async {
    final now = DateTime.now();

    if (_lastCheck != null &&
        _lastKnownAvailability != null &&
        _lastKnownEnabled != null &&
        now.difference(_lastCheck!) < _cacheTimeout) {
      return {
        'isAvailable': _lastKnownAvailability,
        'isEnabled': _lastKnownEnabled,
      };
    }

    final Map<String, dynamic> info = {};

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBluetoothState');
      final Map<String, dynamic> state = Map<String, dynamic>.from(result ?? {});

      info['isAvailable'] = state['isAvailable'] ?? false;
      info['isEnabled'] = state['isEnabled'] ?? false;

      if (info['isEnabled'] == true) {
        final List<dynamic>? devices = await _channel.invokeMethod<List<dynamic>>('getPairedDevices');
        if (devices != null) {
          info['pairedDevices'] =
              devices.map((device) => Map<String, dynamic>.from(device as Map<dynamic, dynamic>)).toList();
        }
      }

      return info;
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to get Bluetooth info: ${e.message}');
    }
  }

  static Future<void> startScan() async {
    try {
      await _channel.invokeMethod('startScan');
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to start scan: ${e.message}');
    }
  }

  static Future<void> stopScan() async {
    try {
      await _channel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to stop scan: ${e.message}');
    }
  }

  static Future<bool> connectToDevice(String address) async {
    try {
      final result = await _channel.invokeMethod<bool>('connectToDevice', address);
      return result ?? false;
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to connect: ${e.message}');
    }
  }

  static Future<bool> pairDevice(String address) async {
    try {
      return await _channel.invokeMethod<bool>('pairDevice', address) ?? false;
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to pair: ${e.message}');
    }
  }

  static Future<void> startAdvertising({
    Map<String, dynamic>? settings,
  }) async {
    try {
      await _channel.invokeMethod('startAdvertising', settings);
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to start advertising: ${e.message}');
    }
  }

  static Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopAdvertising');
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to stop advertising: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>?> getDeviceMetadata(String address) async {
    try {
      final String? metadata = await _channel.invokeMethod('getDeviceMetadata', address);
      return metadata != null ? jsonDecode(metadata) as Map<String, dynamic> : null;
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to get device metadata: ${e.message}');
    }
  }

  static Future<bool> connectProfile({
    required String address,
    required String profile,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('connectProfile', {
        'address': address,
        'profile': profile,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw BluetoothException('Failed to connect profile: ${e.message}');
    }
  }
}

class BluetoothException implements Exception {
  BluetoothException(this.message);
  final String message;

  @override
  String toString() => message;
}
