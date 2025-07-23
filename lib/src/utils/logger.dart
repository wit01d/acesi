import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel {
  verbose(0),
  debug(1),
  info(2),
  warning(3),
  error(4);

  const LogLevel(this.level);
  final int level;
}

class Logger {
  static LogLevel _minLevel = LogLevel.info;
  static bool enableVerbose = false;
  static const int _maxQueueSize = 100;
  static final List<String> _logQueue = [];
  static const _rateLimitDuration = Duration(seconds: 1);
  static const _maxLogsPerSecond = 10;
  static int _logCount = 0;
  static DateTime _lastLogTime = DateTime.now();
  static const bool _isWeb = kIsWeb;
  static const String _resetColor = '\x1B[0m';
  static const String _errorColor = '\x1B[31m';
  static const String _warningColor = '\x1B[33m';
  static const String _successColor = '\x1B[32m';
  static const String _infoColor = '\x1B[36m';
  static void _platformPrint(
    String message, {
    String color = '',
    int? wrapWidth,
  }) {
    if (!kDebugMode) {
      debugPrint(message, wrapWidth: wrapWidth);
      return;
    }
    final String formattedMessage = _isWeb ? message : '$color$message$_resetColor';
    debugPrint(
      formattedMessage,
      wrapWidth: wrapWidth ?? 120,
    );
  }

  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  static set logLevel(LogLevel level) {
    _minLevel = level;
  }

  static void success(String message) {
    if (_minLevel.level > LogLevel.info.level) return;
    final timestamp = _getTimestamp();
    if (kDebugMode) {
      _platformPrint('[$timestamp][SUCCESS] $message', color: _successColor);
    }
    developer.log('[$timestamp] $message', name: '***SUCCESS***');
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (_minLevel.level > LogLevel.error.level) return;
    final timestamp = _getTimestamp();
    if (kDebugMode) {
      _platformPrint('[$timestamp][ERROR] $message', color: _errorColor);
      if (error != null) {
        _platformPrint('Error details: $error', color: _errorColor);
      }
      if (stackTrace != null) {
        _platformPrint('Stack trace:\n$stackTrace', color: _errorColor);
      }
      if (extra != null) {
        _platformPrint('Extra context: $extra', color: _errorColor);
      }
    }
    if (_isWeb) {
      debugPrint('[$timestamp][ERROR] $message');
    } else {
      developer.log(
        '[$timestamp] $message',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
        name: '***Error***',
      );
    }
  }

  static void verbose(String message, {Object? details}) {
    if (_minLevel.level > LogLevel.verbose.level) return;
    final timestamp = _getTimestamp();
    if (kDebugMode && enableVerbose) {
      _queueLog('[$timestamp][VERBOSE] $message');
      if (details != null) {
        _queueLog('[$timestamp] Details: $details');
      }
    }
    developer.log(
      '[$timestamp] $message',
      error: details,
      level: 500,
      name: '***VERBOSE***',
    );
  }

  static void info(String message) {
    if (_minLevel.level > LogLevel.info.level) return;
    final timestamp = _getTimestamp();
    if (kDebugMode) {
      _platformPrint('[$timestamp][INFO] $message', color: _infoColor);
      if (enableVerbose) {
        _platformPrint('Timestamp: ${DateTime.now()}', color: _infoColor);
      }
    }
    developer.log('[$timestamp] $message', name: '***INFO***');
  }

  static void warning(String message) {
    if (_minLevel.level > LogLevel.warning.level) return;
    final timestamp = _getTimestamp();
    if (kDebugMode) {
      _platformPrint('[$timestamp][WARNING] $message', color: _warningColor);
    }
    developer.log('[$timestamp] $message', level: 500, name: '***WARNING***');
  }

  static bool _shouldRateLimit() {
    final now = DateTime.now();
    if (now.difference(_lastLogTime) >= _rateLimitDuration) {
      _logCount = 0;
      _lastLogTime = now;
      return false;
    }
    _logCount++;
    return _logCount > _maxLogsPerSecond;
  }

  static void _queueLog(String message) {
    if (_shouldRateLimit()) {
      if (_logQueue.length >= _maxQueueSize) {
        _logQueue.removeAt(0);
      }
      _logQueue.add(message);
      return;
    }
    while (_logQueue.isNotEmpty && !_shouldRateLimit()) {
      final queuedMessage = _logQueue.removeAt(0);
      debugPrint(queuedMessage);
    }
    if (!_shouldRateLimit()) {
      debugPrint(message);
    } else {
      _logQueue.add(message);
    }
  }
}
