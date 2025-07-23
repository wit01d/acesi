package com.example.company_app

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class AudioMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/audio"
    }

    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    fun handleAudioMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getAudioDeviceInfo" -> getAudioDeviceInfo(result)
            "getAudioRouting" -> getAudioRouting(result)
            "getAudioFocusInfo" -> getAudioFocusInfo(result)
            "getAudioSessionInfo" -> getAudioSessionInfo(result)
            "getAvailableAudioDevices" -> getAvailableAudioDevices(result)
            else -> result.notImplemented()
        }
    }

    private fun getAudioDeviceInfo(result: Result) {
        try {
            val info = mutableMapOf<String, Any>()
            info["maxVolume"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            info["currentVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            info["isMusicActive"] = audioManager.isMusicActive
            info["isWiredHeadsetOn"] = audioManager.isWiredHeadsetOn
            info["isSpeakerphoneOn"] = audioManager.isSpeakerphoneOn
            info["isBluetoothScoOn"] = audioManager.isBluetoothScoOn
            info["mode"] = when (audioManager.mode) {
                AudioManager.MODE_NORMAL -> "NORMAL"
                AudioManager.MODE_RINGTONE -> "RINGTONE"
                AudioManager.MODE_IN_CALL -> "IN_CALL"
                AudioManager.MODE_IN_COMMUNICATION -> "IN_COMMUNICATION"
                else -> "UNKNOWN"
            }
            result.success(info)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    private fun getAudioRouting(result: Result) {
        try {
            val routing = mutableMapOf<String, Any>()
            routing["isSpeakerphoneOn"] = audioManager.isSpeakerphoneOn
            routing["isBluetoothA2dpOn"] = audioManager.isBluetoothA2dpOn
            routing["isBluetoothScoOn"] = audioManager.isBluetoothScoOn
            routing["isWiredHeadsetOn"] = audioManager.isWiredHeadsetOn
            result.success(routing)
        } catch (e: Exception) {
            result.error("ROUTING_ERROR", e.message, null)
        }
    }

    private fun getAudioFocusInfo(result: Result) {
        try {
            val focusInfo = mutableMapOf<String, Any>()
            focusInfo["isMusicActive"] = audioManager.isMusicActive
            focusInfo["mode"] = audioManager.mode
            focusInfo["ringerMode"] = audioManager.ringerMode
            result.success(focusInfo)
        } catch (e: Exception) {
            result.error("FOCUS_ERROR", e.message, null)
        }
    }

    private fun getAudioSessionInfo(result: Result) {
        try {
            val sessionInfo = mutableMapOf<String, Any>()
            sessionInfo["streamVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            sessionInfo["streamMaxVolume"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            sessionInfo["isStreamMute"] = audioManager.isStreamMute(AudioManager.STREAM_MUSIC)
            result.success(sessionInfo)
        } catch (e: Exception) {
            result.error("SESSION_ERROR", e.message, null)
        }
    }

    private fun getAvailableAudioDevices(result: Result) {
        try {
            val devices = mutableListOf<Map<String, Any>>()
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_ALL)
                for (device in audioDevices) {
                    val deviceInfo = mutableMapOf<String, Any>()
                    deviceInfo["id"] = device.id
                    deviceInfo["productName"] = device.productName?.toString() ?: "Unknown"
                    deviceInfo["type"] = getDeviceTypeName(device.type)
                    deviceInfo["isSource"] = device.isSource
                    deviceInfo["isSink"] = device.isSink
                    devices.add(deviceInfo)
                }
            }
            result.success(devices)
        } catch (e: Exception) {
            result.error("DEVICES_ERROR", e.message, null)
        }
    }

    private fun getDeviceTypeName(type: Int): String {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "BUILTIN_SPEAKER"
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "BUILTIN_EARPIECE"
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> "WIRED_HEADSET"
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "WIRED_HEADPHONES"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "BLUETOOTH_SCO"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "BLUETOOTH_A2DP"
            AudioDeviceInfo.TYPE_USB_DEVICE -> "USB_DEVICE"
            AudioDeviceInfo.TYPE_USB_HEADSET -> "USB_HEADSET"
            else -> "UNKNOWN"
        }
    }
}
