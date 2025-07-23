package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class CameraMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/camera"
    }

    fun handleCameraMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "checkCameraAvailability" -> checkCameraAvailability(result)
            "getCameraInfo" -> getCameraInfo(result)
            "getCameraPermissionStatus" -> getCameraPermissionStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun checkCameraAvailability(result: Result) {
        val hasCamera = context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        result.success(hasCamera)
    }

    private fun getCameraInfo(result: Result) {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraIds = cameraManager.cameraIdList

            val cameraInfo = mutableMapOf<String, Any>()
            val cameras = mutableListOf<Map<String, Any>>()

            var hasFlash = false
            var hasFrontCamera = false
            var hasBackCamera = false
            var hasExternalCamera = false

            for (cameraId in cameraIds) {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val cameraData = mutableMapOf<String, Any>()


                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
                val facingString = when (lensFacing) {
                    CameraCharacteristics.LENS_FACING_FRONT -> {
                        hasFrontCamera = true
                        "FRONT"
                    }
                    CameraCharacteristics.LENS_FACING_BACK -> {
                        hasBackCamera = true
                        "BACK"
                    }
                    CameraCharacteristics.LENS_FACING_EXTERNAL -> {
                        hasExternalCamera = true
                        "EXTERNAL"
                    }
                    else -> "UNKNOWN"
                }


                val hasFlashUnit = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                if (hasFlashUnit) hasFlash = true


                val resolution = characteristics.get(CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE)
                val maxResolution = mapOf(
                    "width" to (resolution?.width ?: 0),
                    "height" to (resolution?.height ?: 0)
                )


                val formats = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                val supportedFormats = formats?.outputFormats?.map { format ->
                    when (format) {
                        ImageFormat.JPEG -> "JPEG"
                        ImageFormat.RAW_SENSOR -> "RAW"
                        ImageFormat.YUV_420_888 -> "YUV"
                        else -> "FORMAT_$format"
                    }
                } ?: listOf()


                val afAvailable = characteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)?.size ?: 0 > 1


                val stabilizationModes = characteristics.get(CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES)
                val hasStabilization = stabilizationModes?.contains(1) ?: false


                val minFocusDistance = characteristics.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE) ?: 0f


                val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.toList() ?: listOf()

                cameraData.apply {
                    put("id", cameraId)
                    put("lensFacing", facingString)
                    put("flashAvailable", hasFlashUnit)
                    put("maxResolution", maxResolution)
                    put("supportedFormats", supportedFormats)
                    put("autoFocusAvailable", afAvailable)
                    put("stabilizationSupported", hasStabilization)
                    put("minimumFocusDistance", minFocusDistance)
                    put("focalLengths", focalLengths)
                }

                cameras.add(cameraData)
            }

            cameraInfo.apply {
                put("numberOfCameras", cameraIds.size)
                put("hasFlash", hasFlash)
                put("hasFrontCamera", hasFrontCamera)
                put("hasBackCamera", hasBackCamera)
                put("hasExternalCamera", hasExternalCamera)
                put("cameras", cameras)
            }

            result.success(cameraInfo)
        } catch (e: Exception) {
            result.error("CAMERA_ERROR", e.message, null)
        }
    }

    private fun getCameraPermissionStatus(result: Result) {
        val permission = android.Manifest.permission.CAMERA
        val status = context.checkSelfPermission(permission) == android.content.pm.PackageManager.PERMISSION_GRANTED
        result.success(status)
    }
}
