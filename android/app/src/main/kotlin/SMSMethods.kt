package com.example.company_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SMSMethods(private val context: Context) : CoroutineScope {
    override val coroutineContext = Dispatchers.Main

    companion object {
        const val CHANNEL = "com.example.company_app/sms"
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.READ_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.RECEIVE_SMS
        )
    }

    fun handleMethod(call: MethodCall, result: Result) {
        if (!hasPermissions()) {
            result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
            return
        }

        when (call.method) {
            "getMessages" -> {
                val limit = call.argument<Int>("limit") ?: 50
                val offset = call.argument<Int>("offset") ?: 0
                handleGetMessages(limit, offset, result)
            }
            "searchMessages" -> {
                val query = call.argument<String>("query")
                val limit = call.argument<Int>("limit") ?: 20
                handleSearchMessages(query, limit, result)
            }
            "getSMSStats" -> handleGetSMSStats(result)
            "getMessageCounts" -> handleGetMessageCounts(result)
            "getPaginatedMessages" -> {
                val type = call.argument<String>("type")
                val page = call.argument<Int>("page") ?: 0
                val pageSize = call.argument<Int>("pageSize") ?: 50
                handleGetPaginatedMessages(type, page, pageSize, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleGetMessages(limit: Int, offset: Int, result: Result) {
        try {
            val messages = loadMessages(Telephony.Sms.CONTENT_URI, limit, offset)
            result.success(messages)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to query SMS messages: ${e.message}", null)
        }
    }

    private fun handleSearchMessages(query: String?, limit: Int, result: Result) {
        try {
            val messages = if (query.isNullOrEmpty()) {
                emptyList()
            } else {
                val selection = "${Telephony.Sms.BODY} LIKE ? OR ${Telephony.Sms.ADDRESS} LIKE ?"
                val selectionArgs = arrayOf("%$query%", "%$query%")
                loadMessagesWithSelection(Telephony.Sms.CONTENT_URI, limit, 0, selection, selectionArgs)
            }
            result.success(messages)
        } catch (e: Exception) {
            result.error("SEARCH_FAILED", "Failed to search SMS messages: ${e.message}", null)
        }
    }

    private fun handleGetSMSStats(result: Result) {
        try {
            val stats = mutableMapOf<String, Int>()
            context.contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf("count(*) as count", Telephony.Sms.TYPE),
                null,
                null,
                null
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val count = cursor.getInt(0)
                    val type = cursor.getInt(1)
                    when (type) {
                        Telephony.Sms.MESSAGE_TYPE_INBOX -> stats["inbox"] = count
                        Telephony.Sms.MESSAGE_TYPE_SENT -> stats["sent"] = count
                        Telephony.Sms.MESSAGE_TYPE_DRAFT -> stats["draft"] = count
                    }
                }
            }
            result.success(stats)
        } catch (e: Exception) {
            result.error("STATS_FAILED", "Failed to get SMS stats: ${e.message}", null)
        }
    }

    private fun handleGetMessageCounts(result: Result) {
        try {
            val counts = mutableMapOf<String, Int>()


            context.contentResolver.query(
                Telephony.Sms.Inbox.CONTENT_URI,
                arrayOf("count(*) as count"),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    counts["inbox"] = cursor.getInt(0)
                }
            }


            context.contentResolver.query(
                Telephony.Sms.Sent.CONTENT_URI,
                arrayOf("count(*) as count"),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    counts["sent"] = cursor.getInt(0)
                }
            }

            result.success(counts)
        } catch (e: Exception) {
            result.error("COUNTS_FAILED", "Failed to get message counts: ${e.message}", null)
        }
    }

    private fun handleGetPaginatedMessages(type: String?, page: Int, pageSize: Int, result: Result) {
        try {
            val uri = when (type) {
                "inbox" -> Telephony.Sms.Inbox.CONTENT_URI
                "sent" -> Telephony.Sms.Sent.CONTENT_URI
                else -> Telephony.Sms.CONTENT_URI
            }

            val offset = page * pageSize
            val messages = loadMessagesWithSelection(uri, pageSize, offset, null, null)

            result.success(mapOf(
                "messages" to messages,
                "hasMore" to (messages.size >= pageSize)
            ))
        } catch (e: Exception) {
            result.error(
                "PAGINATION_FAILED",
                "Failed to get paginated messages: ${e.message}",
                null
            )
        }
    }

    private fun loadMessages(uri: Uri, limit: Int, offset: Int): List<Map<String, Any>> {
        return loadMessagesWithSelection(uri, limit, offset, null, null)
    }

    private fun loadMessagesWithSelection(
        uri: Uri,
        limit: Int,
        offset: Int,
        selection: String?,
        selectionArgs: Array<String>?
    ): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE
        )

        context.contentResolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            "${Telephony.Sms.DATE} DESC LIMIT $limit OFFSET $offset"
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                messages.add(mapOf(
                    "id" to cursor.getLong(0),
                    "address" to (cursor.getString(1) ?: ""),
                    "body" to (cursor.getString(2) ?: ""),
                    "date" to cursor.getLong(3),
                    "type" to cursor.getInt(4)
                ))
            }
        }
        return messages
    }

    private fun hasPermissions(): Boolean {
        return REQUIRED_PERMISSIONS.all {
            context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }
    }
}
