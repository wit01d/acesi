package com.example.company_app

import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.json.JSONArray

class NotificationMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/notifications"
    }

    private val notificationManager: NotificationManager
        get() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNotificationSettings" -> getNotificationSettings(result)
            "getActiveNotifications" -> getActiveNotifications(result)
            "getNotificationChannels" -> getNotificationChannels(result)
            else -> result.notImplemented()
        }
    }

    private fun getNotificationSettings(result: MethodChannel.Result) {
        try {
            val settings = JSONObject().apply {
                put("areNotificationsEnabled", notificationManager.areNotificationsEnabled())

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channels = notificationManager.notificationChannels
                    put("totalChannels", channels.size)
                    put("totalChannelGroups", notificationManager.notificationChannelGroups.size)
                }

                put("importance", notificationManager.importance)
                put("isNotificationPolicyAccessGranted",
                    notificationManager.isNotificationPolicyAccessGranted)
            }

            result.success(settings.toString())
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to get notification settings", e.message)
        }
    }

    private fun getActiveNotifications(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val notifications = notificationManager.activeNotifications
                val notificationList = JSONObject().apply {
                    put("count", notifications.size)
                    put("notifications", notifications.map { notification ->
                        JSONObject().apply {
                            put("id", notification.id)
                            put("packageName", notification.packageName)
                            put("tag", notification.tag)
                            put("postTime", notification.postTime)
                            put("groupKey", notification.groupKey)
                        }
                    })
                }
                result.success(notificationList.toString())
            } else {
                result.error("VERSION_ERROR", "API level 23 or higher required", null)
            }
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to get active notifications", e.message)
        }
    }

    private fun getNotificationChannels(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channels = notificationManager.notificationChannels
                val channelsArray = JSONArray()
                channels.forEach { channel ->
                    channelsArray.put(JSONObject().apply {
                        put("id", channel.id)
                        put("name", channel.name)
                        put("importance", channel.importance)
                        put("description", channel.description)
                        put("group", channel.group)
                        put("isBlockable", channel.isBlockable)
                        put("isBypassDnd", channel.canBypassDnd())
                        put("sound", channel.sound?.toString())
                        put("vibrationEnabled", channel.shouldVibrate())
                    })
                }
                val response = JSONObject()
                response.put("channels", channelsArray)
                result.success(response.toString())
            } else {

                val response = JSONObject()
                response.put("channels", JSONArray())
                result.success(response.toString())
            }
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to get notification channels", e.message)
        }
    }
}
