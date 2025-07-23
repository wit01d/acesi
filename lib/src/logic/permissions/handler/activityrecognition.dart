import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class ActivityRecognition {
  static const MethodChannel _channel = MethodChannel('com.example.company_app/activity_recognition');
  static final StreamController<List<ActivityData>> _activityController =
      StreamController<List<ActivityData>>.broadcast();
  static final StreamController<List<ActivityTransition>> _transitionController =
      StreamController<List<ActivityTransition>>.broadcast();
  static Stream<List<ActivityData>> get activityStream => _activityController.stream;
  static Stream<List<ActivityTransition>> get transitionStream => _transitionController.stream;
  static bool _isInitialized = false;
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onActivityDetected':
          final List<dynamic> activities = jsonDecode(call.arguments as String) as List<dynamic>;
          _activityController
              .add(activities.map((data) => ActivityData.fromJson(data as Map<String, dynamic>)).toList());
          break;
        case 'onActivityTransition':
          final List<dynamic> transitions = jsonDecode(call.arguments as String) as List<dynamic>;
          _transitionController
              .add(transitions.map((data) => ActivityTransition.fromJson(data as Map<String, dynamic>)).toList());
          break;
      }
    });
    _isInitialized = true;
  }

  static Future<bool> startActivityRecognition() async {
    try {
      await initialize();
      final bool result = await _channel.invokeMethod<bool>('startActivityRecognition') ?? false;
      return result;
    } on PlatformException catch (e) {
      throw ActivityRecognitionException('Failed to start activity recognition: ${e.message}');
    }
  }

  static Future<bool> stopActivityRecognition() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('stopActivityRecognition') ?? false;
      return result;
    } on PlatformException catch (e) {
      throw ActivityRecognitionException('Failed to stop activity recognition: ${e.message}');
    }
  }

  static Future<bool> startActivityTransitionUpdates() async {
    try {
      await initialize();
      final bool result = await _channel.invokeMethod<bool>('startActivityTransitionUpdates') ?? false;
      return result;
    } on PlatformException catch (e) {
      throw ActivityRecognitionException('Failed to start activity transition updates: ${e.message}');
    }
  }

  static Future<bool> stopActivityTransitionUpdates() async {
    try {
      final bool result = await _channel.invokeMethod<bool>('stopActivityTransitionUpdates') ?? false;
      return result;
    } on PlatformException catch (e) {
      throw ActivityRecognitionException('Failed to stop activity transition updates: ${e.message}');
    }
  }

  static void dispose() {
    _activityController.close();
    _transitionController.close();
    _isInitialized = false;
  }
}

class ActivityData {
  ActivityData({
    required this.type,
    required this.confidence,
  });
  factory ActivityData.fromJson(Map<String, dynamic> json) => ActivityData(
        type: json['type'] as String,
        confidence: json['confidence'] as int,
      );
  final String type;
  final int confidence;
  Map<String, dynamic> toJson() => {
        'type': type,
        'confidence': confidence,
      };
}

class ActivityTransition {
  ActivityTransition({
    required this.from,
    required this.to,
  });
  factory ActivityTransition.fromJson(Map<String, dynamic> json) => ActivityTransition(
        from: json['from'] as String,
        to: json['to'] as String,
      );
  final String from;
  final String to;
  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
      };
}

class ActivityRecognitionException implements Exception {
  ActivityRecognitionException(this.message);
  final String message;
  @override
  String toString() => 'ActivityRecognitionException: $message';
}
