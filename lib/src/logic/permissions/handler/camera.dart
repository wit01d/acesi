import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraHandler {
  static const platform = MethodChannel('com.example.company_app/camera');

  static Map<String, dynamic>? _cameraInfoCache;
  static DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);

  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  static Future<Map<String, dynamic>?> getCameraInfo({
    bool useCache = true,
  }) async {
    if (!await _checkCameraPermissions()) return null;

    try {
      if (useCache && _isCacheValid() && _cameraInfoCache != null) {
        return _cameraInfoCache;
      }

      final result = await platform.invokeMethod('getCameraInfo');
      if (result == null) return null;

      final cameraInfo = Map<String, dynamic>.from(result as Map);
      _cameraInfoCache = cameraInfo;
      _lastCacheUpdate = DateTime.now();

      return cameraInfo;
    } on PlatformException catch (e, stack) {
      Logger.error('Platform exception in getCameraInfo', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      Logger.error('Error in getCameraInfo', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<bool> checkCameraAvailability() async {
    try {
      final result = await platform.invokeMethod('checkCameraAvailability');
      return result as bool? ?? false;
    } catch (e, stack) {
      Logger.error('Error checking camera availability', error: e, stackTrace: stack);
      return false;
    }
  }

  static Future<bool> getCameraPermissionStatus() async {
    try {
      final result = await platform.invokeMethod('getCameraPermissionStatus');
      return result as bool? ?? false;
    } catch (e, stack) {
      Logger.error('Error getting camera permission status', error: e, stackTrace: stack);
      return false;
    }
  }

  static Future<bool> _checkCameraPermissions() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true;
  }

  static Map<String, dynamic> _safeCastMap(Map<Object?, Object?> input) => input.map((key, value) {
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

  static Future<String> getCameraDetails() async {
    final details = StringBuffer();

    try {
      final isAvailable = await checkCameraAvailability();
      details.writeln('Camera Hardware Available: $isAvailable\n');

      if (!isAvailable) return details.toString();

      final rawCameraInfo = await getCameraInfo(useCache: false);
      if (rawCameraInfo != null) {
        final cameraInfo = _safeCastMap(rawCameraInfo as Map<Object?, Object?>);

        details
          ..writeln('Number of Cameras: ${cameraInfo['numberOfCameras']}')
          ..writeln('Has Flash: ${cameraInfo['hasFlash']}')
          ..writeln('Has Front Camera: ${cameraInfo['hasFrontCamera']}')
          ..writeln('Has Back Camera: ${cameraInfo['hasBackCamera']}')
          ..writeln('Has External Camera: ${cameraInfo['hasExternalCamera']}\n');

        final cameras = cameraInfo['cameras'] as List<dynamic>;
        for (final camera in cameras) {
          final cameraData = camera is Map<Object?, Object?> ? _safeCastMap(camera) : camera as Map<String, dynamic>;

          final maxResolution = cameraData['maxResolution'] is Map<Object?, Object?>
              ? _safeCastMap(cameraData['maxResolution'] as Map<Object?, Object?>)
              : cameraData['maxResolution'] as Map<String, dynamic>;

          details
            ..writeln('Camera ID: ${cameraData['id']}')
            ..writeln('Lens Facing: ${cameraData['lensFacing']}')
            ..writeln('Flash Available: ${cameraData['flashAvailable']}')
            ..writeln('Max Resolution: ${maxResolution['width']}x${maxResolution['height']}')
            ..writeln('Supported Formats: ${(cameraData['supportedFormats'] as List<dynamic>).join(', ')}')
            ..writeln('Auto Focus Available: ${cameraData['autoFocusAvailable']}')
            ..writeln('Stabilization Supported: ${cameraData['stabilizationSupported']}')
            ..writeln('Minimum Focus Distance: ${cameraData['minimumFocusDistance']}')
            ..writeln('Focal Lengths: ${(cameraData['focalLengths'] as List<dynamic>).join(', ')}\n');
        }
      }
    } catch (e, stack) {
      Logger.error('Error getting camera details', error: e, stackTrace: stack);
      details.writeln('Error getting camera details: $e');
    }

    return details.toString();
  }
}
