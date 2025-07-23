import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

const sensitiveMobilePermissions = [
  Permission.ignoreBatteryOptimizations,
  Permission.locationAlways,
  Permission.locationWhenInUse,
  Permission.manageExternalStorage,
  Permission.mediaLibrary,
  Permission.photosAddOnly,
  Permission.storage,
  Permission.systemAlertWindow,
];

Map<Permission, String> getSensitivePermissionMessages(AppLocalizations l10n) =>
    {
    Permission.ignoreBatteryOptimizations:
        l10n.ignoreBatteryOptimizationsPermissionDeniedMessage,
    Permission.locationAlways: l10n.locationAlwaysPermissionDeniedMessage,
    Permission.locationWhenInUse: l10n.locationPermissionDeniedMessage,
    Permission.manageExternalStorage: l10n.mediaLibraryPermissionDeniedMessage,
    Permission.mediaLibrary: l10n.mediaLibraryPermissionDeniedMessage,
    Permission.photosAddOnly: l10n.photosPermissionDeniedMessage,
    Permission.storage: l10n.mediaLibraryPermissionDeniedMessage,
    Permission.systemAlertWindow: l10n.systemAlertWindowPermissionDeniedMessage,
    };
