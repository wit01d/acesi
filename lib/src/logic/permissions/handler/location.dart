import 'dart:async';
import 'dart:io';

import 'package:company_app/src/utils/logger.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geolocator/geolocator.dart' hide LocationSettings;

const String kLocationServicesDisabledMessage = 'Location services are disabled.';
const String kPermissionDeniedMessage = 'Permission denied.';
const String kPermissionDeniedForeverMessage = 'Permission denied forever.';
const String kPermissionGrantedMessage = 'Permission granted.';

enum LocationAccuracy { high, balanced, lowPower, passive }

enum PositionItemType {
  log,
  position,
}

class PositionItem {
  const PositionItem(this.type, this.displayValue);
  final PositionItemType type;
  final String displayValue;
}

class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.bearing,
  });
  factory LocationData.fromMap(Map<dynamic, dynamic> map) => LocationData(
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        accuracy: map['accuracy'] as double,
        speed: map['speed'] as double?,
        bearing: map['bearing'] as double?,
        timestamp: map['timestamp'] as int,
      );
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? bearing;
  final int timestamp;
  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
        'timestamp': timestamp,
      };
}

class LocationSettings {
  const LocationSettings({
    required this.isLocationEnabled,
    required this.isGpsPresent,
    required this.isNetworkLocationPresent,
    required this.bestProvider,
    required this.accuracy,
    required this.updateInterval,
  });
  final bool isLocationEnabled;
  final bool isGpsPresent;
  final bool isNetworkLocationPresent;
  final String bestProvider;
  final LocationAccuracy accuracy;
  final int updateInterval;
  @override
  String toString() => '''
Location Settings:
  - Location Enabled: $isLocationEnabled
  - GPS Present: $isGpsPresent
  - Network Location Present: $isNetworkLocationPresent
  - Best Provider: $bestProvider
  - Accuracy Mode: $accuracy
  - Update Interval: ${updateInterval}ms''';
}

class LocationHandler {
  static StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  static StreamSubscription<Position>? _positionSubscription;
  static bool _positionStreamStarted = false;
  static void Function(PositionItem)? onPositionUpdate;
  static const Duration _initialTimeout = Duration(seconds: 10);
  static const Duration _fallbackTimeout = Duration(seconds: 15);
  static const Duration _lastResortTimeout = Duration(seconds: 20);
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e, stack) {
      Logger.error(
        'Error checking location service status',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  static Future<bool> _checkGooglePlayServicesAvailability() async {
    if (!Platform.isAndroid) return true;
    try {
      await Geolocator.checkPermission();
      return true;
    } catch (e) {
      if (e.toString().contains('Google Play Services')) {
        Logger.error('Google Play Services not available', error: e);
        return false;
      }
      return true;
    }
  }

  static Future<Position?> getCurrentLocation() async {
    Position? position;
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationDisabledException(kLocationServicesDisabledMessage);
      }
      if (Platform.isAndroid && !await _checkGooglePlayServicesAvailability()) {
        Logger.warning('Google Play Services not available, location accuracy may be reduced');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException(kPermissionDeniedMessage);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(kPermissionDeniedForeverMessage);
      }
      TimeoutException? lastTimeoutError;
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.high,
            timeLimit: _initialTimeout,
          ),
        );
      } on TimeoutException catch (e) {
        lastTimeoutError = e;
        Logger.warning('Initial location request timed out, trying fallback...');
      }
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.medium,
            timeLimit: _fallbackTimeout,
          ),
        );
      } on TimeoutException catch (e) {
        lastTimeoutError = e;
        Logger.warning('Fallback location request timed out, trying last resort...');
      }
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.low,
            timeLimit: _lastResortTimeout,
          ),
        );
      } on TimeoutException catch (e) {
        lastTimeoutError = e;
        Logger.error('All location requests timed out');
      }
      position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        Logger.info('Returning last known position as fallback');
        return position;
      }
      throw LocationServiceException('Failed to get location after multiple attempts: ${lastTimeoutError.message}');
    } on LocationServiceException catch (e, stack) {
      Logger.error('Location service error', error: e, stackTrace: stack);
      rethrow;
    } on LocationPermissionException catch (e, stack) {
      Logger.error('Location permission error', error: e, stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      Logger.error(
        'Error getting current location',
        error: e,
        stackTrace: stack,
      );
      throw LocationServiceException('Failed to get location: $e');
    }
  }

  static Future<Position?> getLastKnownPosition() async {
    try {
      return Geolocator.getLastKnownPosition();
    } catch (e) {
      throw LocationUnavailableException('Failed to get last known location: $e');
    }
  }

  static Stream<Position> getLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int interval = 1000,
  }) =>
      Geolocator.getPositionStream(
        locationSettings: geolocator.LocationSettings(
          accuracy: _mapGeolocatorAccuracy(accuracy),
          distanceFilter: interval,
        ),
      );
  static Future<bool> handlePermission({
    void Function(PositionItem)? onUpdate,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onUpdate?.call(const PositionItem(
        PositionItemType.log,
        kLocationServicesDisabledMessage,
      ));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onUpdate?.call(const PositionItem(
          PositionItemType.log,
          kPermissionDeniedMessage,
        ));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      onUpdate?.call(const PositionItem(
        PositionItemType.log,
        kPermissionDeniedForeverMessage,
      ));
      return false;
    }
    onUpdate?.call(const PositionItem(
      PositionItemType.log,
      kPermissionGrantedMessage,
    ));
    return true;
  }

  static void startLocationUpdates({
    required void Function(PositionItem) onUpdate,
    required void Function(String) onError,
  }) {
    if (_positionSubscription == null) {
      final positionStream = getLocationUpdates();
      _positionSubscription = positionStream.handleError((error) {
        onError(error.toString());
        _positionSubscription?.cancel();
        _positionSubscription = null;
      }).listen((position) => onUpdate(PositionItem(
            PositionItemType.position,
            position.toString(),
          )));
      _positionSubscription?.pause();
    }
    if (_positionSubscription?.isPaused ?? false) {
      _positionSubscription?.resume();
      _positionStreamStarted = true;
      onUpdate(const PositionItem(
        PositionItemType.log,
        'Listening for position updates resumed',
      ));
    } else {
      _positionSubscription?.pause();
      _positionStreamStarted = false;
      onUpdate(const PositionItem(
        PositionItemType.log,
        'Listening for position updates paused',
      ));
    }
  }

  static void monitorServiceStatus({
    required void Function(PositionItem) onUpdate,
    required void Function(String) onError,
  }) {
    if (_serviceStatusSubscription == null) {
      final serviceStatusStream = Geolocator.getServiceStatusStream();
      _serviceStatusSubscription = serviceStatusStream.handleError((error) {
        onError(error.toString());
        _serviceStatusSubscription?.cancel();
        _serviceStatusSubscription = null;
      }).listen((serviceStatus) {
        final isEnabled = serviceStatus == ServiceStatus.enabled;
        onUpdate(PositionItem(
          PositionItemType.log,
          'Location service has been ${isEnabled ? 'enabled' : 'disabled'}',
        ));
        if (!isEnabled && _positionSubscription != null) {
          _positionSubscription?.cancel();
          _positionSubscription = null;
          onUpdate(const PositionItem(
            PositionItemType.log,
            'Position Stream has been canceled',
          ));
        } else if (isEnabled && _positionStreamStarted) {
          startLocationUpdates(onUpdate: onUpdate, onError: onError);
        }
      });
    }
  }

  static Future<LocationAccuracyStatus> getLocationAccuracy() async {
    final status = await Geolocator.getLocationAccuracy();
    return switch (status) {
      geolocator.LocationAccuracyStatus.reduced => LocationAccuracyStatus.reduced,
      geolocator.LocationAccuracyStatus.precise => LocationAccuracyStatus.precise,
      _ => LocationAccuracyStatus.unknown,
    };
  }

  static Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async {
    final status = await Geolocator.requestTemporaryFullAccuracy(purposeKey: purposeKey);
    return switch (status) {
      geolocator.LocationAccuracyStatus.reduced => LocationAccuracyStatus.reduced,
      geolocator.LocationAccuracyStatus.precise => LocationAccuracyStatus.precise,
      _ => LocationAccuracyStatus.unknown,
    };
  }

  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();
  static bool isListening() => !(_positionSubscription == null || _positionSubscription!.isPaused);
  static void dispose() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionStreamStarted = false;
    onPositionUpdate = null;
  }

  static geolocator.LocationAccuracy _mapGeolocatorAccuracy(LocationAccuracy accuracy) => switch (accuracy) {
        LocationAccuracy.high => geolocator.LocationAccuracy.high,
        LocationAccuracy.balanced => geolocator.LocationAccuracy.medium,
        LocationAccuracy.lowPower => geolocator.LocationAccuracy.low,
        LocationAccuracy.passive => geolocator.LocationAccuracy.lowest,
      };
}

class LocationPermissionException implements Exception {
  LocationPermissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationDisabledException implements Exception {
  LocationDisabledException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationUnavailableException implements Exception {
  LocationUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationServiceException implements Exception {
  LocationServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum LocationAccuracyStatus {
  reduced,
  precise,
  unknown,
}

extension LocationDataExtension on LocationData {
  String toDetailedString() => '''
Location Data:
  - Latitude: $latitude
  - Longitude: $longitude
  - Accuracy: ${accuracy.toStringAsFixed(2)} meters
  - Speed: ${speed?.toStringAsFixed(2) ?? 'N/A'} m/s
  - Bearing: ${bearing?.toStringAsFixed(2) ?? 'N/A'} degrees
  - Timestamp: ${DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal()}''';
}
