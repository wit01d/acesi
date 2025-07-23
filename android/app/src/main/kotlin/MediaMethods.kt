package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MediaMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/media"
    }

    fun handleMediaMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getMediaLibraryInfo" -> {
                val info = mutableMapOf<String, Any>()

                if (hasPhotoPermissions()) {

                    val photoProjection = arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.DATE_TAKEN,
                        MediaStore.Images.Media.SIZE,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT
                    )
                    val photoUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    context.contentResolver.query(photoUri, photoProjection, null, null, null)?.use { cursor ->
                        info["totalPhotos"] = cursor.count
                        info["photoStats"] = getPhotoStats(cursor)
                    }
                }

                if (hasVideoPermissions()) {

                    val videoProjection = arrayOf(
                        MediaStore.Video.Media._ID,
                        MediaStore.Video.Media.DATE_TAKEN,
                        MediaStore.Video.Media.SIZE,
                        MediaStore.Video.Media.DURATION,
                        MediaStore.Video.Media.RESOLUTION
                    )
                    val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    context.contentResolver.query(videoUri, videoProjection, null, null, null)?.use { cursor ->
                        info["totalVideos"] = cursor.count
                        info["videoStats"] = getVideoStats(cursor)
                    }
                }

                if (!hasPhotoPermissions() && !hasVideoPermissions()) {
                    result.error("PERMISSION_DENIED", "Media permissions not granted", null)
                    return
                }

                info["availableSpace"] = getAvailableStorage()
                info["maxFileSize"] = getMaxFileSize()
                result.success(info)
            }

            "getRecentMedia" -> {
                if (!hasMediaPermissions()) {
                    result.error("PERMISSION_DENIED", "Media permissions not granted", null)
                    return
                }

                try {
                    val media = getRecentMedia()
                    result.success(media)
                } catch (e: Exception) {
                    result.error("QUERY_ERROR", "Failed to get recent media: ${e.message}", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun hasMediaPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun hasPhotoPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.checkSelfPermission(android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
            } else {
                context.checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            }
        } else {
            true
        }
    }

    private fun hasVideoPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.checkSelfPermission(android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
            } else {
                context.checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            }
        } else {
            true
        }
    }

    private fun getPhotoStats(cursor: Cursor): Map<String, Any> {
        var totalSize = 0L
        var maxWidth = 0
        var maxHeight = 0
        var oldestDate = Long.MAX_VALUE
        var newestDate = 0L

        val sizeIndex = cursor.getColumnIndex(MediaStore.Images.Media.SIZE)
        val widthIndex = cursor.getColumnIndex(MediaStore.Images.Media.WIDTH)
        val heightIndex = cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT)
        val dateIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN)

        while (cursor.moveToNext()) {
            totalSize += cursor.getLong(sizeIndex)
            maxWidth = maxOf(maxWidth, cursor.getInt(widthIndex))
            maxHeight = maxOf(maxHeight, cursor.getInt(heightIndex))
            val dateTaken = cursor.getLong(dateIndex)
            oldestDate = minOf(oldestDate, dateTaken)
            newestDate = maxOf(newestDate, dateTaken)
        }

        return mapOf(
            "totalSize" to totalSize,
            "maxResolution" to "${maxWidth}x${maxHeight}",
            "oldestPhoto" to oldestDate,
            "newestPhoto" to newestDate
        )
    }

    private fun getVideoStats(cursor: Cursor): Map<String, Any> {
        var totalSize = 0L
        var totalDuration = 0L
        var maxDuration = 0L
        var oldestDate = Long.MAX_VALUE
        var newestDate = 0L

        val sizeIndex = cursor.getColumnIndex(MediaStore.Video.Media.SIZE)
        val durationIndex = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)
        val dateIndex = cursor.getColumnIndex(MediaStore.Video.Media.DATE_TAKEN)

        while (cursor.moveToNext()) {
            totalSize += cursor.getLong(sizeIndex)
            val duration = cursor.getLong(durationIndex)
            totalDuration += duration
            maxDuration = maxOf(maxDuration, duration)
            val dateTaken = cursor.getLong(dateIndex)
            oldestDate = minOf(oldestDate, dateTaken)
            newestDate = maxOf(newestDate, dateTaken)
        }

        return mapOf(
            "totalSize" to totalSize,
            "totalDuration" to totalDuration,
            "maxDuration" to maxDuration,
            "oldestVideo" to oldestDate,
            "newestVideo" to newestDate
        )
    }

    private fun getRecentMedia(): List<Map<String, Any>> {
        val media = mutableListOf<Map<String, Any>>()
        val contentResolver = context.contentResolver

        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATE_TAKEN,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT,
            MediaStore.MediaColumns.MIME_TYPE
        )

        val imageQuery = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            "${MediaStore.Images.Media.DATE_TAKEN} DESC"
        )

        val videoQuery = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            "${MediaStore.Video.Media.DATE_TAKEN} DESC"
        )

        imageQuery?.use { cursor ->
            while (cursor.moveToNext()) {
                media.add(getMediaInfo(cursor, "image"))
            }
        }

        videoQuery?.use { cursor ->
            while (cursor.moveToNext()) {
                media.add(getMediaInfo(cursor, "video"))
            }
        }

        return media.sortedByDescending { it["dateTaken"] as Long }
    }

    private fun getMediaInfo(cursor: Cursor, type: String): Map<String, Any> {
        return mapOf(
            "id" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)),
            "name" to cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)),
            "dateTaken" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_TAKEN)),
            "size" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)),
            "width" to cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)),
            "height" to cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)),
            "mimeType" to cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)),
            "type" to type
        )
    }

    private fun getAvailableStorage(): Long {
        val path = Environment.getExternalStorageDirectory()
        val stat = StatFs(path.path)
        return stat.availableBlocksLong * stat.blockSizeLong
    }

    private fun getMaxFileSize(): Long {
        return Environment.getExternalStorageDirectory().freeSpace
    }
}
