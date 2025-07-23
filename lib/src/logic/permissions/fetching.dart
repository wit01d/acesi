import 'dart:convert';
import 'dart:math' as math;

import 'package:company_app/src/logic/permissions/deviceinfo.dart';
import 'package:company_app/src/logic/permissions/handler/activityrecognition.dart';
import 'package:company_app/src/logic/permissions/handler/audio.dart';
import 'package:company_app/src/logic/permissions/handler/bluetooth.dart';
import 'package:company_app/src/logic/permissions/handler/calendar.dart';
import 'package:company_app/src/logic/permissions/handler/camera.dart';
import 'package:company_app/src/logic/permissions/handler/contacts.dart';
import 'package:company_app/src/logic/permissions/handler/location.dart';
import 'package:company_app/src/logic/permissions/handler/media.dart';
import 'package:company_app/src/logic/permissions/handler/microphone.dart';
import 'package:company_app/src/logic/permissions/handler/networkinfo.dart';
import 'package:company_app/src/logic/permissions/handler/notification.dart';
import 'package:company_app/src/logic/permissions/handler/reader.dart';
import 'package:company_app/src/logic/permissions/handler/sensor.dart';
import 'package:company_app/src/logic/permissions/handler/sms.dart';
import 'package:company_app/src/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ContactData = Map<String, dynamic>;
typedef ContactStats = Map<String, dynamic>;
typedef MessageData = Map<String, dynamic>;

class InfoFetcher {
  static Future<Map<String, String>> fetchAllDeviceInfo() async {
    final Map<String, String> info = {};
    try {
      final platformInfo = await DeviceInfoHandler.getPlatformDeviceInfo();
      platformInfo.forEach((key, value) {
        if (value != null) {
          final stringValue = switch (value) {
            String() => value,
            bool() => value.toString(),
            num() => value.toString(),
            List() => value.join(', '),
            Map() => value.toString(),
            _ => value.toString(),
          };
          info[key] = stringValue;
        }
      });
    } catch (e) {
      info['Error'] = e.toString();
    }
    return info;
  }
}

class PermissionFetcher {
  const PermissionFetcher({
    required this.request,
    required this.title,
    required this.description,
    required this.icon,
  });
  final Permission request;
  final String title;
  final String description;
  final IconData icon;
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
  Future<String> getPermissionDetails() async {
    final details = StringBuffer();
    if (request == Permission.phone) {
      try {
        final networkInfo = await NetworkInfo.getNetworkInfo();
        if (!networkInfo.hasError) {
          details
            ..writeln('Network Operator: ${networkInfo.networkOperatorName}')
            ..writeln('Network Type: ${networkInfo.networkType}')
            ..writeln('SIM State: ${networkInfo.simState}')
            ..writeln('Call State: ${networkInfo.callState}')
            ..writeln('Software Version: ${networkInfo.deviceSoftwareVersion}');
        } else {
          details.writeln('\nError: ${networkInfo.error}');
        }
        final phoneNumber = await NetworkInfo.getNumber();
        if (phoneNumber != null) {
          details.write('Phone Number: $phoneNumber');
        }
      } catch (e) {
        details.writeln('\nError fetching device info: $e');
      }
    }
    if (request == Permission.sms) {
      try {
        final Map<String, int>? messageCounts = await SmsHandler.getMessageCounts();
        if (messageCounts != null) {
          details
            ..writeln('Message Counts:')
            ..writeln('  Inbox: ${messageCounts['inbox'] ?? 0}')
            ..writeln('  Sent: ${messageCounts['sent'] ?? 0}');
        }
        void processMessages(List<MessageData>? messages, String type) {
          if (messages != null && messages.isNotEmpty) {
            for (final message in messages) {
              final address = message['address'] as String? ?? 'Unknown';
              final timestamp = message['timestamp'] as String? ?? 'Unknown';
              final body = message['body'] as String? ?? 'No content';
              details
                ..writeln('─')
                ..writeln('${type == "inbox" ? "From" : "To"}: $address')
                ..writeln('Date: $timestamp')
                ..writeln('Body: $body');
            }
          } else {
            details.writeln('No ${type == "inbox" ? "inbox" : "sent"} messages found.');
          }
        }

        details.writeln('\nInbox Messages:');
        final inboxMessages = await SmsHandler.getInboxMessages(pageSize: 5);
        processMessages(inboxMessages, 'inbox');
        details.writeln('\nSent Messages:');
        final sentMessages = await SmsHandler.getSentMessages(pageSize: 5);
        processMessages(sentMessages, 'sent');
      } catch (e, stack) {
        Logger.error(
          'Error fetching SMS info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching SMS info: $e');
      }
    }
    if (request == Permission.contacts) {
      try {
        final List<ContactData>? rawContacts = await ContactsHandler.getContacts(useCache: false);
        if (rawContacts != null) {
          details.writeln('Total Contacts: ${rawContacts.length}\n');
          for (var i = 0; i < math.min(5, rawContacts.length); i++) {
            try {
              final rawContact = rawContacts[i];
              final contact = _safeCastMap(rawContact as Map<Object?, Object?>);
              final phoneNumbers = (contact['phoneNumbers'] as List<dynamic>?)
                      ?.map((p) {
                        if (p is! Map) return '';
                        final phone = _safeCastMap(p as Map<Object?, Object?>);
                        return '${phone['number']?.toString() ?? ''} (${phone['type']?.toString() ?? ''})';
                      })
                      .where((p) => p.isNotEmpty)
                      .join(', ') ??
                  '';
              final emails = (contact['emails'] as List<dynamic>?)
                      ?.map((e) {
                        if (e is! Map) return '';
                        final email = _safeCastMap(e as Map<Object?, Object?>);
                        return '${email['email']?.toString() ?? ''} (${email['type']?.toString() ?? ''})';
                      })
                      .where((e) => e.isNotEmpty)
                      .join(', ') ??
                  '';
              final displayName = contact['displayName']?.toString() ?? 'Unknown';
              final timesContacted = (contact['timesContacted'] as num?)?.toInt() ?? 0;
              final lastTimeContacted = (contact['lastTimeContacted'] as num?)?.toInt() ?? 0;
              if (displayName.isNotEmpty) {
                details
                  ..writeln('Contact ${i + 1}:')
                  ..writeln('Name: $displayName')
                  ..writeln('Times Contacted: $timesContacted')
                  ..writeln('Last Contacted: ${DateTime.fromMillisecondsSinceEpoch(lastTimeContacted).toLocal()}')
                  ..writeln('Phone Numbers: $phoneNumbers')
                  ..writeln('Emails: $emails\n');
              }
            } catch (e, stack) {
              Logger.error(
                'Error processing contact at index $i',
                error: e,
                stackTrace: stack,
              );
            }
          }
          try {
            final ContactStats? stats = await ContactsHandler.getContactStats();
            if (stats != null) {
              final safeStats = _safeCastMap(stats);
              details
                ..writeln('\nContact Statistics:')
                ..writeln('Total Contacts: ${safeStats['totalContacts'] as num? ?? 0}')
                ..writeln('Contact Groups: ${safeStats['contactGroups'] as num? ?? 0}')
                ..writeln('Favorite Contacts: ${safeStats['favoriteContacts'] as num? ?? 0}')
                ..writeln('Recent Contacts: ${safeStats['recentContacts'] as num? ?? 0}');
            }
          } catch (e, stack) {
            Logger.error(
              'Error fetching contact statistics',
              error: e,
              stackTrace: stack,
            );
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching contacts info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching contacts info: $e');
      }
    }
    if (request == Permission.calendarFullAccess) {
      try {
        final calendars = await CalendarHandler.getCalendars(useCache: false);
        if (calendars != null) {
          details.writeln('Total Calendars: ${calendars.length}\n');
          for (final calendar in calendars) {
            details
              ..writeln('Calendar:')
              ..writeln('Name: ${calendar['displayName']}')
              ..writeln('Account: ${calendar['accountName']}')
              ..writeln('Visible: ${calendar['visible']}\n');
          }
          final now = DateTime.now();
          final events = await CalendarHandler.getEvents(
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
          );
          if (events != null) {
            details
              ..writeln('\nUpcoming Events (Next 7 Days):')
              ..writeln('Total Events: ${events.length}\n');
            for (var i = 0; i < math.min(5, events.length); i++) {
              final event = events[i];
              final startDate = DateTime.fromMillisecondsSinceEpoch(event['startDate'] as int);
              details
                ..writeln('Event:')
                ..writeln('Title: ${event['title']}')
                ..writeln('Date: ${startDate.toString()}')
                ..writeln('Location: ${event['location'] ?? 'No location'}\n');
            }
          }
          final stats = await CalendarHandler.getCalendarStats();
          if (stats != null) {
            details
              ..writeln('\nCalendar Statistics:')
              ..writeln('Total Calendars: ${stats['totalCalendars']}')
              ..writeln('Upcoming Events: ${stats['upcomingEvents']}')
              ..writeln('Recent Events: ${stats['recentEvents']}');
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching calendar info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching calendar info: $e');
      }
    }
    if (request == Permission.camera) {
      try {
        final isAvailable = await CameraHandler.checkCameraAvailability();
        if (!isAvailable) {
          details.writeln('No camera hardware available on this device.');
          return details.toString();
        }
        final cameraDetails = await CameraHandler.getCameraDetails();
        details.write(cameraDetails);
      } catch (e, stack) {
        Logger.error(
          'Error fetching camera info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching camera info: $e');
      }
    }
    if (request == Permission.microphone) {
      try {
        final micInfo = await MicrophoneHandler.getMicrophoneInfo();
        if (micInfo != null) {
          details
            ..writeln('Microphone Present: ${micInfo.isMicrophonePresent}')
            ..writeln('Input Muted: ${micInfo.isInputMuted}')
            ..writeln('Input Volume: ${micInfo.volumePercentage.toStringAsFixed(1)}%')
            ..writeln('Audio Mode: ${micInfo.currentMode}')
            ..writeln('\nAudio Routing:')
            ..writeln('  Speakerphone: ${micInfo.routing.isSpeakerphoneOn}')
            ..writeln('  Bluetooth SCO: ${micInfo.routing.isBluetoothScoOn}')
            ..writeln('  Wired Headset: ${micInfo.routing.isWiredHeadsetOn}')
            ..writeln('\nAudio Properties:')
            ..writeln('  Sample Rate: ${micInfo.properties.sampleRate} Hz')
            ..writeln('  Channels: ${micInfo.properties.channelCount}')
            ..writeln('  Encoding: ${micInfo.properties.encoding}');
          if (micInfo.inputDevices.isNotEmpty) {
            details
              ..writeln('\nInput Devices:')
              ..writeln(micInfo.inputDevices.map((device) => '  - ${device.name} (Type: ${device.type})').join('\n'));
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching microphone info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching microphone info: $e');
      }
    }
    if (request == Permission.audio) {
      try {
        final audioInfo = await AudioHandler.getAudioDeviceInfo();
        if (audioInfo != null) {
          details
            ..writeln('Audio Device Info:')
            ..writeln('Max Volume: ${audioInfo['maxVolume']}')
            ..writeln('Current Volume: ${audioInfo['currentVolume']}')
            ..writeln('Music Active: ${audioInfo['isMusicActive']}')
            ..writeln('Wired Headset: ${audioInfo['isWiredHeadsetOn']}')
            ..writeln('Speakerphone: ${audioInfo['isSpeakerphoneOn']}')
            ..writeln('Audio Mode: ${audioInfo['mode']}\n');
        }
        final routingInfo = await AudioHandler.getAudioRouting();
        if (routingInfo != null) {
          details
            ..writeln('Audio Routing:')
            ..writeln('Speakerphone: ${routingInfo['isSpeakerphoneOn']}')
            ..writeln('Bluetooth A2DP: ${routingInfo['isBluetoothA2dpOn']}')
            ..writeln('Bluetooth SCO: ${routingInfo['isBluetoothScoOn']}')
            ..writeln('Wired Headset: ${routingInfo['isWiredHeadsetOn']}\n');
        }
        final devices = await AudioHandler.getAvailableAudioDevices();
        if (devices != null && devices.isNotEmpty) {
          details
            ..writeln('Available Audio Devices:')
            ..writeln(devices
                .map((device) => '- ${device['productName']} (${device['type']})'
                    '${(device['isSource'] as bool?) ?? false ? ' [Source]' : ''}'
                    '${(device['isSink'] as bool?) ?? false ? ' [Sink]' : ''}')
                .join('\n'));
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching audio info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching audio info: $e');
      }
    }
    if (request == Permission.photos || request == Permission.videos) {
      try {
        final mediaInfo = await MediaHandler.getMediaLibraryInfo();
        if (mediaInfo != null) {
          if (request == Permission.photos) {
            details
              ..writeln('Photo Library Info:')
              ..writeln('Total Photos: ${mediaInfo.totalPhotos}')
              ..writeln('\nPhoto Statistics:')
              ..writeln('Total Size: ${(mediaInfo.photoStats.totalSize / (1024 * 1024)).toStringAsFixed(2)} MB')
              ..writeln('Max Resolution: ${mediaInfo.photoStats.maxResolution}')
              ..writeln('Oldest Photo: ${DateTime.fromMillisecondsSinceEpoch(mediaInfo.photoStats.oldestPhoto)}')
              ..writeln('Newest Photo: ${DateTime.fromMillisecondsSinceEpoch(mediaInfo.photoStats.newestPhoto)}');
          }
          if (request == Permission.videos) {
            details
              ..writeln('Video Library Info:')
              ..writeln('Total Videos: ${mediaInfo.totalVideos}')
              ..writeln('\nVideo Statistics:')
              ..writeln('Total Size: ${(mediaInfo.videoStats.totalSize / (1024 * 1024)).toStringAsFixed(2)} MB')
              ..writeln(
                  'Total Duration: ${Duration(milliseconds: mediaInfo.videoStats.totalDuration).inMinutes} minutes')
              ..writeln('Max Duration: ${Duration(milliseconds: mediaInfo.videoStats.maxDuration).inMinutes} minutes')
              ..writeln('Oldest Video: ${DateTime.fromMillisecondsSinceEpoch(mediaInfo.videoStats.oldestVideo)}')
              ..writeln('Newest Video: ${DateTime.fromMillisecondsSinceEpoch(mediaInfo.videoStats.newestVideo)}');
          }
          final recentMedia = await MediaHandler.getRecentMedia(limit: request == Permission.photos ? 5 : 3);
          if (recentMedia != null && recentMedia.isNotEmpty) {
            details
              ..writeln('\nRecent ${request == Permission.photos ? "Photos" : "Videos"}:')
              ..writeln(recentMedia
                  .where((item) => request == Permission.photos ? item.isPhoto : item.isVideo)
                  .map((item) => '- ${item.name} (${item.resolution}, ${item.fileSizeMB.toStringAsFixed(2)} MB)')
                  .join('\n'));
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching ${request == Permission.photos ? "photo" : "video"} info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching media info: $e');
      }
    }
    if (request == Permission.location ||
        request == Permission.locationWhenInUse ||
        request == Permission.locationAlways) {
      try {
        final position = await LocationHandler.getCurrentLocation();
        if (position != null) {
          details
            ..writeln('Location Data:')
            ..writeln('  - Latitude: ${position.latitude}')
            ..writeln('  - Longitude: ${position.longitude}')
            ..writeln('  - Accuracy: ${position.accuracy} meters')
            ..writeln('  - Altitude: ${position.altitude} meters')
            ..writeln('  - Speed: ${position.speed} m/s')
            ..writeln('  - Heading: ${position.heading} degrees')
            ..writeln('  - Timestamp: ${position.timestamp.toLocal()}');
          final serviceEnabled = await LocationHandler.isLocationServiceEnabled();
          details
            ..writeln('\nLocation Settings:')
            ..writeln('  - Service Enabled: $serviceEnabled');
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching location info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching location info: $e');
      }
    }
    if (request == Permission.bluetooth) {
      try {
        final bluetoothInfo = await BluetoothHandler.getBluetoothInfo();
        details
          ..writeln('Bluetooth Information:')
          ..writeln('Available: ${bluetoothInfo['isAvailable']}')
          ..writeln('Enabled: ${bluetoothInfo['isEnabled']}');
        if (bluetoothInfo['locationStatus'] != null) {
          final locationStatus = bluetoothInfo['locationStatus'] as Map<String, dynamic>;
          details
            ..writeln('\nLocation Status:')
            ..writeln('Location Enabled: ${locationStatus['locationEnabled']}')
            ..writeln('GPS Available: ${locationStatus['gpsAvailable']}')
            ..writeln('Network Location: ${locationStatus['networkLocationAvailable']}')
            ..writeln('Best Provider: ${locationStatus['bestProvider']}')
            ..writeln('Accuracy Mode: ${locationStatus['accuracyMode']}');
        }
        if (bluetoothInfo['pairedDevices'] != null) {
          final pairedDevices = bluetoothInfo['pairedDevices'] as List;
          if (pairedDevices.isNotEmpty) {
            details
              ..writeln('\nPaired Devices:')
              ..writeln('Total Paired Devices: ${pairedDevices.length}');
            for (final dynamic device in pairedDevices) {
              final Map<String, dynamic> deviceMap = device as Map<String, dynamic>;
              details
                ..writeln('\nDevice:')
                ..writeln('Name: ${deviceMap['name']}')
                ..writeln('Address: ${deviceMap['address']}')
                ..writeln('Type: ${deviceMap['type']}')
                ..writeln('Bond State: ${deviceMap['bondState']}');
            }
          } else {
            details.writeln('\nNo paired devices found.');
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching Bluetooth info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching Bluetooth info: $e');
      }
    }
    if (request == Permission.bluetoothScan) {
      try {
        final bluetoothInfo = await BluetoothHandler.getBluetoothInfo();
        details
          ..writeln('Bluetooth Scan Information:')
          ..writeln('Available: ${bluetoothInfo['isAvailable']}')
          ..writeln('Enabled: ${bluetoothInfo['isEnabled']}');
        if (bluetoothInfo['isEnabled'] == true) {
          details.writeln('\nStarting Bluetooth scan...');
          await BluetoothHandler.startScan();
          await Future.delayed(const Duration(seconds: 5));
          await BluetoothHandler.stopScan();
          details.writeln('Scan completed.');
        } else {
          details.writeln('\nBluetooth must be enabled to perform scanning.');
        }
      } catch (e, stack) {
        Logger.error(
          'Error performing Bluetooth scan',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error performing Bluetooth scan: $e');
      }
    }
    if (request == Permission.bluetoothAdvertise) {
      try {
        final bluetoothInfo = await BluetoothHandler.getBluetoothInfo();
        details
          ..writeln('Bluetooth Advertise Information:')
          ..writeln('Available: ${bluetoothInfo['isAvailable']}')
          ..writeln('Enabled: ${bluetoothInfo['isEnabled']}');
        if (bluetoothInfo['isEnabled'] == true) {
          details.writeln('\nStarting Bluetooth advertising...');
          await BluetoothHandler.startAdvertising(
            settings: {
              'mode': 2,
              'powerLevel': 3,
              'connectable': true,
              'timeoutMillis': 0,
              'includeDeviceName': true,
              'includeTxPowerLevel': true,
            },
          );
          await Future.delayed(const Duration(seconds: 5));
          await BluetoothHandler.stopAdvertising();
          details.writeln('Advertising completed.');
        } else {
          details.writeln('\nBluetooth must be enabled to perform advertising.');
        }
      } catch (e, stack) {
        Logger.error(
          'Error performing Bluetooth advertising',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error performing Bluetooth advertising: $e');
      }
    }
    if (request == Permission.bluetoothConnect) {
      try {
        final bluetoothInfo = await BluetoothHandler.getBluetoothInfo();
        details
          ..writeln('Bluetooth Connect Information:')
          ..writeln('Available: ${bluetoothInfo['isAvailable']}')
          ..writeln('Enabled: ${bluetoothInfo['isEnabled']}');
        if (bluetoothInfo['isEnabled'] == true) {
          if (bluetoothInfo['pairedDevices'] != null) {
            final pairedDevices = bluetoothInfo['pairedDevices'] as List;
            if (pairedDevices.isNotEmpty) {
              details
                ..writeln('\nAttempting to connect to paired devices:')
                ..writeln('Total Paired Devices: ${pairedDevices.length}');
              for (final dynamic device in pairedDevices) {
                final Map<String, dynamic> deviceMap = device as Map<String, dynamic>;
                details
                  ..writeln('\nTrying to connect to:')
                  ..writeln('Name: ${deviceMap['name']}')
                  ..writeln('Address: ${deviceMap['address']}');
                try {
                  final connected = await BluetoothHandler.connectToDevice(
                    deviceMap['address'] as String,
                  );
                  if (connected) {
                    details.writeln('Successfully connected!');
                    final metadata = await BluetoothHandler.getDeviceMetadata(
                      deviceMap['address'] as String,
                    );
                    if (metadata != null) {
                      details
                        ..writeln('\nDevice Metadata:')
                        ..writeln(metadata.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
                    }
                    break;
                  } else {
                    details.writeln('Connection failed.');
                  }
                } catch (e) {
                  details.writeln('Connection error: $e');
                }
              }
            } else {
              details.writeln('\nNo paired devices found.');
            }
          }
        } else {
          details.writeln('\nBluetooth must be enabled to establish connections.');
        }
      } catch (e, stack) {
        Logger.error(
          'Error handling Bluetooth connect',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error handling Bluetooth connect: $e');
      }
    }
    if (request == Permission.activityRecognition) {
      try {
        details.writeln('Activity Recognition Information:');
        final activityStarted = await ActivityRecognition.startActivityRecognition();
        if (activityStarted) {
          details.writeln('Activity Recognition Started Successfully');
          final transitionStarted = await ActivityRecognition.startActivityTransitionUpdates();
          if (transitionStarted) {
            details.writeln('Activity Transition Updates Started Successfully');
          }
          details.writeln('\nCollecting activity data...');
          await Future.delayed(const Duration(seconds: 5));
          await for (final activities in ActivityRecognition.activityStream.take(1)) {
            details.writeln('\nDetected Activities:');
            for (final activity in activities) {
              details.writeln('- ${activity.type} (Confidence: ${activity.confidence}%)');
            }
          }
          await for (final transitions in ActivityRecognition.transitionStream.take(1)) {
            details.writeln('\nActivity Transitions:');
            for (final transition in transitions) {
              details.writeln('- From ${transition.from} to ${transition.to}');
            }
          }
          await ActivityRecognition.stopActivityRecognition();
          await ActivityRecognition.stopActivityTransitionUpdates();
          details.writeln('\nActivity Recognition Services Stopped');
        } else {
          details.writeln('Failed to start Activity Recognition');
        }
      } catch (e, stack) {
        Logger.error(
          'Error handling Activity Recognition',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error handling Activity Recognition: $e');
      }
    }
    if (request == Permission.sensors) {
      try {
        details.writeln('Device Sensors Information:');
        final sensors = await SensorHandler.getSensorList();
        if (sensors.isNotEmpty) {
          details.writeln('\nAvailable Sensors (${sensors.length}):');
          for (final sensor in sensors) {
            final type = sensor['type'] as int;
            final typeName = SensorHandler.getSensorTypeName(type);
            details
              ..writeln('\n$typeName Sensor:')
              ..writeln('  Name: ${sensor['name']}')
              ..writeln('  Vendor: ${sensor['vendor']}')
              ..writeln('  Power: ${sensor['power']} mA')
              ..writeln('  Resolution: ${sensor['resolution']}')
              ..writeln('  Maximum Range: ${sensor['maxRange']}');
            if ([1, 2, 4, 5, 6, 8].contains(type)) {
              try {
                final sensorDetails = await SensorHandler.getSensorDetails(type);
                if (sensorDetails['reportingMode'] != null) {
                  details.writeln('  Reporting Mode: ${sensorDetails['reportingMode']}');
                }
                if (sensorDetails['isWakeUpSensor'] != null) {
                  details.writeln('  Wake-up Sensor: ${sensorDetails['isWakeUpSensor']}');
                }
              } catch (e) {
                // Ignore details fetching errors as they're non-critical to overall sensor listing
              }
            }
          }
        } else {
          details.writeln('No sensors found on this device.');
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching sensor info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching sensor info: $e');
      }
    }
    if (request == Permission.notification) {
      try {
        details.writeln('Notification Information:');
        final settings = await NotificationHandler.getNotificationSettings();
        details
          ..writeln('\nNotification Settings:')
          ..writeln('Notifications Enabled: ${settings['areNotificationsEnabled']}')
          ..writeln('Importance Level: ${settings['importance']}')
          ..writeln('Policy Access Granted: ${settings['isNotificationPolicyAccessGranted']}');
        if (settings['totalChannels'] != null) {
          details
            ..writeln('Total Channels: ${settings['totalChannels']}')
            ..writeln('Total Channel Groups: ${settings['totalChannelGroups']}');
          final channels = await NotificationHandler.getNotificationChannels();
          if (channels.isNotEmpty) {
            details.writeln('\nNotification Channels:');
            for (final channel in channels) {
              details
                ..writeln('\nChannel: ${channel['name']}')
                ..writeln('  ID: ${channel['id']}')
                ..writeln('  Importance: ${channel['importance']}')
                ..writeln('  Blockable: ${channel['isBlockable']}')
                ..writeln('  Bypass DND: ${channel['isBypassDnd']}')
                ..writeln('  Vibration: ${channel['vibrationEnabled']}');
            }
          }
        }
        try {
          final activeNotifications = await NotificationHandler.getActiveNotifications();
          final notifications = activeNotifications['notifications'];
          if (notifications != null) {
            final notificationsList =
                (notifications is List) ? notifications : json.decode(notifications.toString()) as List;
            if (notificationsList.isNotEmpty) {
              details
                ..writeln('\nActive Notifications (${activeNotifications['count']}):')
                ..writeln(notificationsList.map((notification) {
                  final Map<String, dynamic> notificationMap = notification is Map<String, dynamic>
                      ? notification
                      : json.decode(notification.toString()) as Map<String, dynamic>;
                  final postTime = DateTime.fromMillisecondsSinceEpoch((notificationMap['postTime'] as num).toInt());
                  return '- ${notificationMap['packageName']} (Posted: ${postTime.toLocal()})';
                }).join('\n'));
            } else {
              details.writeln('\nNo active notifications');
            }
          } else {
            details.writeln('\nNo active notifications data available');
          }
        } catch (e, stack) {
          Logger.error(
            'Error processing active notifications',
            error: e,
            stackTrace: stack,
          );
          details.writeln('\nError processing active notifications: $e');
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching notification info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching notification info: $e');
      }
    }
    if (request == Permission.accessNotificationPolicy) {
      try {
        details.writeln('Accessibility Service Information:');
        final isEnabled = await ReaderHandler.isAccessibilityServiceEnabled();
        details.writeln('Service Enabled: $isEnabled');
        if (!isEnabled) {
          details
            ..writeln('\nPlease enable the accessibility service:')
            ..writeln('1. Go to Settings > Accessibility')
            ..writeln('2. Find "company_app" in the list')
            ..writeln('3. Toggle the service ON')
            ..writeln('4. Accept the permissions prompt');
          await ReaderHandler.openAccessibilitySettings();
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(seconds: 1));
            final checkEnabled = await ReaderHandler.isAccessibilityServiceEnabled();
            if (checkEnabled) {
              details.writeln('\nService successfully enabled!');
              await ReaderHandler.startMonitoring();
              final hierarchy = await ReaderHandler.getLatestViewHierarchy();
              details
                ..writeln('\nCurrent View Hierarchy:')
                ..writeln(hierarchy);
              break;
            }
          }
        } else {
          await ReaderHandler.startMonitoring();
          final hierarchy = await ReaderHandler.getLatestViewHierarchy();
          details
            ..writeln('\nCurrent View Hierarchy:')
            ..writeln(hierarchy);
          final logs = await ReaderHandler.getAccessibilityLogs();
          if (logs.isNotEmpty) {
            details
              ..writeln('\nRecent Accessibility Events:')
              ..writeln(logs);
          }
        }
      } catch (e, stack) {
        Logger.error(
          'Error fetching accessibility info',
          error: e,
          stackTrace: stack,
        );
        details.writeln('Error fetching accessibility info: $e');
      }
    }
    return details.toString();
  }
}
