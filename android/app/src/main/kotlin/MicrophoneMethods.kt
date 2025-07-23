package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MicrophoneMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/microphone"
    }

    fun handleMicrophoneMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getMicrophoneInfo" -> {
                if (!hasMicrophonePermissions()) {
                    result.error("PERMISSION_DENIED", "Microphone permissions not granted", null)
                    return
                }

                try {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val info = mutableMapOf<String, Any>()

                    info["isMicrophonePresent"] = context.packageManager.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)
                    info["isInputMuted"] = audioManager.isMicrophoneMute
                    info["inputVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
                    info["maxInputVolume"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)

                    info["currentMode"] = when(audioManager.mode) {
                        AudioManager.MODE_NORMAL -> "NORMAL"
                        AudioManager.MODE_RINGTONE -> "RINGTONE"
                        AudioManager.MODE_IN_CALL -> "IN_CALL"
                        AudioManager.MODE_IN_COMMUNICATION -> "IN_COMMUNICATION"
                        else -> "UNKNOWN"
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val devices = mutableListOf<Map<String, Any>>()
                        audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS).forEach { device ->
                            devices.add(mapOf(
                                "type" to device.type,
                                "name" to device.productName.toString(),
                                "address" to device.address,
                                "isSourceAssociated" to device.isSource
                            ))
                        }
                        info["inputDevices"] = devices
                    }

                    info["isSpeakerphoneOn"] = audioManager.isSpeakerphoneOn
                    info["isBluetoothScoOn"] = audioManager.isBluetoothScoOn
                    info["isWiredHeadsetOn"] = audioManager.isWiredHeadsetOn

                    info["properties"] = mapOf(
                        "sampleRate" to 44100,
                        "channelCount" to 1,
                        "encoding" to "PCM_16BIT"
                    )

                    result.success(info)
                } catch (e: Exception) {
                    result.error("AUDIO_ERROR", "Failed to get microphone info: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun hasMicrophonePermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
