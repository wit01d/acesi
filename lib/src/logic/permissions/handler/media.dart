import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaHandler {
  static const platform = MethodChannel('com.example.company_app/media');
  static Future<bool> _checkMediaPermissions() async {
    final photoStatus = await Permission.photos.status;
    final videoStatus = await Permission.videos.status;
    if (!photoStatus.isGranted || !videoStatus.isGranted) {
      final photoResult = await Permission.photos.request();
      final videoResult = await Permission.videos.request();
      return photoResult.isGranted && videoResult.isGranted;
    }
    return true;
  }

  static Future<MediaLibraryInfo?> getMediaLibraryInfo() async {
    if (!await _checkMediaPermissions()) {
      return null;
    }
    try {
      final result = await platform.invokeMethod('getMediaLibraryInfo');
      if (result is Map) {
        return MediaLibraryInfo.fromJson(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<List<MediaItem>?> getRecentMedia({int limit = 20}) async {
    if (!await _checkMediaPermissions()) {
      return null;
    }
    try {
      final result = await platform.invokeMethod('getRecentMedia', {
        'limit': limit,
      });
      return (result as List).map((item) => MediaItem.fromJson(item as Map<String, dynamic>)).toList();
    } on PlatformException {
      return null;
    }
  }
}

class MediaLibraryInfo {
  const MediaLibraryInfo({
    required this.totalPhotos,
    required this.totalVideos,
    required this.photoStats,
    required this.videoStats,
    required this.availableSpace,
    required this.maxFileSize,
  });
  factory MediaLibraryInfo.fromJson(Map<String, dynamic> json) => MediaLibraryInfo(
        totalPhotos: json['totalPhotos'] as int,
        totalVideos: json['totalVideos'] as int,
        photoStats: PhotoStats.fromJson((json['photoStats'] as Map).cast<String, dynamic>()),
        videoStats: VideoStats.fromJson((json['videoStats'] as Map).cast<String, dynamic>()),
        availableSpace: json['availableSpace'] as int,
        maxFileSize: json['maxFileSize'] as int,
      );
  final int totalPhotos;
  final int totalVideos;
  final PhotoStats photoStats;
  final VideoStats videoStats;
  final int availableSpace;
  final int maxFileSize;
  Map<String, dynamic> toJson() => {
        'totalPhotos': totalPhotos,
        'totalVideos': totalVideos,
        'photoStats': photoStats.toJson(),
        'videoStats': videoStats.toJson(),
        'availableSpace': availableSpace,
        'maxFileSize': maxFileSize,
      };
}

class PhotoStats {
  const PhotoStats({
    required this.totalSize,
    required this.maxResolution,
    required this.oldestPhoto,
    required this.newestPhoto,
  });
  factory PhotoStats.fromJson(Map<String, dynamic> json) => PhotoStats(
        totalSize: json['totalSize'] as int,
        maxResolution: json['maxResolution'] as String,
        oldestPhoto: json['oldestPhoto'] as int,
        newestPhoto: json['newestPhoto'] as int,
      );
  final int totalSize;
  final String maxResolution;
  final int oldestPhoto;
  final int newestPhoto;
  Map<String, dynamic> toJson() => {
        'totalSize': totalSize,
        'maxResolution': maxResolution,
        'oldestPhoto': oldestPhoto,
        'newestPhoto': newestPhoto,
      };
}

class VideoStats {
  const VideoStats({
    required this.totalSize,
    required this.totalDuration,
    required this.maxDuration,
    required this.oldestVideo,
    required this.newestVideo,
  });
  factory VideoStats.fromJson(Map<String, dynamic> json) => VideoStats(
        totalSize: json['totalSize'] as int,
        totalDuration: json['totalDuration'] as int,
        maxDuration: json['maxDuration'] as int,
        oldestVideo: json['oldestVideo'] as int,
        newestVideo: json['newestVideo'] as int,
      );
  final int totalSize;
  final int totalDuration;
  final int maxDuration;
  final int oldestVideo;
  final int newestVideo;
  Map<String, dynamic> toJson() => {
        'totalSize': totalSize,
        'totalDuration': totalDuration,
        'maxDuration': maxDuration,
        'oldestVideo': oldestVideo,
        'newestVideo': newestVideo,
      };
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.dateTaken,
    required this.size,
    required this.width,
    required this.height,
    required this.mimeType,
  });
  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'].toString(),
        name: json['name'] as String,
        type: json['type'] as String,
        dateTaken: json['dateTaken'] as int,
        size: json['size'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        mimeType: json['mimeType'] as String,
      );
  final String id;
  final String name;
  final String type;
  final int dateTaken;
  final int size;
  final int width;
  final int height;
  final String mimeType;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'dateTaken': dateTaken,
        'size': size,
        'width': width,
        'height': height,
        'mimeType': mimeType,
      };
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTaken);
  double get fileSizeMB => size / (1024 * 1024);
  String get resolution => '${width}x$height';
  bool get isVideo => type == 'video';
  bool get isPhoto => type == 'image';
}
