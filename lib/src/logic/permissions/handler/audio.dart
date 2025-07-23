import 'dart:async';

import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioHandler {
  static const platform = MethodChannel('com.example.company_app/audio');

  static Map<String, dynamic>? _safeCastMap(Map<Object?, Object?> input) => input.map((key, value) {
        final safeKey = key?.toString() ?? '';
        final safeValue = switch (value) {
          Map<Object?, Object?>() => _safeCastMap(value),
          List<Object?>() => value.map((item) {
              if (item is Map<Object?, Object?>) {
                return _safeCastMap(item);
              }
              return item;
            }).toList(),
          _ => value,
        };
        return MapEntry(safeKey, safeValue);
      });

  static Future<bool> _checkAudioPermissions() async {
    final status = await Permission.audio.status;
    if (!status.isGranted) {
      final result = await Permission.audio.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<Map<String, dynamic>?> getAudioDeviceInfo() async {
    if (!await _checkAudioPermissions()) {
      return null;
    }

    try {
      final result = await platform.invokeMethod('getAudioDeviceInfo');
      if (result == null) return null;

      return _safeCastMap(result as Map<Object?, Object?>);
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getAudioDeviceInfo', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getAudioDeviceInfo', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAudioRouting() async {
    if (!await _checkAudioPermissions()) {
      return null;
    }

    try {
      final result = await platform.invokeMethod('getAudioRouting');
      if (result == null) return null;

      return _safeCastMap(result as Map<Object?, Object?>);
    } catch (e, stack) {
      Logger.error('Error in getAudioRouting', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAudioFocusInfo() async {
    if (!await _checkAudioPermissions()) {
      return null;
    }

    try {
      return await platform.invokeMethod('getAudioFocusInfo');
    } on PlatformException {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAudioSessionInfo() async {
    if (!await _checkAudioPermissions()) {
      return null;
    }

    try {
      return await platform.invokeMethod('getAudioSessionInfo');
    } on PlatformException {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAvailableAudioDevices() async {
    if (!await _checkAudioPermissions()) {
      return null;
    }

    try {
      final result = await platform.invokeMethod('getAvailableAudioDevices');
      if (result == null) return null;

      final devices = result as List<dynamic>;
      return devices.map((device) {
        if (device is! Map) return <String, dynamic>{};
        return _safeCastMap(device as Map<Object?, Object?>)!;
      }).toList();
    } catch (e, stack) {
      Logger.error('Error in getAvailableAudioDevices', error: e, stackTrace: stack);
      return null;
    }
  }
}
