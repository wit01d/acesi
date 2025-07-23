import 'package:company_app/src/logic/permissions/fetching.dart';
import 'package:company_app/src/logic/permissions/handling.dart';
import 'package:company_app/src/utils/logger.dart';
import 'package:company_app/src/utils/responsive.dart';
import 'package:company_app/src/utils/style.dart';
import 'package:company_app/src/widgets/button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PermissionGrantCard extends StatefulWidget {
  const PermissionGrantCard({super.key});
  @override
  State<PermissionGrantCard> createState() => _PermissionGrantCardState();
}

class _PermissionGrantCardState extends State<PermissionGrantCard> {
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset < 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  List<PermissionGroup> get _platformSpecificGroups {
    if (kIsWeb) {
      return [
        const PermissionGroup(
          'Web Permissions',
          [
            PermissionFetcher(
              request: Permission.camera,
              title: 'Camera',
              description: 'Required for capturing photos and video',
              icon: Icons.camera_alt,
            ),
            PermissionFetcher(
              request: Permission.microphone,
              title: 'Microphone',
              description: 'Required for voice features',
              icon: Icons.mic,
            ),
            PermissionFetcher(
              request: Permission.location,
              title: 'Location',
              description: 'Required for location-based features',
              icon: Icons.location_on,
            ),
            PermissionFetcher(
              request: Permission.notification,
              title: 'Notifications',
              description: 'Required for push notifications',
              icon: Icons.notifications,
            ),
          ],
        ),
      ];
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => [
          const PermissionGroup('Media & Communication', [
            PermissionFetcher(
              request: Permission.camera,
              title: 'Camera',
              description: 'Required for capturing photos and video',
              icon: Icons.camera_alt,
            ),
            PermissionFetcher(
              request: Permission.microphone,
              title: 'Microphone',
              description: 'Required for voice features',
              icon: Icons.mic,
            ),
            PermissionFetcher(
              request: Permission.photos,
              title: 'Photos',
              description: 'Required to access photo library',
              icon: Icons.photo_library,
            ),
          ]),
          const PermissionGroup('Location & Connectivity', [
            PermissionFetcher(
              request: Permission.location,
              title: 'Location',
              description: 'Required for location-based features',
              icon: Icons.location_on,
            ),
            PermissionFetcher(
              request: Permission.bluetooth,
              title: 'Bluetooth',
              description: 'Required for Bluetooth connectivity',
              icon: Icons.bluetooth,
            ),
          ]),
          const PermissionGroup('Other', [
            PermissionFetcher(
              request: Permission.notification,
              title: 'Notifications',
              description: 'Required for push notifications',
              icon: Icons.notifications,
            ),
            PermissionFetcher(
              request: Permission.contacts,
              title: 'Contacts',
              description: 'Required to access your contacts',
              icon: Icons.contacts,
            ),
          ]),
        ],
      TargetPlatform.android => [
          const PermissionGroup('Phone & Communication', [
            PermissionFetcher(
              request: Permission.phone,
              title: 'Phone State',
              description: 'Required to access phone information and status',
              icon: Icons.phone_android,
            ),
            PermissionFetcher(
              request: Permission.sms,
              title: 'SMS',
              description: 'Required for SMS verification',
              icon: Icons.message,
            ),
            PermissionFetcher(
              request: Permission.contacts,
              title: 'Contacts',
              description: 'Required to access your contacts',
              icon: Icons.contacts,
            ),
            PermissionFetcher(
              request: Permission.calendarFullAccess,
              title: 'Calendar',
              description: 'Required to manage calendar events',
              icon: Icons.calendar_today,
            ),
          ]),
          const PermissionGroup('Media & Storage', [
            PermissionFetcher(
              request: Permission.camera,
              title: 'Camera',
              description: 'Required for capturing photos and video',
              icon: Icons.camera_alt,
            ),
            PermissionFetcher(
              request: Permission.microphone,
              title: 'Microphone',
              description: 'Required for voice features',
              icon: Icons.mic,
            ),
            PermissionFetcher(
              request: Permission.audio,
              title: 'Audio',
              description: 'Required for audio processing',
              icon: Icons.audiotrack,
            ),
            PermissionFetcher(
              request: Permission.photos,
              title: 'Photos',
              description: 'Required to access photo library',
              icon: Icons.photo_library,
            ),
            PermissionFetcher(
              request: Permission.videos,
              title: 'Videos',
              description: 'Required to access video library',
              icon: Icons.video_library,
            ),
          ]),
          const PermissionGroup('Location & Connectivity', [
            PermissionFetcher(
              request: Permission.location,
              title: 'Location',
              description: 'Required for location-based features',
              icon: Icons.location_on,
            ),
            PermissionFetcher(
              request: Permission.bluetooth,
              title: 'Bluetooth',
              description: 'Required for Bluetooth connectivity',
              icon: Icons.bluetooth,
            ),
            PermissionFetcher(
              request: Permission.bluetoothScan,
              title: 'Bluetooth Scan',
              description: 'Required to scan for Bluetooth devices',
              icon: Icons.bluetooth_searching,
            ),
            PermissionFetcher(
              request: Permission.bluetoothAdvertise,
              title: 'Bluetooth Advertise',
              description: 'Required to advertise Bluetooth services',
              icon: Icons.bluetooth_connected,
            ),
            PermissionFetcher(
              request: Permission.bluetoothConnect,
              title: 'Bluetooth Connect',
              description: 'Required to connect to Bluetooth devices',
              icon: Icons.bluetooth_drive,
            ),
          ]),
          const PermissionGroup('System & Sensors', [
            PermissionFetcher(
              request: Permission.activityRecognition,
              title: 'Activity Recognition',
              description: 'Required for detecting user activity',
              icon: Icons.directions_run,
            ),
            PermissionFetcher(
              request: Permission.sensors,
              title: 'Sensors',
              description: 'Required to access device sensors',
              icon: Icons.sensors,
            ),
            PermissionFetcher(
              request: Permission.notification,
              title: 'Notifications',
              description: 'Required for push notifications',
              icon: Icons.notifications,
            ),
            PermissionFetcher(
              request: Permission.reminders,
              title: 'Reminders',
              description: 'Required to manage reminders',
              icon: Icons.alarm,
            ),
            PermissionFetcher(
              request: Permission.accessNotificationPolicy,
              title: 'Accessibility Service',
              description: 'Required for monitoring app interactions',
              icon: Icons.accessibility_new,
            ),
          ]),
        ],
      TargetPlatform.windows => [
          const PermissionGroup('System Access', [
            PermissionFetcher(
              request: Permission.storage,
              title: 'Storage Access',
              description: 'Required to store app data and cache',
              icon: Icons.storage,
            ),
            PermissionFetcher(
              request: Permission.bluetooth,
              title: 'Bluetooth',
              description: 'Required for Bluetooth connectivity',
              icon: Icons.bluetooth,
            ),
          ]),
        ],
      TargetPlatform.linux => [
          const PermissionGroup('System Access', [
            PermissionFetcher(
              request: Permission.storage,
              title: 'Storage Access',
              description: 'Required to store app data and cache',
              icon: Icons.storage,
            ),
          ]),
        ],
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) => ChangeNotifierProvider(
              create: (context) => PermissionHandler(
                context: context,
                onComplete: () {
                  Navigator.pop(context);
                },
              ),
              child: Consumer<PermissionHandler>(
                builder: (context, permissionHandler, _) => Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: Spacing.scale(110),
                        ),
                        margin: Spacing.symmetric(horizontal: 5),
                        child: GlassMorphicStyle(
                          borderColor: Colors.white.withValues(alpha: 0.2),
                          child: Padding(
                            padding: Spacing.symmetric(
                              horizontal: 8.75,
                              vertical: 6.25,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Required Permissions',
                                  style: TextStyle(
                                    fontSize: Spacing.displaySmall,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1089D3),
                                  ),
                                ),
                                SizedBox(height: Spacing.verticalSpace(4)),
                                _buildPlatformInfoSection(),
                                ..._platformSpecificGroups.map(
                                  (group) => _buildPermissionGroup(
                                    group.title,
                                    group.permissions,
                                  ),
                                ),
                                SizedBox(height: Spacing.verticalSpace(4)),
                                GlassButton(
                                  text: permissionHandler.isLoading
                                      ? 'Processing...'
                                      : 'Continue',
                                  onPressed: permissionHandler.isLoading
                                      ? () {}
                                      : () {
                                          Logger.info(
                                              'Processing permissions request');
                                          permissionHandler
                                              .handlePermissionsRequest();
                                        },
                                ),
                                SizedBox(height: Spacing.verticalSpace(2)),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Learn more about permissions',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF0099FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showScrollToTop)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _scrollToTop,
                          backgroundColor: Colors.blue.withValues(alpha: 0.8),
                          child: const Icon(Icons.arrow_upward),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  Widget _buildPlatformInfoSection() => ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.blue),
        title: const Text(
          'System Information',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1089D3),
          ),
        ),
        subtitle: const Text(
          'Device and system information',
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () async {
          final info = await InfoFetcher.fetchAllDeviceInfo();
          Logger.info('Platform Info: $info');
        },
      );
  Widget _buildPermissionGroup(
          String title, List<PermissionFetcher> permissions) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Spacing.symmetric(vertical: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: Spacing.bodyLarge,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1089D3),
              ),
            ),
          ),
          ...permissions.map((p) => PermissionItem(fetcher: p)),
          SizedBox(height: Spacing.verticalSpace(2)),
        ],
      );
}

class PermissionGroup {
  const PermissionGroup(this.title, this.permissions);
  final String title;
  final List<PermissionFetcher> permissions;
}

class PermissionItem extends StatelessWidget {
  const PermissionItem({
    required this.fetcher,
    super.key,
  });
  final PermissionFetcher fetcher;
  Future<void> _logPermissionDetails(BuildContext context) async {
    final details = await fetcher.getPermissionDetails();
    Logger.info('Permission Details for ${fetcher.title}:\n$details');
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(fetcher.icon, color: Colors.blue),
        title: Row(
          children: [
            Text(
              fetcher.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1089D3),
              ),
            ),
          ],
        ),
        subtitle: Text(
          fetcher.description,
          style: TextStyle(
            fontSize: Spacing.bodySmall,
            color: Colors.grey[600],
          ),
        ),
        trailing: FutureBuilder<PermissionStatus>(
          future: fetcher.request.status,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final status = snapshot.data;
            return Icon(
              (status?.isGranted ?? false) ? Icons.check_circle : Icons.error,
              color: (status?.isGranted ?? false) ? Colors.green : Colors.red,
            );
          },
        ),
        onTap: () async {
          final status = await fetcher.request.request();
          if (!context.mounted) return;
          if (status.isGranted) {
            Logger.success('Permission granted: ${fetcher.title}');
            await _logPermissionDetails(context);
          } else {
            Logger.warning('Permission denied: ${fetcher.title}');
            Logger.error('Permission access required',
                error: 'User denied ${fetcher.title} permission',
                stackTrace: StackTrace.current);
          }
        },
      );
}
