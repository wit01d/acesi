import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceInfoHandler {
  static const platform = MethodChannel('com.example.company_app/deviceinfo');
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getPlatformDeviceInfo() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfoPlugin.webBrowserInfo;
      final browserData = _readWebBrowserInfo(webInfo);

      if (browserData['browserName'] == BrowserName.chrome.name) {
        browserData['isChrome'] = true;
        browserData['chromeVersion'] = browserData['appVersion']
            ?.toString()
            .split('Chrome/')
            .lastOrNull
            ?.split(' ')
            .firstOrNull;
      }

      return browserData;
    }

    if (Platform.isAndroid) {
      return _readAndroidBuildData(await _deviceInfoPlugin.androidInfo);
    } else if (Platform.isIOS) {
      return _readIosDeviceInfo(await _deviceInfoPlugin.iosInfo);
    } else if (Platform.isLinux) {
      return _readLinuxDeviceInfo(await _deviceInfoPlugin.linuxInfo);
    } else if (Platform.isMacOS) {
      return _readMacOsDeviceInfo(await _deviceInfoPlugin.macOsInfo);
    } else if (Platform.isWindows) {
      return _readWindowsDeviceInfo(await _deviceInfoPlugin.windowsInfo);
    }

    return <String, dynamic>{'Error': 'Unsupported platform'};
  }

  static Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) =>
      <String, dynamic>{
        'version.securityPatch': '${build.version.securityPatch}\n',
        'version.sdkInt': '${build.version.sdkInt}\n',
        'version.release': '${build.version.release}\n',
        'version.previewSdkInt': '${build.version.previewSdkInt}\n',
        'version.incremental': '${build.version.incremental}\n',
        'version.codename': '${build.version.codename}\n',
        'version.baseOS': '${build.version.baseOS}\n',
        'board': '${build.board}\n',
        'bootloader': '${build.bootloader}\n',
        'brand': '${build.brand}\n',
        'device': '${build.device}\n',
        'display': '${build.display}\n',
        'fingerprint': '${build.fingerprint}\n',
        'hardware': '${build.hardware}\n',
        'host': '${build.host}\n',
        'id': '${build.id}\n',
        'manufacturer': '${build.manufacturer}\n',
        'model': '${build.model}\n',
        'product': '${build.product}\n',
        'supported32BitAbis': '${build.supported32BitAbis}\n',
        'supported64BitAbis': '${build.supported64BitAbis}\n',
        'supportedAbis': '${build.supportedAbis}\n',
        'tags': '${build.tags}\n',
        'type': '${build.type}\n',
        'isPhysicalDevice': '${build.isPhysicalDevice}\n',
        'serialNumber': '${build.serialNumber}\n',
        'isLowRamDevice': '${build.isLowRamDevice}\n',
        'systemFeatures': '${build.systemFeatures}\n',
      };

  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) =>
      <String, dynamic>{
        'name': '${data.name}\n',
        'systemName': '${data.systemName}\n',
        'systemVersion': '${data.systemVersion}\n',
        'model': '${data.model}\n',
        'modelName': '${data.modelName}\n',
        'localizedModel': '${data.localizedModel}\n',
        'identifierForVendor': '${data.identifierForVendor}\n',
        'isPhysicalDevice': '${data.isPhysicalDevice}\n',
        'isiOSAppOnMac': '${data.isiOSAppOnMac}\n',
        'utsname.sysname:': '${data.utsname.sysname}\n',
        'utsname.nodename:': '${data.utsname.nodename}\n',
        'utsname.release:': '${data.utsname.release}\n',
        'utsname.version:': '${data.utsname.version}\n',
        'utsname.machine:': '${data.utsname.machine}\n',
      };

  static Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) =>
      <String, dynamic>{
        'name': '${data.name}\n',
        'version': '${data.version}\n',
        'id': '${data.id}\n',
        'idLike': '${data.idLike}\n',
        'versionCodename': '${data.versionCodename}\n',
        'versionId': '${data.versionId}\n',
        'prettyName': '${data.prettyName}\n',
        'buildId': '${data.buildId}\n',
        'variant': '${data.variant}\n',
        'variantId': '${data.variantId}\n',
        'machineId': '${data.machineId}\n',
      };

  static Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) =>
      <String, dynamic>{
        'browserName': '${data.browserName.name}\n',
        'appCodeName': '${data.appCodeName ?? 'unknown'}\n',
        'appName': '${data.appName ?? 'unknown'}\n',
        'appVersion': '${data.appVersion ?? 'unknown'}\n',
        'deviceMemory': '${data.deviceMemory?.toString() ?? 'unknown'}\n',
        'language': '${data.language ?? 'unknown'}\n',
        'languages': '${data.languages?.join(', ') ?? 'unknown'}\n',
        'platform': '${data.platform ?? 'unknown'}\n',
        'product': '${data.product ?? 'unknown'}\n',
        'productSub': '${data.productSub ?? 'unknown'}\n',
        'userAgent': '${data.userAgent ?? 'unknown'}\n',
        'vendor': '${data.vendor ?? 'unknown'}\n',
        'vendorSub': '${data.vendorSub ?? 'unknown'}\n',
        'hardwareConcurrency':
            '${data.hardwareConcurrency?.toString() ?? 'unknown'}\n',
        'maxTouchPoints': '${data.maxTouchPoints?.toString() ?? 'unknown'}\n',
        'isWeb': '${true}\n',
        'timestamp': '${DateTime.now().toUtc().toIso8601String()}\n',
      };

  static Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) =>
      <String, dynamic>{
        'computerName': '${data.computerName}\n',
        'hostName': '${data.hostName}\n',
        'arch': '${data.arch}\n',
        'model': '${data.model}\n',
        'modelName': '${data.modelName}\n',
        'kernelVersion': '${data.kernelVersion}\n',
        'majorVersion': '${data.majorVersion}\n',
        'minorVersion': '${data.minorVersion}\n',
        'patchVersion': '${data.patchVersion}\n',
        'osRelease': '${data.osRelease}\n',
        'activeCPUs': '${data.activeCPUs}\n',
        'memorySize': '${data.memorySize}\n',
        'cpuFrequency': '${data.cpuFrequency}\n',
        'systemGUID': '${data.systemGUID}\n',
      };

  static Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) =>
      <String, dynamic>{
        'numberOfCores': '${data.numberOfCores}\n',
        'computerName': '${data.computerName}\n',
        'systemMemoryInMegabytes': '${data.systemMemoryInMegabytes}\n',
        'userName': '${data.userName}\n',
        'majorVersion': '${data.majorVersion}\n',
        'minorVersion': '${data.minorVersion}\n',
        'buildNumber': '${data.buildNumber}\n',
        'platformId': '${data.platformId}\n',
        'csdVersion': '${data.csdVersion}\n',
        'servicePackMajor': '${data.servicePackMajor}\n',
        'servicePackMinor': '${data.servicePackMinor}\n',
        'suitMask': '${data.suitMask}\n',
        'productType': '${data.productType}\n',
        'reserved': '${data.reserved}\n',
        'buildLab': '${data.buildLab}\n',
        'buildLabEx': '${data.buildLabEx}\n',
        'digitalProductId': '${data.digitalProductId}\n',
        'displayVersion': '${data.displayVersion}\n',
        'editionId': '${data.editionId}\n',
        'installDate': '${data.installDate}\n',
        'productId': '${data.productId}\n',
        'productName': '${data.productName}\n',
        'registeredOwner': '${data.registeredOwner}\n',
        'releaseId': '${data.releaseId}\n',
        'deviceId': '${data.deviceId}\n',
      };
}
