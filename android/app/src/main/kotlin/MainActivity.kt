package com.example.company_app
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.company_app.NetworkMethods
import com.example.company_app.SMSMethods
import com.example.company_app.ContactsMethods
import com.example.company_app.CalendarMethods
import com.example.company_app.LocationMethods
import com.example.company_app.NotificationMethods
import android.content.Context
import android.telephony.TelephonyManager
import android.os.Build
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.pm.PackageManager
import android.telephony.SmsManager
import android.provider.Telephony
import android.net.Uri
import android.provider.ContactsContract
import android.provider.MediaStore
import android.database.Cursor
import android.os.Environment
import android.os.StatFs
import android.content.res.Configuration
import android.widget.LinearLayout
import android.media.AudioManager
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraCharacteristics
import android.graphics.ImageFormat
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.OnBackPressedDispatcher

import com.example.company_app.R

class MainActivity: FlutterActivity() {
    private lateinit var activityRecognitionMethods: ActivityRecognitionMethods
    private lateinit var connectAccessibility: ConnectAssessibility
        companion object {
        private const val BACK_CHANNEL = "com.example.company_app/back_navigation"
    }
    private lateinit var backMethodChannel: MethodChannel
    private var currentBackCallback: OnBackInvokedCallback? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
                MatrixPowerMethodChannel.registerWith(flutterEngine, applicationContext)
                backMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_CHANNEL)
        setupBackHandling()

        val networkMethods = NetworkMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NetworkMethods.CHANNEL).setMethodCallHandler { call, result ->
            networkMethods.handleNetworkMethod(call, result)
        }
                val smsMethods = SMSMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMSMethods.CHANNEL).setMethodCallHandler { call, result ->
            smsMethods.handleMethod(call, result)
        }
                val contactsMethods = ContactsMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ContactsMethods.CHANNEL).setMethodCallHandler { call, result ->
            contactsMethods.handleContactMethod(call, result)
        }
                val microphoneMethods = MicrophoneMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MicrophoneMethods.CHANNEL).setMethodCallHandler { call, result ->
            microphoneMethods.handleMicrophoneMethod(call, result)
        }
                val callHistoryMethods = CallHistoryMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CallHistoryMethods.CHANNEL).setMethodCallHandler { call, result ->
            callHistoryMethods.handleCallHistoryMethod(call, result)
        }
                val mediaMethods = MediaMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MediaMethods.CHANNEL).setMethodCallHandler { call, result ->
            mediaMethods.handleMediaMethod(call, result)
        }
                val cameraMethods = CameraMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CameraMethods.CHANNEL).setMethodCallHandler { call, result ->
            cameraMethods.handleCameraMethod(call, result)
        }
                val bluetoothMethods = BluetoothMethods(context).apply {setActivity(this@MainActivity)}
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BluetoothMethods.CHANNEL).setMethodCallHandler { call, result ->
            bluetoothMethods.handleBluetoothMethod(call, result)
        }

        val calendarMethods = CalendarMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CalendarMethods.CHANNEL).setMethodCallHandler { call, result ->
            calendarMethods.handleCalendarMethod(call, result)
        }

        val audioMethods = AudioMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AudioMethods.CHANNEL).setMethodCallHandler { call, result ->
            audioMethods.handleAudioMethod(call, result)
        }

        val locationMethods = LocationMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LocationMethods.CHANNEL).setMethodCallHandler { call, result ->
            locationMethods.handleLocationMethod(call, result)
        }
        activityRecognitionMethods = ActivityRecognitionMethods(this)
        activityRecognitionMethods.setActivity(this, flutterEngine)
        ActivityRecognitionReceiver.setMethodInstance(activityRecognitionMethods)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,ActivityRecognitionMethods.CHANNEL).setMethodCallHandler { call, result ->
            activityRecognitionMethods.handleMethod(call, result)
        }

        val sensorMethods = SensorMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SensorMethods.CHANNEL).setMethodCallHandler { call, result ->
            sensorMethods.handleSensorMethod(call, result)
        }

        val notificationMethods = NotificationMethods(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NotificationMethods.CHANNEL).setMethodCallHandler { call, result ->
            notificationMethods.handleMethod(call, result)
        }

        connectAccessibility = ConnectAssessibility(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ConnectAssessibility.CHANNEL).setMethodCallHandler { call, result ->
            connectAccessibility.handleMethod(call, result)
        }
    }

    private fun setupBackHandling() {

        if (Build.VERSION.SDK_INT >= 33) {
            val callback = OnBackInvokedCallback {

                backMethodChannel.invokeMethod("onBackPressed", null)
            }
                        currentBackCallback = callback
                        onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                callback
            )
        } else {

            val callback = object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    backMethodChannel.invokeMethod("onBackPressed", null)
                }
            }

            (this as ComponentActivity).onBackPressedDispatcher.addCallback(this, callback)
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        findViewById<LinearLayout>(R.id.main_layout)?.let { layout ->
            layout.orientation = if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
                LinearLayout.HORIZONTAL
            } else {
                LinearLayout.VERTICAL
            }
        }
    }

    override fun onDestroy() {

        if (Build.VERSION.SDK_INT >= 33) {
            currentBackCallback?.let { callback ->
                onBackInvokedDispatcher.unregisterOnBackInvokedCallback(callback)
            }
        }

        activityRecognitionMethods.cleanup()
        connectAccessibility.cleanup()
        super.onDestroy()
    }
}

