package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NetworkMethods(private val context: Context) {
    fun handleNetworkMethod(call: MethodCall, result: MethodChannel.Result) {
                when (call.method) {
            "getNetworkInfo" -> {
                if (!hasRequiredPermissions()) {
                    result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                    return
                }

                try {
                    val info = mutableMapOf<String, Any>()
                    val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                    info["networkOperatorName"] = telephonyManager.networkOperatorName ?: ""
                    info["simOperatorName"] = telephonyManager.simOperatorName ?: ""
                    info["networkCountryIso"] = telephonyManager.networkCountryIso ?: ""
                    info["simCountryIso"] = telephonyManager.simCountryIso ?: ""
                    info["deviceSoftwareVersion"] = telephonyManager.deviceSoftwareVersion ?: ""
                    info["networkType"] = getNetworkType()
                    info["callState"] = when(telephonyManager.callState) {
                        TelephonyManager.CALL_STATE_IDLE -> "IDLE"
                        TelephonyManager.CALL_STATE_RINGING -> "RINGING"
                        TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
                        else -> "UNKNOWN"
                    }
                    info["simState"] = when(telephonyManager.simState) {
                        TelephonyManager.SIM_STATE_ABSENT -> "ABSENT"
                        TelephonyManager.SIM_STATE_READY -> "READY"
                        TelephonyManager.SIM_STATE_PIN_REQUIRED -> "PIN_REQUIRED"
                        TelephonyManager.SIM_STATE_PUK_REQUIRED -> "PUK_REQUIRED"
                        TelephonyManager.SIM_STATE_NETWORK_LOCKED -> "NETWORK_LOCKED"
                        else -> "UNKNOWN"
                    }

                    result.success(info)
            } catch (e: SecurityException) {
                result.error("PERMISSION_DENIED", "Security Exception: ${e.message}", null)
            } catch (e: Exception) {
                    result.error("ERROR", "Failed to get device info: ${e.message}", null)
            }
        }
            "getPhoneNumber" -> {
                try {
                    val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val phoneNumber = telephonyManager.line1Number
                    result.success(phoneNumber ?: "")
                } catch (e: SecurityException) {
                    result.error("PERMISSION_DENIED", "Phone permission not granted", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(android.Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(android.Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(android.Manifest.permission.ACCESS_NETWORK_STATE) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun getNetworkType(): String {
        if (!hasRequiredPermissions()) {
            return "PERMISSION_DENIED"
        }
        try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                return when {
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "WIFI"
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "CELLULAR"
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> "ETHERNET"
                    else -> "UNKNOWN"
                }
            }
        } catch (e: SecurityException) {
            return "PERMISSION_DENIED"
        }
        return "UNKNOWN"
    }

    companion object {
        const val CHANNEL = "com.example.company_app/networkinfo"
    }
}
