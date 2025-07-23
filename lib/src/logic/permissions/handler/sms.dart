import 'dart:async';

import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsHandler {
  static const platform = MethodChannel('com.example.company_app/sms');
  static final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  static DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  static void clearCache() {
    _messageCache.clear();
    _lastCacheUpdate = null;
  }

  static Future<bool> _checkSmsPermissions() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      final result = await Permission.sms.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<Map<String, int>?> getMessageCounts() async {
    if (!await _checkSmsPermissions()) {
      return null;
    }
    try {
      final result = await platform.invokeMethod('getMessageCounts');
      if (result == null) return null;
      final Map<dynamic, dynamic> rawCounts = result as Map<dynamic, dynamic>;
      return {
        'inbox': rawCounts['inbox'] as int? ?? 0,
        'sent': rawCounts['sent'] as int? ?? 0,
      };
    } on PlatformException catch (e, stack) {
      Logger.error(
        'Platform exception in getMessageCounts',
        error: e,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      Logger.error(
        'Error getting message counts',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _getPaginatedMessages(
    String type,
    int page,
    int pageSize,
  ) async {
    if (!await _checkSmsPermissions()) return null;
    final cacheKey = '${type}_${page}_$pageSize';
    if (_isCacheValid() && _messageCache.containsKey(cacheKey)) {
      return _messageCache[cacheKey];
    }
    try {
      final result = await platform.invokeMethod('getPaginatedMessages', {
        'type': type,
        'page': page,
        'pageSize': pageSize,
      });
      if (result == null) return null;
      final Map<Object?, Object?> rawResult = result as Map<Object?, Object?>;
      final List<Object?> messages = (rawResult['messages'] as List<Object?>?) ?? [];
      final parsedMessages = messages.map<Map<String, dynamic>>((message) {
        final Map<Object?, Object?> msg = message! as Map<Object?, Object?>;
        final map = _parseMessage(msg);
        map['messageType'] = type;
        return map;
      }).toList();
      _messageCache[cacheKey] = parsedMessages;
      _lastCacheUpdate = DateTime.now();
      return parsedMessages;
    } catch (e, stack) {
      Logger.error(
        'Error processing messages',
        error: e,
        stackTrace: stack,
        extra: {'type': type, 'page': page, 'pageSize': pageSize},
      );
      return null;
    }
  }

  static Map<String, dynamic> _parseMessage(Map<Object?, Object?> msg) {
    int? parseNumber(Object? value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    final rawDate = parseNumber(msg['date']) ?? 0;
    final id = parseNumber(msg['id']) ?? -1;
    final type = parseNumber(msg['type']) ?? 0;
    return {
      'id': id,
      'address': msg['address']?.toString() ?? 'Unknown',
      'body': msg['body']?.toString() ?? '',
      'date': rawDate,
      'type': type,
      'timestamp': rawDate > 0
          ? DateTime.fromMillisecondsSinceEpoch(rawDate).toIso8601String()
          : DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>?> getInboxMessages({
    int page = 0,
    int pageSize = 50,
  }) async =>
      _getPaginatedMessages('inbox', page, pageSize);
  static Future<List<Map<String, dynamic>>?> getSentMessages({
    int page = 0,
    int pageSize = 50,
  }) async =>
      _getPaginatedMessages('sent', page, pageSize);
}
