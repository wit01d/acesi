import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CallHistoryHandler {
  static const platform =
      MethodChannel('com.example.company_app/callhistory');

  static Future<bool> _checkCallLogPermissions() async {
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>?> getCallHistory() async {
    if (!await _checkCallLogPermissions()) {
      return null;
    }

    try {
      final dynamic result = await platform.invokeMethod('getCallHistory');

      if (result == null) {
        return null;
      }

      return List<Map<String, dynamic>>.from(
        (result as List).map(
          (item) => Map<String, dynamic>.from(
            (item as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        ),
      );
    } on PlatformException catch (e) {
      Logger.error('Failed to get call history', error: e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCallStats() async {
    if (!await _checkCallLogPermissions()) return null;

    try {
      final dynamic result = await platform.invokeMethod('getCallStats');

      if (result == null) return null;

      return Map<String, dynamic>.from(
        (result as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } on PlatformException catch (e) {
      Logger.error('Failed to get call statistics', error: e);
      return null;
    }
  }
}
