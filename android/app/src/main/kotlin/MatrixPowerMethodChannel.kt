package com.example.company_app

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MatrixPowerMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.example.matrix_animation/power"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            val instance = MatrixPowerMethodChannel(context)
            channel.setMethodCallHandler(instance)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getBatteryLevel" -> {
                val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) / 100f
                result.success(batteryLevel)
            }
            "isLowPowerMode" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    result.success(powerManager.isPowerSaveMode)
                } else {
                    result.success(false)
                }
            }
            "getThermalState" -> {

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                    val thermalState = when (powerManager.currentThermalStatus) {
                        PowerManager.THERMAL_STATUS_NONE -> 0
                        PowerManager.THERMAL_STATUS_LIGHT -> 1
                        PowerManager.THERMAL_STATUS_MODERATE -> 2
                        PowerManager.THERMAL_STATUS_SEVERE -> 3
                        PowerManager.THERMAL_STATUS_CRITICAL -> 3
                        PowerManager.THERMAL_STATUS_EMERGENCY -> 3
                        PowerManager.THERMAL_STATUS_SHUTDOWN -> 3
                        else -> 0
                    }
                    result.success(thermalState)
                } else {

                    result.success(0)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
