import 'dart:convert';
import 'package:flutter/services.dart';

class SensorHandler {
  static const MethodChannel _channel =
      MethodChannel('com.example.company_app/sensors');

  static Future<List<Map<String, dynamic>>> getSensorList() async {
    try {
      final String result =
          await _channel.invokeMethod('getSensorList') as String;
      final List<dynamic> sensorList = json.decode(result) as List<dynamic>;
      return sensorList.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      throw Exception('Failed to get sensor list: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> getSensorDetails(int sensorType) async {
    try {
      final String result = await _channel.invokeMethod(
        'getSensorDetails',
        {'sensorType': sensorType},
      ) as String;
      return json.decode(result) as Map<String, dynamic>;
    } on PlatformException catch (e) {
      throw Exception('Failed to get sensor details: ${e.message}');
    }
  }

  static String getSensorTypeName(int type) {
    switch (type) {
      case 1:
        return 'Accelerometer';
      case 2:
        return 'Magnetic Field';
      case 3:
        return 'Orientation';
      case 4:
        return 'Gyroscope';
      case 5:
        return 'Light';
      case 6:
        return 'Pressure';
      case 8:
        return 'Proximity';
      case 9:
        return 'Gravity';
      case 10:
        return 'Linear Acceleration';
      case 11:
        return 'Rotation Vector';
      case 12:
        return 'Relative Humidity';
      case 13:
        return 'Ambient Temperature';
      default:
        return 'Unknown';
    }
  }
}
