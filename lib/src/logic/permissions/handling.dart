import 'package:company_app/src/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

const _serverLogUrl = 'https://your-server.com/api/logs';
const _webPermissions = [
  Permission.camera,
  Permission.microphone,
  Permission.location,
  Permission.notification,
];
const _iosPermissions = [
  Permission.camera,
  Permission.microphone,
  Permission.location,
  Permission.notification,
  Permission.photos,
  Permission.contacts,
  Permission.calendarFullAccess,
  Permission.reminders,
  Permission.bluetooth,
  Permission.bluetoothScan,
  Permission.sensors,
];
const _androidPermissions = [
  Permission.activityRecognition,
  Permission.audio,
  Permission.bluetooth,
  Permission.bluetoothAdvertise,
  Permission.bluetoothConnect,
  Permission.bluetoothScan,
  Permission.calendarFullAccess,
  Permission.camera,
  Permission.contacts,
  Permission.location,
  Permission.microphone,
  Permission.notification,
  Permission.phone,
  Permission.photos,
  Permission.reminders,
  Permission.sensors,
  Permission.sms,
  Permission.videos,
];
const _linuxPermissions = [
  Permission.storage,
  Permission.notification,
  Permission.microphone,
  Permission.camera,
  Permission.bluetooth,
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
];
const _windowsPermissions = [
  Permission.storage,
  Permission.location,
  Permission.camera,
  Permission.microphone,
  Permission.bluetooth,
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
  Permission.notification,
];

class ErrorDialogHelper {
  ErrorDialogHelper(this.context);
  final BuildContext context;
  void showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.error ?? 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }
}

class PermissionHandler extends ChangeNotifier {
  PermissionHandler({required this.onComplete, required this.context});
  final VoidCallback onComplete;
  final BuildContext context;
  bool _isLoading = false;
  bool _isCanceled = false;
  final _dio = Dio();
  bool get isLoading => _isLoading;
  List<Permission> get _platformSpecificPermissions {
    if (kIsWeb) return _webPermissions;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _iosPermissions;
      case TargetPlatform.android:
        return _androidPermissions;
      case TargetPlatform.linux:
        return _linuxPermissions;
      case TargetPlatform.windows:
        return _windowsPermissions;
      default:
        return const [];
    }
  }

  Future<void> handlePermissionsRequest() async {
    if (_isLoading) return;
    _isLoading = true;
    _isCanceled = false;
    notifyListeners();
    try {
      final granted = await _requestPlatformSpecificPermissions();
      if (granted) {
        try {
          Logger.info('Permissions granted successfully');
          final permissionStatuses = await Future.wait(
            _platformSpecificPermissions.map((p) async => {
                  'name': p.value,
                  'status': (await p.status).name,
                }),
          );
          await _dio.post(_serverLogUrl, data: {
            'timestamp': DateTime.now().toIso8601String(),
            'platform': defaultTargetPlatform.name,
            'permissions': permissionStatuses,
          });
        } catch (e) {
          Logger.error('Failed to log permissions', error: e);
        }
      }
      if (!_isCanceled && granted) {
        onComplete();
      }
    } catch (e, stack) {
      Logger.error('Permission request failed', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _requestPlatformSpecificPermissions() async {
    final permissions = _platformSpecificPermissions;
    if (permissions.isEmpty) {
      return true;
    }
    for (final permission in permissions) {
      if (_isCanceled) return false;
      if (kIsWeb && !_webPermissions.contains(permission)) continue;
      final granted = await _requestSinglePermission(permission);
      if (!granted) return false;
    }
    return true;
  }

  Future<bool> _requestSinglePermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    final shouldOpenSettings = await _showPermissionDialog(permission);
    if (!shouldOpenSettings) return false;
    if (await openAppSettings()) {
      await Future.delayed(const Duration(seconds: 1));
      final newStatus = await permission.status;
      return newStatus.isGranted || newStatus.isLimited;
    }
    return false;
  }

  Future<bool> requestSinglePermission(Permission permission) async {
    _isLoading = true;
    notifyListeners();
    final granted = await _requestSinglePermission(permission);
    _isLoading = false;
    notifyListeners();
    if (granted) onComplete();
    return granted;
  }

  Future<bool> _showPermissionDialog(Permission permission) async {
    if (_isCanceled) return false;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n?.permissionsRequired ?? 'Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (l10n != null) Text(_getPermissionMessage(permission, l10n)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isCanceled = true;
              _isLoading = false;
              Navigator.of(context).pop(false);
            },
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n?.openSettings ?? 'Open Settings'),
          ),
        ],
      ),
    );
    if (_isCanceled) {
      notifyListeners();
      return false;
    }
    return result ?? false;
  }

  String _getPermissionMessage(Permission permission, AppLocalizations l10n) {
    final messages = {
      Permission.activityRecognition: l10n.activity_recognitionPermissionDeniedMessage,
      Permission.audio: l10n.audioPermissionDeniedMessage,
      Permission.bluetooth: l10n.bluetoothPermissionDeniedMessage,
      Permission.bluetoothAdvertise: l10n.bluetoothAdvertisePermissionDeniedMessage,
      Permission.bluetoothConnect: l10n.bluetoothConnectPermissionDeniedMessage,
      Permission.bluetoothScan: l10n.bluetoothScanPermissionDeniedMessage,
      Permission.calendarFullAccess: l10n.calendarPermissionDeniedMessage,
      Permission.camera: l10n.cameraPermissionDeniedMessage,
      Permission.contacts: l10n.contactsPermissionDeniedMessage,
      Permission.location: l10n.locationPermissionDeniedMessage,
      Permission.microphone: l10n.microphonePermissionDeniedMessage,
      Permission.notification: l10n.notificationPermissionDeniedMessage,
      Permission.phone: l10n.phonePermissionDeniedMessage,
      Permission.photos: l10n.photosPermissionDeniedMessage,
      Permission.reminders: l10n.remindersPermissionDeniedMessage,
      Permission.sensors: l10n.sensorsPermissionDeniedMessage,
      Permission.sms: l10n.smsPermissionDeniedMessage,
      Permission.videos: l10n.videosPermissionDeniedMessage,
    };
    return messages[permission]!;
  }

  static Future<bool> areAllPermissionsGranted() async {
    final permissions = kIsWeb
        ? _webPermissions
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => _iosPermissions,
            TargetPlatform.android => _androidPermissions,
            TargetPlatform.linux => _linuxPermissions,
            TargetPlatform.windows => _windowsPermissions,
            _ => const <Permission>[],
          };
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }
    return true;
  }
}
