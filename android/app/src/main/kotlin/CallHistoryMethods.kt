package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CallLog
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class CallHistoryMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/callhistory"
    }

    fun handleCallHistoryMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getCallHistory" -> {
                if (!hasCallLogPermissions()) {
                    result.error("PERMISSION_DENIED", "Call log permissions not granted", null)
                    return
                }

                try {
                    val calls = mutableListOf<Map<String, Any>>()
                    val cursor = context.contentResolver.query(
                        CallLog.Calls.CONTENT_URI,
                        arrayOf(
                            CallLog.Calls._ID,
                            CallLog.Calls.NUMBER,
                            CallLog.Calls.TYPE,
                            CallLog.Calls.DATE,
                            CallLog.Calls.DURATION,
                            CallLog.Calls.CACHED_NAME
                        ),
                        null,
                        null,
                        "${CallLog.Calls.DATE} DESC"
                    )

                    cursor?.use {
                        while (it.moveToNext()) {
                            calls.add(mapOf(
                                "id" to it.getLong(0),
                                "number" to (it.getString(1) ?: ""),
                                "type" to when(it.getInt(2)) {
                                    CallLog.Calls.INCOMING_TYPE -> "INCOMING"
                                    CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
                                    CallLog.Calls.MISSED_TYPE -> "MISSED"
                                    CallLog.Calls.REJECTED_TYPE -> "REJECTED"
                                    else -> "UNKNOWN"
                                },
                                "timestamp" to it.getLong(3),
                                "duration" to it.getLong(4),
                                "name" to (it.getString(5) ?: "")
                            ))
                        }
                    }
                    result.success(calls)
                } catch (e: Exception) {
                    result.error("CALL_LOG_ERROR", "Failed to get call history: ${e.message}", null)
                }
            }

            "getCallStats" -> {
                if (!hasCallLogPermissions()) {
                    result.error("PERMISSION_DENIED", "Call log permissions not granted", null)
                    return
                }

                try {
                    val stats = mutableMapOf<String, Any>()
                    val cursor = context.contentResolver.query(
                        CallLog.Calls.CONTENT_URI,
                        arrayOf(
                            "COUNT(*) AS total",
                            "SUM(CASE WHEN ${CallLog.Calls.TYPE} = ${CallLog.Calls.INCOMING_TYPE} THEN 1 ELSE 0 END) as incoming",
                            "SUM(CASE WHEN ${CallLog.Calls.TYPE} = ${CallLog.Calls.OUTGOING_TYPE} THEN 1 ELSE 0 END) as outgoing",
                            "SUM(CASE WHEN ${CallLog.Calls.TYPE} = ${CallLog.Calls.MISSED_TYPE} THEN 1 ELSE 0 END) as missed",
                            "SUM(${CallLog.Calls.DURATION}) as totalDuration",
                            "MAX(${CallLog.Calls.DATE}) as lastCallDate"
                        ),
                        null,
                        null,
                        null
                    )

                    cursor?.use {
                        if (it.moveToFirst()) {
                            stats["totalCalls"] = it.getInt(0)
                            stats["incomingCalls"] = it.getInt(1)
                            stats["outgoingCalls"] = it.getInt(2)
                            stats["missedCalls"] = it.getInt(3)
                            stats["totalDuration"] = it.getLong(4)
                            stats["lastCallDate"] = it.getLong(5)
                        }
                    }

                    result.success(stats)
                } catch (e: Exception) {
                    result.error("CALL_LOG_ERROR", "Failed to get call statistics: ${e.message}", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun hasCallLogPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
