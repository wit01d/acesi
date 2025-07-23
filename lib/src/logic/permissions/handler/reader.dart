import 'dart:async';

import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';

class ReaderHandler {
  static const MethodChannel _channel = MethodChannel('com.example.company_app/accessibility');

  static final StreamController<Map<String, dynamic>> _accessibilityController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get accessibilityStream => _accessibilityController.stream;

  static void dispose() {
    _accessibilityController.close();
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
      return result;
    } catch (e, stack) {
      Logger.error('Failed to check accessibility service status', error: e, stackTrace: stack);
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e, stack) {
      Logger.error('Failed to open accessibility settings', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<void> startMonitoring() async {
    try {
      await _channel.invokeMethod('startMonitoring');
    } catch (e, stack) {
      Logger.error('Failed to start accessibility monitoring', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<String?> getLatestViewHierarchy() async {
    try {
      final String? hierarchy = await _channel.invokeMethod<String?>('getLatestViewHierarchy');
      if (hierarchy != null) {
        Logger.info('View hierarchy updated');
      }
      return hierarchy;
    } catch (e, stack) {
      Logger.error('Failed to get view hierarchy', error: e, stackTrace: stack);
      return 'Error getting view hierarchy: $e';
    }
  }

  static Future<String> getAccessibilityLogs() async {
    try {
      final String logs = await _channel.invokeMethod<String>('getAccessibilityLogs') ?? '';
      return logs;
    } catch (e, stack) {
      Logger.error('Failed to get accessibility logs', error: e, stackTrace: stack);
      return 'Error getting accessibility logs: $e';
    }
  }
}
