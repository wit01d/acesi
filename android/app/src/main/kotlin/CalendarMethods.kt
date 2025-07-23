package com.example.company_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class CalendarMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/calendar"
    }

    private fun hasCalendarPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun handleCalendarMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getCalendars" -> handleGetCalendars(result)
            "getEvents" -> handleGetEvents(call, result)
            "getCalendarStats" -> handleGetCalendarStats(result)
            "searchEvents" -> handleSearchEvents(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetCalendars(result: Result) {
        if (!hasCalendarPermissions()) {
            result.error("PERMISSION_DENIED", "Calendar permissions not granted", null)
            return
        }

        try {
            val calendars = mutableListOf<Map<String, Any>>()
            val projection = arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.CALENDAR_COLOR,
                CalendarContract.Calendars.VISIBLE,
                CalendarContract.Calendars.SYNC_EVENTS
            )

            context.contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                projection,
                null,
                null,
                null
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    calendars.add(mapOf(
                        "id" to cursor.getLong(0),
                        "displayName" to (cursor.getString(1) ?: ""),
                        "accountName" to (cursor.getString(2) ?: ""),
                        "color" to cursor.getInt(3),
                        "visible" to (cursor.getInt(4) == 1),
                        "syncEvents" to (cursor.getInt(5) == 1)
                    ))
                }
            }
            result.success(calendars)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to query calendars: ${e.message}", null)
        }
    }

    private fun handleGetEvents(call: MethodCall, result: Result) {
        if (!hasCalendarPermissions()) {
            result.error("PERMISSION_DENIED", "Calendar permissions not granted", null)
            return
        }

        try {
            val startDate = call.argument<Long>("startDate") ?: System.currentTimeMillis()
            val endDate = call.argument<Long>("endDate") ?: (System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000)
            val calendarId = call.argument<Long>("calendarId")

            val events = mutableListOf<Map<String, Any>>()
            val projection = arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.DTEND,
                CalendarContract.Events.EVENT_LOCATION,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.CALENDAR_ID
            )

            val selection = StringBuilder().apply {
                append("${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ?")
                if (calendarId != null) {
                    append(" AND ${CalendarContract.Events.CALENDAR_ID} = ?")
                }
            }

            val selectionArgs = if (calendarId != null) {
                arrayOf(startDate.toString(), endDate.toString(), calendarId.toString())
            } else {
                arrayOf(startDate.toString(), endDate.toString())
            }

            context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                projection,
                selection.toString(),
                selectionArgs,
                "${CalendarContract.Events.DTSTART} ASC"
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    events.add(mapOf(
                        "id" to cursor.getLong(0),
                        "title" to (cursor.getString(1) ?: ""),
                        "description" to (cursor.getString(2) ?: ""),
                        "startDate" to cursor.getLong(3),
                        "endDate" to cursor.getLong(4),
                        "location" to (cursor.getString(5) ?: ""),
                        "isAllDay" to (cursor.getInt(6) == 1),
                        "calendarId" to cursor.getLong(7)
                    ))
                }
            }
            result.success(events)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to query events: ${e.message}", null)
        }
    }

    private fun handleSearchEvents(call: MethodCall, result: Result) {
        if (!hasCalendarPermissions()) {
            result.error("PERMISSION_DENIED", "Calendar permissions not granted", null)
            return
        }

        try {
            val query = call.argument<String>("query") ?: ""
            val events = mutableListOf<Map<String, Any>>()

            context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                null,
                "${CalendarContract.Events.TITLE} LIKE ? OR ${CalendarContract.Events.DESCRIPTION} LIKE ?",
                arrayOf("%$query%", "%$query%"),
                "${CalendarContract.Events.DTSTART} ASC"
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    events.add(mapOf(
                        "id" to cursor.getLong(cursor.getColumnIndex(CalendarContract.Events._ID)),
                        "title" to (cursor.getString(cursor.getColumnIndex(CalendarContract.Events.TITLE)) ?: ""),
                        "startDate" to cursor.getLong(cursor.getColumnIndex(CalendarContract.Events.DTSTART)),
                        "endDate" to cursor.getLong(cursor.getColumnIndex(CalendarContract.Events.DTEND)),
                        "location" to (cursor.getString(cursor.getColumnIndex(CalendarContract.Events.EVENT_LOCATION)) ?: "")
                    ))
                }
            }
            result.success(events)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to search events: ${e.message}", null)
        }
    }

    private fun handleGetCalendarStats(result: Result) {
        if (!hasCalendarPermissions()) {
            result.error("PERMISSION_DENIED", "Calendar permissions not granted", null)
            return
        }

        try {
            val stats = mutableMapOf<String, Any>()
            val now = System.currentTimeMillis()
            val thirtyDaysAgo = now - (30L * 24 * 60 * 60 * 1000)
            val thirtyDaysAhead = now + (30L * 24 * 60 * 60 * 1000)


            context.contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                arrayOf(CalendarContract.Calendars._ID),
                null,
                null,
                null
            )?.use { cursor ->
                stats["totalCalendars"] = cursor.count
            }


            context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                arrayOf(CalendarContract.Events._ID),
                "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ?",
                arrayOf(now.toString(), thirtyDaysAhead.toString()),
                null
            )?.use { cursor ->
                stats["upcomingEvents"] = cursor.count
            }


            context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                arrayOf(CalendarContract.Events._ID),
                "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ?",
                arrayOf(thirtyDaysAgo.toString(), now.toString()),
                null
            )?.use { cursor ->
                stats["recentEvents"] = cursor.count
            }

            result.success(stats)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to get calendar stats: ${e.message}", null)
        }
    }
}
