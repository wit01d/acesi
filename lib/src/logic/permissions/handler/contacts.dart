import 'dart:async';

import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsHandler {
  static const platform = MethodChannel('com.example.company_app/contacts');
  static final Map<String, Map<String, dynamic>> _contactCache = {};
  static DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  static void clearCache() {
    _contactCache.clear();
    _lastCacheUpdate = null;
  }

  static Future<bool> _checkContactsPermissions() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final result = await Permission.contacts.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>?> getContacts({bool useCache = true}) async {
    if (!await _checkContactsPermissions()) return null;
    try {
      if (useCache && _isCacheValid() && _contactCache.isNotEmpty) {
        return _contactCache.values.toList();
      }
      final dynamic result = await platform.invokeMethod('getContacts');
      if (result == null) return null;
      final contacts =
          List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
      _contactCache.clear();
      for (final contact in contacts) {
        _contactCache[contact['id'] as String] = contact;
      }
      _lastCacheUpdate = DateTime.now();
      return contacts;
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getContacts', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getContacts', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getContactDetails(
    String contactId, {
    bool useCache = true,
  }) async {
    if (!await _checkContactsPermissions()) return null;
    try {
      if (useCache && _isCacheValid() && _contactCache.containsKey(contactId)) {
        return _contactCache[contactId];
      }
      final dynamic result = await platform.invokeMethod('getContactDetails', {
        'contactId': contactId,
      });
      if (result == null) return null;
      final contact = Map<String, dynamic>.from(result as Map);
      _contactCache[contactId] = contact;
      _lastCacheUpdate = DateTime.now();
      return contact;
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getContactDetails', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getContactDetails', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getContactGroups() async {
    if (!await _checkContactsPermissions()) return null;
    try {
      final dynamic result = await platform.invokeMethod('getContactGroups');
      if (result == null) return null;
      return List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getContactGroups', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getContactGroups', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> searchContacts(String query) async {
    if (!await _checkContactsPermissions()) return null;
    try {
      final dynamic result = await platform.invokeMethod('searchContacts', {
        'query': query,
      });
      return List<Map<String, dynamic>>.from((result as List).map((item) => Map<String, dynamic>.from(item as Map)));
    } on PlatformException {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getContactStats() async {
    if (!await _checkContactsPermissions()) return null;
    try {
      final dynamic result = await platform.invokeMethod('getContactStats');
      if (result == null) return null;
      return Map<String, dynamic>.from((result as Map).map((key, value) => MapEntry(
          key.toString(),
          value is Map
              ? Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)))
              : value is List
                  ? List.from(value
                      .map((e) => e is Map ? Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))) : e))
                  : value)));
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getContactStats', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getContactStats', error: e, stackTrace: stack);
      return null;
    }
  }
}
