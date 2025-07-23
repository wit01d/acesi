import 'package:flutter/services.dart';

class NetworkInfo {
  static const MethodChannel _channel =
      MethodChannel('com.example.company_app/networkinfo');

  static Future<String?> getNumber() async {
    try {
      final String? phoneNumber = await _channel.invokeMethod('getPhoneNumber');
      return phoneNumber?.isNotEmpty ?? false ? phoneNumber : null;
    } on PlatformException catch (e) {
      return '${e.code}: ${e.message}';
    } catch (e) {
      return 'UNKNOWN_ERROR: ${e.toString()}';
    }
  }

  static Future<Network> getNetworkInfo() async {
    try {
      final dynamic result = await _channel.invokeMethod('getNetworkInfo');

      if (result == null) return Network.error('NULL_ERROR: No data received');

      final Map<dynamic, dynamic> resultMap = result as Map<dynamic, dynamic>;
      final info = Map<String, dynamic>.from(resultMap.map((key, value) =>
          MapEntry(key.toString(),
              value is Map ? Map<String, dynamic>.from(value) : value)));

      return Network.fromMap(info);
    } on PlatformException catch (e) {
      return Network.error('${e.code}: ${e.message}');
    } catch (e) {
      return Network.error('UNKNOWN_ERROR: ${e.toString()}');
    }
  }
}

enum NetworkType {
  wifi,
  cellular2G,
  cellular3G,
  cellular4G,
  cellular5G,
  ethernet,
  disconnected,
  permissionDenied,
  unknown
}

class Network {
  const Network({
    required this.callState,
    required this.simState,
    required this.networkOperatorName,
    required this.deviceSoftwareVersion,
    required this.networkCountryIso,
    required this.simCountryIso,
    required this.networkType,
    this.error,
  });

  factory Network.fromMap(Map<String, dynamic> map) => Network(
        callState: _parseCallState(map['callState']),
        simState: _parseSimState(map['simState']),
        networkOperatorName:
            map['networkOperatorName']?.toString() ?? 'UNKNOWN',
        deviceSoftwareVersion:
            map['deviceSoftwareVersion']?.toString() ?? 'UNKNOWN',
        networkCountryIso: map['networkCountryIso']?.toString() ?? '',
        simCountryIso: map['simCountryIso']?.toString() ?? '',
        networkType: _parseNetworkType(map['networkType']?.toString()),
      );

  factory Network.error(String errorMessage) => Network(
        callState: 'UNKNOWN',
        simState: 'UNKNOWN',
        networkOperatorName: 'UNKNOWN',
        deviceSoftwareVersion: 'UNKNOWN',
        networkCountryIso: '',
        simCountryIso: '',
        networkType: NetworkType.unknown,
        error: errorMessage,
      );
  final String callState;
  final String simState;
  final String networkOperatorName;
  final String deviceSoftwareVersion;
  final String networkCountryIso;
  final String simCountryIso;
  final NetworkType networkType;
  final String? error;

  static NetworkType _parseNetworkType(String? type) {
    switch (type?.toLowerCase()) {
      case 'wifi':
        return NetworkType.wifi;
      case '2g':
        return NetworkType.cellular2G;
      case '3g':
        return NetworkType.cellular3G;
      case '4g':
        return NetworkType.cellular4G;
      case '5g':
        return NetworkType.cellular5G;
      case 'ethernet':
        return NetworkType.ethernet;
      case 'disconnected':
        return NetworkType.disconnected;
      case 'permission_denied':
        return NetworkType.permissionDenied;
      default:
        return NetworkType.unknown;
    }
  }

  static String _parseCallState(dynamic state) {
    final String stateStr = state?.toString() ?? 'UNKNOWN';
    return stateStr == '' ? 'UNKNOWN' : stateStr;
  }

  static String _parseSimState(dynamic state) {
    final String stateStr = state?.toString() ?? 'UNKNOWN';
    return stateStr == '' ? 'UNKNOWN' : stateStr;
  }

  bool get hasError => error != null;

  @override
  String toString() => 'Network('
      'callState: $callState, '
      'simState: $simState, '
      'operator: $networkOperatorName, '
      'softwareVersion: $deviceSoftwareVersion, '
      'countryISO: $networkCountryIso, '
      'simCountryISO: $simCountryIso, '
      'type: ${networkType.name}, '
      'error: $error)';
}
