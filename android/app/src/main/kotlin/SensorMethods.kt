package com.example.company_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class SensorMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/sensors"
    }

    private val sensorManager: SensorManager by lazy {
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    }

    fun handleSensorMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSensorList" -> getSensorList(result)
            "getSensorDetails" -> getSensorDetails(call.argument("sensorType") ?: -1, result)
            else -> result.notImplemented()
        }
    }

    private fun getSensorList(result: MethodChannel.Result) {
        try {
            val sensorList = sensorManager.getSensorList(Sensor.TYPE_ALL)
            val sensorArray = JSONArray()

            sensorList.forEach { sensor ->
                val sensorJson = JSONObject().apply {
                    put("name", sensor.name)
                    put("type", sensor.type)
                    put("vendor", sensor.vendor)
                    put("version", sensor.version)
                    put("power", sensor.power)
                    put("maxRange", sensor.maximumRange)
                    put("resolution", sensor.resolution)
                    put("minDelay", sensor.minDelay)
                }
                sensorArray.put(sensorJson)
            }
            result.success(sensorArray.toString())
        } catch (e: Exception) {
            result.error("SENSOR_ERROR", "Failed to get sensor list", e.message)
        }
    }

    private fun getSensorDetails(sensorType: Int, result: MethodChannel.Result) {
        try {
            val sensor = sensorManager.getDefaultSensor(sensorType)
            if (sensor != null) {
                val sensorJson = JSONObject().apply {
                    put("name", sensor.name)
                    put("type", sensor.type)
                    put("vendor", sensor.vendor)
                    put("version", sensor.version)
                    put("power", sensor.power)
                    put("maxRange", sensor.maximumRange)
                    put("resolution", sensor.resolution)
                    put("minDelay", sensor.minDelay)
                    put("maxDelay", sensor.maxDelay)
                    put("reportingMode", sensor.reportingMode)
                    put("isWakeUpSensor", sensor.isWakeUpSensor)
                    put("isDynamicSensor", sensor.isDynamicSensor)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        put("id", sensor.id)
                    }
                }
                result.success(sensorJson.toString())
            } else {
                result.error("SENSOR_NOT_FOUND", "Sensor type $sensorType not found", null)
            }
        } catch (e: Exception) {
            result.error("SENSOR_ERROR", "Failed to get sensor details", e.message)
        }
    }
}
