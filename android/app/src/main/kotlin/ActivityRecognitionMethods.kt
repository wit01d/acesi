package com.example.company_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityRecognitionClient
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionEvent
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.Manifest
import com.google.android.gms.tasks.Task
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class ActivityRecognitionMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/activity_recognition"
        private const val PERMISSION_REQUEST_CODE = 12345

        internal const val ACTIVITY_UPDATES_ACTION = "com.example.company_app.ACTIVITY_UPDATES"
        internal const val ACTIVITY_TRANSITION_ACTION = "com.example.company_app.ACTIVITY_TRANSITION"
    }

    private var activity: Activity? = null
    private lateinit var methodChannel: MethodChannel
    private var activityRecognitionClient: ActivityRecognitionClient? = null
    private var activityUpdatesPendingIntent: PendingIntent? = null
    private var transitionUpdatesPendingIntent: PendingIntent? = null
    private var isReceiverRegistered = false

    private val activityReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTIVITY_UPDATES_ACTION) {
                handleActivityUpdates(intent)
            }
        }
    }

    private val transitionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTIVITY_TRANSITION_ACTION) {
                handleTransitionUpdates(intent)
            }
        }
    }

    fun setActivity(activity: Activity, engine: FlutterEngine) {
        this.activity = activity
        activityRecognitionClient = ActivityRecognition.getClient(context)


        methodChannel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        setupPendingIntents()
        registerReceivers()
    }

    fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startActivityRecognition" -> handleStartActivityRecognition(result)
            "stopActivityRecognition" -> handleStopActivityRecognition(result)
            "startActivityTransitionUpdates" -> handleStartTransitionUpdates(result)
            "stopActivityTransitionUpdates" -> handleStopTransitionUpdates(result)
            else -> result.notImplemented()
        }
    }

    private fun setupPendingIntents() {

        val flags = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> {

                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {

                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            }
            else -> {

                PendingIntent.FLAG_UPDATE_CURRENT
            }
        }


        val activityIntent = Intent(context, ActivityRecognitionReceiver::class.java).apply {
            action = ACTIVITY_UPDATES_ACTION
            setPackage(context.packageName)
        }

        val transitionIntent = Intent(context, ActivityRecognitionReceiver::class.java).apply {
            action = ACTIVITY_TRANSITION_ACTION
            setPackage(context.packageName)
        }

        activityUpdatesPendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            activityIntent,
            flags
        )

        transitionUpdatesPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            transitionIntent,
            flags
        )
    }

    private fun registerReceivers() {
        if (!isReceiverRegistered) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {

                    val receiverFlags = Context.RECEIVER_NOT_EXPORTED
                    context.registerReceiver(
                        activityReceiver,
                        IntentFilter(ACTIVITY_UPDATES_ACTION),
                        receiverFlags
                    )
                    context.registerReceiver(
                        transitionReceiver,
                        IntentFilter(ACTIVITY_TRANSITION_ACTION),
                        receiverFlags
                    )
                } else {

                    context.registerReceiver(activityReceiver, IntentFilter(ACTIVITY_UPDATES_ACTION))
                    context.registerReceiver(transitionReceiver, IntentFilter(ACTIVITY_TRANSITION_ACTION))
                }
                isReceiverRegistered = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    internal fun handleActivityUpdates(intent: Intent) {
        if (com.google.android.gms.location.ActivityRecognitionResult.hasResult(intent)) {
            val result = com.google.android.gms.location.ActivityRecognitionResult.extractResult(intent)
            val activities = JSONArray()

            result?.probableActivities?.forEach { activity ->
                activities.put(JSONObject().apply {
                    put("type", getActivityName(activity.type))
                    put("confidence", activity.confidence)
                })
            }

            activity?.runOnUiThread {
                methodChannel.invokeMethod("onActivityDetected", activities.toString())
            }
        }
    }

    internal fun handleTransitionUpdates(intent: Intent) {
        val result = ActivityTransitionResult.extractResult(intent)
        val transitions = JSONArray()

        result?.transitionEvents?.forEach { event ->
            transitions.put(JSONObject().apply {
                put("from", getActivityName(event.activityType))
                put("to", getTransitionName(event.transitionType))
            })
        }

        activity?.runOnUiThread {
            methodChannel.invokeMethod("onActivityTransition", transitions.toString())
        }
    }

    private fun handleStartActivityRecognition(result: MethodChannel.Result) {
        if (!hasPermission()) {
            result.error("PERMISSION_DENIED", "Activity recognition permission not granted", null)
            return
        }

        val pendingIntent = activityUpdatesPendingIntent
        if (pendingIntent == null) {
            result.error("PENDING_INTENT_ERROR", "Failed to create pending intent", null)
            return
        }

        activityRecognitionClient?.requestActivityUpdates(
            0,
            pendingIntent
        )?.addOnSuccessListener {
            result.success(true)
        }?.addOnFailureListener { e ->
            result.error("ACTIVITY_RECOGNITION_ERROR", e.message, null)
        }
    }

    private fun handleStopActivityRecognition(result: MethodChannel.Result) {
        val pendingIntent = activityUpdatesPendingIntent
        if (pendingIntent == null) {
            result.error("PENDING_INTENT_ERROR", "No active pending intent", null)
            return
        }

        activityRecognitionClient?.removeActivityUpdates(pendingIntent)
            ?.addOnSuccessListener {
                result.success(true)
            }?.addOnFailureListener { e ->
                result.error("ACTIVITY_RECOGNITION_ERROR", e.message, null)
            }
    }

    private fun handleStartTransitionUpdates(result: MethodChannel.Result) {
        if (!hasPermission()) {
            result.error("PERMISSION_DENIED", "Activity recognition permission not granted", null)
            return
        }

        val pendingIntent = transitionUpdatesPendingIntent
        if (pendingIntent == null) {
            result.error("PENDING_INTENT_ERROR", "Failed to create pending intent", null)
            return
        }

        val transitions = getTransitionList()
        val request = ActivityTransitionRequest(transitions)

        activityRecognitionClient?.requestActivityTransitionUpdates(
            request,
            pendingIntent
        )?.addOnSuccessListener {
            result.success(true)
        }?.addOnFailureListener { e ->
            result.error("TRANSITION_UPDATES_ERROR", e.message, null)
        }
    }

    private fun handleStopTransitionUpdates(result: MethodChannel.Result) {
        val pendingIntent = transitionUpdatesPendingIntent
        if (pendingIntent == null) {
            result.error("PENDING_INTENT_ERROR", "No active pending intent", null)
            return
        }

        activityRecognitionClient?.removeActivityTransitionUpdates(pendingIntent)
            ?.addOnSuccessListener {
                result.success(true)
            }?.addOnFailureListener { e ->
                result.error("TRANSITION_UPDATES_ERROR", e.message, null)
            }
    }

    private fun getTransitionList(): List<ActivityTransition> = listOf(
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.STILL)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.WALKING)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.RUNNING)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.IN_VEHICLE)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build()
    )

    private fun hasPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun getActivityName(type: Int): String = when (type) {
        DetectedActivity.STILL -> "STILL"
        DetectedActivity.WALKING -> "WALKING"
        DetectedActivity.RUNNING -> "RUNNING"
        DetectedActivity.IN_VEHICLE -> "IN_VEHICLE"
        DetectedActivity.ON_BICYCLE -> "ON_BICYCLE"
        DetectedActivity.ON_FOOT -> "ON_FOOT"
        DetectedActivity.TILTING -> "TILTING"
        DetectedActivity.UNKNOWN -> "UNKNOWN"
        else -> "UNKNOWN"
    }

    private fun getTransitionName(transition: Int): String = when (transition) {
        ActivityTransition.ACTIVITY_TRANSITION_ENTER -> "ENTER"
        ActivityTransition.ACTIVITY_TRANSITION_EXIT -> "EXIT"
        else -> "UNKNOWN"
    }

    fun cleanup() {
        if (isReceiverRegistered) {
            try {
                context.unregisterReceiver(activityReceiver)
                context.unregisterReceiver(transitionReceiver)
                isReceiverRegistered = false
            } catch (e: Exception) {

                e.printStackTrace()
            }
        }
    }
}


class ActivityRecognitionReceiver : BroadcastReceiver() {
    companion object {
        private var methodInstance: ActivityRecognitionMethods? = null

        fun setMethodInstance(instance: ActivityRecognitionMethods) {
            methodInstance = instance
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {

        when (intent?.action) {
            ActivityRecognitionMethods.ACTIVITY_UPDATES_ACTION ->
                methodInstance?.handleActivityUpdates(intent)
            ActivityRecognitionMethods.ACTIVITY_TRANSITION_ACTION ->
                methodInstance?.handleTransitionUpdates(intent)
        }
    }
}
