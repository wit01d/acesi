package com.example.company_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class LocationMethods(private val context: Context) {
    private val fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private val locationManager: LocationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var locationCallback: LocationCallback? = null
    private var eventSink: EventSink? = null

    companion object {
        const val CHANNEL = "com.example.company_app/location"
        private const val DEFAULT_INTERVAL = 1000L
    }

    fun handleLocationMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentPosition" -> getCurrentPosition(result)
            "startLocationUpdates" -> {
                val interval = call.argument<Long>("interval") ?: DEFAULT_INTERVAL
                startLocationUpdates(interval, result)
            }
            "stopLocationUpdates" -> {
                stopLocationUpdates()
                result.success(null)
            }
            "getLocationStatus" -> result.success(getLocationStatus())
            else -> result.notImplemented()
        }
    }

    private fun getCurrentPosition(result: MethodChannel.Result) {
        if (!checkPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location ->
                    if (location != null) {
                        result.success(mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "accuracy" to location.accuracy,
                            "speed" to location.speed,
                            "bearing" to location.bearing,
                            "timestamp" to location.time
                        ))
                    } else {
                        result.error("LOCATION_UNAVAILABLE", "Location not available", null)
                    }
                }
                .addOnFailureListener { e ->
                    result.error("LOCATION_ERROR", e.message, null)
                }
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", e.message, null)
        }
    }

    private fun startLocationUpdates(interval: Long, result: MethodChannel.Result) {
        if (!checkPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            val locationRequest = LocationRequest.Builder(interval)
                .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                .setMinUpdateIntervalMillis(interval / 2)
                .build()

            locationCallback = object : LocationCallback() {
                override fun onLocationResult(locationResult: LocationResult) {
                    locationResult.lastLocation?.let { location ->
                        result.success(mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "accuracy" to location.accuracy,
                            "speed" to location.speed,
                            "bearing" to location.bearing,
                            "timestamp" to location.time
                        ))
                    }
                }
            }

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback!!,
                Looper.getMainLooper()
            )
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", e.message, null)
        }
    }

    fun stopLocationUpdates() {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
            locationCallback = null
        }
    }

    fun isLocationEnabled(): Boolean {
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    fun getBestProvider(): String {
        val criteria = android.location.Criteria().apply {
            accuracy = android.location.Criteria.ACCURACY_FINE
            isAltitudeRequired = false
            isBearingRequired = false
            isCostAllowed = true
            powerRequirement = android.location.Criteria.POWER_LOW
        }

        return locationManager.getBestProvider(criteria, true) ?: LocationManager.GPS_PROVIDER
    }

    private fun getLocationStatus(): Map<String, Any> {
        return mapOf(
            "locationEnabled" to isLocationEnabled(),
            "gpsAvailable" to locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER),
            "networkLocationAvailable" to locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER),
            "bestProvider" to getBestProvider(),
            "accuracyMode" to if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) "high" else "balanced",
            "updateInterval" to DEFAULT_INTERVAL
        )
    }

    private fun checkPermission(): Boolean {
        return (ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED)
    }
}
