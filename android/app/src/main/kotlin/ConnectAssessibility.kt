package com.example.company_app

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import android.util.Log

class ConnectAssessibility(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/accessibility"
        private const val TAG = "SRS"
    }

    private val accessibilityManager: AccessibilityManager? by lazy {
        context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
    }

    fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityServiceEnabled" -> {
                result.success(isAccessibilityServiceEnabled())
            }
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(null)
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        val serviceName = "${context.packageName}/${AccessorService::class.java.name}"
        return enabledServices?.contains(serviceName) == true
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun cleanup() {
        Log.d(TAG, "Cleaning up screen reader methods")
    }
}
