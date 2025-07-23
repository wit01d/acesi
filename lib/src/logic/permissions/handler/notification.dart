import 'dart:convert';

import 'package:flutter/services.dart';

class NotificationHandler {
  static const MethodChannel _channel = MethodChannel('com.example.company_app/notifications');
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final String result = await _channel.invokeMethod('getNotificationSettings') as String;
      return json.decode(result) as Map<String, dynamic>;
    } on PlatformException catch (e) {
      throw Exception('Failed to get notification settings: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> getActiveNotifications() async {
    try {
      final String result = await _channel.invokeMethod('getActiveNotifications') as String;
      return json.decode(result) as Map<String, dynamic>;
    } on PlatformException catch (e) {
      throw Exception('Failed to get active notifications: ${e.message}');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificationChannels() async {
    try {
      final String result = await _channel.invokeMethod('getNotificationChannels') as String;
      final Map<String, dynamic> response = json.decode(result) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(response['channels'] as List);
    } on PlatformException catch (e) {
      throw Exception('Failed to get notification channels: ${e.message}');
    }
  }
}
