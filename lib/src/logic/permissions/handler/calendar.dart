import 'dart:async';

import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CalendarHandler {
  static const platform = MethodChannel('com.example.company_app/calendar');
  static final Map<String, Map<String, dynamic>> _calendarCache = {};
  static DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  static void clearCache() {
    _calendarCache.clear();
    _lastCacheUpdate = null;
  }

  static Future<bool> _checkCalendarPermissions() async {
    final status = await Permission.calendarFullAccess.status;
    if (!status.isGranted) {
      final result = await Permission.calendarFullAccess.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>?> getCalendars({
    bool useCache = true,
  }) async {
    if (!await _checkCalendarPermissions()) return null;
    try {
      if (useCache && _isCacheValid() && _calendarCache.isNotEmpty) {
        return _calendarCache.values.toList();
      }
      final dynamic result = await platform.invokeMethod('getCalendars');
      if (result == null) return null;
      final calendars =
          List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
      _calendarCache.clear();
      for (final calendar in calendars) {
        _calendarCache[calendar['id'].toString()] = calendar;
      }
      _lastCacheUpdate = DateTime.now();
      return calendars;
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getCalendars', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getCalendars', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
  }) async {
    if (!await _checkCalendarPermissions()) return null;
    try {
      final params = {
        'startDate': startDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'endDate':
            endDate?.millisecondsSinceEpoch ?? DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        if (calendarId != null) 'calendarId': calendarId,
      };
      final dynamic result = await platform.invokeMethod('getEvents', params);
      if (result == null) return null;
      return List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getEvents', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getEvents', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> searchEvents(String query) async {
    if (!await _checkCalendarPermissions()) return null;
    try {
      final dynamic result = await platform.invokeMethod('searchEvents', {'query': query});
      if (result == null) return null;
      return List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in searchEvents', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in searchEvents', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCalendarStats() async {
    if (!await _checkCalendarPermissions()) return null;
    try {
      final dynamic result = await platform.invokeMethod('getCalendarStats');
      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getCalendarStats', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getCalendarStats', error: e, stackTrace: stack);
      return null;
    }
  }
}
