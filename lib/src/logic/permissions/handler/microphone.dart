import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class MicrophoneHandler {
  static const platform = MethodChannel('com.example.company_app/microphone');
  static Future<bool> _checkMicrophonePermissions() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<MicrophoneInfo?> getMicrophoneInfo() async {
    if (!await _checkMicrophonePermissions()) return null;
    try {
      final result = await platform.invokeMethod('getMicrophoneInfo');
      if (result is Map) {
        return MicrophoneInfo.fromJson(Map<String, dynamic>.from(result));
      }
      throw const MicrophoneException(
        code: 'invalid_response',
        message: 'Invalid response format from platform',
      );
    } on PlatformException catch (e) {
      throw MicrophoneException(
        code: e.code,
        message: e.message ?? 'Failed to get microphone information',
      );
    }
  }
}

class MicrophoneException implements Exception {
  const MicrophoneException({
    required this.code,
    required this.message,
  });
  final String code;
  final String message;
  @override
  String toString() => 'MicrophoneException($code): $message';
}

class MicrophoneInfo {
  const MicrophoneInfo({
    required this.isMicrophonePresent,
    required this.isInputMuted,
    required this.inputVolume,
    required this.maxInputVolume,
    required this.currentMode,
    required this.inputDevices,
    required this.properties,
    required this.routing,
  });
  factory MicrophoneInfo.fromJson(Map<String, dynamic> json) => MicrophoneInfo(
        isMicrophonePresent: json['isMicrophonePresent'] as bool,
        isInputMuted: json['isInputMuted'] as bool,
        inputVolume: json['inputVolume'] as int,
        maxInputVolume: json['maxInputVolume'] as int,
        currentMode: json['currentMode'] as String,
        inputDevices: (json['inputDevices'] as List?)
                ?.map((device) => device is Map ? AudioInputDevice.fromJson(Map<String, dynamic>.from(device)) : null)
                .whereType<AudioInputDevice>()
                .toList() ??
            [],
        properties: AudioProperties.fromJson(Map<String, dynamic>.from(json['properties'] as Map<dynamic, dynamic>)),
        routing: AudioRouting.fromJson(Map<String, dynamic>.from(json)),
      );
  final bool isMicrophonePresent;
  final bool isInputMuted;
  final int inputVolume;
  final int maxInputVolume;
  final String currentMode;
  final List<AudioInputDevice> inputDevices;
  final AudioProperties properties;
  final AudioRouting routing;
  Map<String, dynamic> toJson() => {
        'isMicrophonePresent': isMicrophonePresent,
        'isInputMuted': isInputMuted,
        'inputVolume': inputVolume,
        'maxInputVolume': maxInputVolume,
        'currentMode': currentMode,
        'inputDevices': inputDevices.map((device) => device.toJson()).toList(),
        'properties': properties.toJson(),
        'routing': routing.toJson(),
      };
}

class AudioInputDevice {
  const AudioInputDevice({
    required this.type,
    required this.name,
    required this.address,
    required this.isSourceAssociated,
  });
  factory AudioInputDevice.fromJson(Map<String, dynamic> json) => AudioInputDevice(
        type: json['type'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        isSourceAssociated: json['isSourceAssociated'] as bool,
      );
  final int type;
  final String name;
  final String address;
  final bool isSourceAssociated;
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'address': address,
        'isSourceAssociated': isSourceAssociated,
      };
}

class AudioProperties {
  const AudioProperties({
    required this.sampleRate,
    required this.channelCount,
    required this.encoding,
  });
  factory AudioProperties.fromJson(Map<String, dynamic> json) => AudioProperties(
        sampleRate: json['sampleRate'] as int,
        channelCount: json['channelCount'] as int,
        encoding: json['encoding'] as String,
      );
  final int sampleRate;
  final int channelCount;
  final String encoding;
  Map<String, dynamic> toJson() => {
        'sampleRate': sampleRate,
        'channelCount': channelCount,
        'encoding': encoding,
      };
}

class AudioRouting {
  const AudioRouting({
    required this.isSpeakerphoneOn,
    required this.isBluetoothScoOn,
    required this.isWiredHeadsetOn,
  });
  factory AudioRouting.fromJson(Map<String, dynamic> json) => AudioRouting(
        isSpeakerphoneOn: json['isSpeakerphoneOn'] as bool,
        isBluetoothScoOn: json['isBluetoothScoOn'] as bool,
        isWiredHeadsetOn: json['isWiredHeadsetOn'] as bool,
      );
  final bool isSpeakerphoneOn;
  final bool isBluetoothScoOn;
  final bool isWiredHeadsetOn;
  Map<String, dynamic> toJson() => {
        'isSpeakerphoneOn': isSpeakerphoneOn,
        'isBluetoothScoOn': isBluetoothScoOn,
        'isWiredHeadsetOn': isWiredHeadsetOn,
      };
}

extension MicrophoneInfoExtension on MicrophoneInfo {
  bool get hasInputDevice => inputDevices.isNotEmpty;
  double get volumePercentage => inputVolume / maxInputVolume * 100;
  bool get isUsingExternalMic => routing.isBluetoothScoOn || routing.isWiredHeadsetOn;
  AudioInputDevice? get primaryInputDevice => inputDevices.isNotEmpty ? inputDevices.first : null;
}
