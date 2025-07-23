package com.example.company_app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class ContactsMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/contacts"
    }

    fun handleContactMethod(call: MethodCall, result: Result) {
        when (call.method) {
            "getContacts" -> handleGetContacts(result)
            "getContactDetails" -> handleGetContactDetails(call, result)
            "searchContacts" -> handleSearchContacts(call, result)
            "getContactStats" -> handleGetContactStats(result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetContacts(result: Result) {
        if (!hasContactsPermissions()) {
            result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
            return
        }

        try {
            val contacts = mutableListOf<Map<String, Any>>()
            val cursor = context.contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                arrayOf(
                    ContactsContract.Contacts._ID,
                    ContactsContract.Contacts.DISPLAY_NAME,
                    ContactsContract.Contacts.HAS_PHONE_NUMBER,
                    ContactsContract.Contacts.PHOTO_URI,
                    ContactsContract.Contacts.LAST_TIME_CONTACTED,
                    ContactsContract.Contacts.TIMES_CONTACTED
                ),
                null,
                null,
                ContactsContract.Contacts.DISPLAY_NAME
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val contactId = it.getString(0)
                    val hasPhone = it.getInt(2) > 0
                    val phoneNumbers = if (hasPhone) getPhoneNumbers(contactId) else emptyList()
                    val emails = getEmails(contactId)

                    contacts.add(mapOf(
                        "id" to contactId,
                        "displayName" to (it.getString(1) ?: ""),
                        "photoUri" to (it.getString(3) ?: ""),
                        "lastTimeContacted" to it.getLong(4),
                        "timesContacted" to it.getInt(5),
                        "phoneNumbers" to phoneNumbers,
                        "emails" to emails
                    ))
                }
            }
            result.success(contacts)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to query contacts: ${e.message}", null)
        }
    }

    private fun handleGetContactDetails(call: MethodCall, result: Result) {
        if (!hasContactsPermissions()) {
            result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
            return
        }

        val contactId = call.argument<String>("contactId")
        if (contactId == null) {
            result.error("INVALID_ARGUMENTS", "Contact ID is required", null)
            return
        }

        try {
            val contact = mutableMapOf<String, Any>()
            val cursor = context.contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                null,
                "${ContactsContract.Contacts._ID} = ?",
                arrayOf(contactId),
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    contact["id"] = contactId
                    contact["displayName"] = it.getString(it.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)) ?: ""
                    contact["photoUri"] = it.getString(it.getColumnIndex(ContactsContract.Contacts.PHOTO_URI)) ?: ""
                    contact["lastTimeContacted"] = it.getLong(it.getColumnIndex(ContactsContract.Contacts.LAST_TIME_CONTACTED))
                    contact["timesContacted"] = it.getInt(it.getColumnIndex(ContactsContract.Contacts.TIMES_CONTACTED))
                    contact["phoneNumbers"] = getPhoneNumbers(contactId)
                    contact["emails"] = getEmails(contactId)
                    contact["addresses"] = getAddresses(contactId)
                    contact["organizations"] = getOrganizations(contactId)
                    contact["websites"] = getWebsites(contactId)
                    contact["notes"] = getNotes(contactId)
                    contact["events"] = getEvents(contactId)
                }
            }
            result.success(contact)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to query contact details: ${e.message}", null)
        }
    }

    private fun handleSearchContacts(call: MethodCall, result: Result) {
        if (!hasContactsPermissions()) {
            result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
            return
        }

        val query = call.argument<String>("query") ?: ""
        try {
            val contacts = mutableListOf<Map<String, Any>>()
            val cursor = context.contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                null,
                "${ContactsContract.Contacts.DISPLAY_NAME} LIKE ?",
                arrayOf("%$query%"),
                "${ContactsContract.Contacts.DISPLAY_NAME} ASC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val contactId = it.getString(it.getColumnIndex(ContactsContract.Contacts._ID))
                    contacts.add(mapOf(
                        "id" to contactId,
                        "displayName" to (it.getString(it.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)) ?: ""),
                        "phoneNumbers" to getPhoneNumbers(contactId),
                        "emails" to getEmails(contactId)
                    ))
                }
            }
            result.success(contacts)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to search contacts: ${e.message}", null)
        }
    }

    private fun handleGetContactStats(result: Result) {
        if (!hasContactsPermissions()) {
            result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
            return
        }

        try {
            val stats = mutableMapOf<String, Any>()
            stats["totalContacts"] = getContactsCount()
            stats["contactGroups"] = getContactGroupsCount()
            stats["favoriteContacts"] = getFavoriteContactsCount()
            stats["recentContacts"] = getRecentContactsCount()
            result.success(stats)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", "Failed to get contact statistics: ${e.message}", null)
        }
    }


    private fun hasContactsPermissions(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        context.checkSelfPermission(android.Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
    } else {
        true
    }

    private fun getPhoneNumbers(contactId: String): List<Map<String, String>> {
        val phoneNumbers = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            null,
            "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                phoneNumbers.add(mapOf(
                    "number" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)) ?: ""),
                    "type" to getPhoneTypeLabel(it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE)))
                ))
            }
        }
        return phoneNumbers
    }

    private fun getEmails(contactId: String): List<Map<String, String>> {
        val emails = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            null,
            "${ContactsContract.CommonDataKinds.Email.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                emails.add(mapOf(
                    "email" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Email.ADDRESS)) ?: ""),
                    "type" to getEmailTypeLabel(it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.Email.TYPE)))
                ))
            }
        }
        return emails
    }

    private fun getAddresses(contactId: String): List<Map<String, String>> {
        val addresses = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_URI,
            null,
            "${ContactsContract.CommonDataKinds.StructuredPostal.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                addresses.add(mapOf(
                    "street" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.STREET)) ?: ""),
                    "city" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.CITY)) ?: ""),
                    "region" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.REGION)) ?: ""),
                    "postcode" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE)) ?: ""),
                    "type" to getAddressTypeLabel(it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.TYPE)))
                ))
            }
        }
        return addresses
    }

    private fun getOrganizations(contactId: String): List<Map<String, String>> {
        val organizations = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            null,
            "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(contactId, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                organizations.add(mapOf(
                    "company" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Organization.COMPANY)) ?: ""),
                    "title" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Organization.TITLE)) ?: ""),
                    "department" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Organization.DEPARTMENT)) ?: "")
                ))
            }
        }
        return organizations
    }

    private fun getWebsites(contactId: String): List<String> {
        val websites = mutableListOf<String>()
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            null,
            "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(contactId, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Website.URL))?.let { url ->
                    websites.add(url)
                }
            }
        }
        return websites
    }

    private fun getNotes(contactId: String): String {
        var notes = ""
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            null,
            "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(contactId, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE),
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                notes = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Note.NOTE)) ?: ""
            }
        }
        return notes
    }

    private fun getEvents(contactId: String): List<Map<String, String>> {
        val events = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            null,
            "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(contactId, ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                events.add(mapOf(
                    "date" to (it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Event.START_DATE)) ?: ""),
                    "type" to getEventTypeLabel(it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.Event.TYPE)))
                ))
            }
        }
        return events
    }

    private fun getContactsCount(): Int {
        var count = 0
        context.contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            null,
            null,
            null,
            null
        )?.use { cursor ->
            count = cursor.count
        }
        return count
    }

    private fun getContactGroupsCount(): Int {
        var count = 0
        context.contentResolver.query(
            ContactsContract.Groups.CONTENT_URI,
            null,
            null,
            null,
            null
        )?.use { cursor ->
            count = cursor.count
        }
        return count
    }

    private fun getFavoriteContactsCount(): Int {
        var count = 0
        context.contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            null,
            "${ContactsContract.Contacts.STARRED} = 1",
            null,
            null
        )?.use { cursor ->
            count = cursor.count
        }
        return count
    }

    private fun getRecentContactsCount(): Int {
        val thirtyDaysAgo = System.currentTimeMillis() - (30L * 24L * 60L * 60L * 1000L)
        var count = 0
        context.contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            null,
            "${ContactsContract.Contacts.LAST_TIME_CONTACTED} >= ?",
            arrayOf(thirtyDaysAgo.toString()),
            null
        )?.use { cursor ->
            count = cursor.count
        }
        return count
    }

    private fun getPhoneTypeLabel(type: Int): String {
        return when (type) {
            ContactsContract.CommonDataKinds.Phone.TYPE_HOME -> "Home"
            ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE -> "Mobile"
            ContactsContract.CommonDataKinds.Phone.TYPE_WORK -> "Work"
            ContactsContract.CommonDataKinds.Phone.TYPE_FAX_WORK -> "Work Fax"
            ContactsContract.CommonDataKinds.Phone.TYPE_FAX_HOME -> "Home Fax"
            ContactsContract.CommonDataKinds.Phone.TYPE_PAGER -> "Pager"
            ContactsContract.CommonDataKinds.Phone.TYPE_OTHER -> "Other"
            else -> "Custom"
        }
    }

    private fun getEmailTypeLabel(type: Int): String {
        return when (type) {
            ContactsContract.CommonDataKinds.Email.TYPE_HOME -> "Home"
            ContactsContract.CommonDataKinds.Email.TYPE_WORK -> "Work"
            ContactsContract.CommonDataKinds.Email.TYPE_OTHER -> "Other"
            else -> "Custom"
        }
    }

    private fun getAddressTypeLabel(type: Int): String {
        return when (type) {
            ContactsContract.CommonDataKinds.StructuredPostal.TYPE_HOME -> "Home"
            ContactsContract.CommonDataKinds.StructuredPostal.TYPE_WORK -> "Work"
            ContactsContract.CommonDataKinds.StructuredPostal.TYPE_OTHER -> "Other"
            else -> "Custom"
        }
    }

    private fun getEventTypeLabel(type: Int): String {
        return when (type) {
            ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY -> "Birthday"
            ContactsContract.CommonDataKinds.Event.TYPE_ANNIVERSARY -> "Anniversary"
            ContactsContract.CommonDataKinds.Event.TYPE_OTHER -> "Other"
            else -> "Custom"
        }
    }

    private fun getContactGroups(contactId: String): List<Map<String, String>> {
        val groups = mutableListOf<Map<String, String>>()
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            null,
            "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(contactId, ContactsContract.CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val groupId = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.GroupMembership.GROUP_ROW_ID))
                val groupCursor = context.contentResolver.query(
                    ContactsContract.Groups.CONTENT_URI,
                    null,
                    "${ContactsContract.Groups._ID} = ?",
                    arrayOf(groupId),
                    null
                )
                groupCursor?.use { groupCursor ->
                    if (groupCursor.moveToFirst()) {
                        groups.add(mapOf(
                            "id" to groupId,
                            "title" to (groupCursor.getString(groupCursor.getColumnIndex(ContactsContract.Groups.TITLE)) ?: ""),
                            "summary" to (groupCursor.getString(groupCursor.getColumnIndex(ContactsContract.Groups.NOTES)) ?: "")
                        ))
                    }
                }
            }
        }
        return groups
    }

    private fun getProfileData(contactId: String): Map<String, Any> {
        val profile = mutableMapOf<String, Any>()
        val cursor = context.contentResolver.query(
            ContactsContract.Profile.CONTENT_URI,
            null,
            "${ContactsContract.Profile._ID} = ?",
            arrayOf(contactId),
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                profile["displayName"] = it.getString(it.getColumnIndex(ContactsContract.Profile.DISPLAY_NAME)) ?: ""
                profile["phoneticName"] = it.getString(it.getColumnIndex(ContactsContract.Profile.PHONETIC_NAME)) ?: ""
                profile["lastUpdated"] = it.getLong(it.getColumnIndex(ContactsContract.Profile.CONTACT_LAST_UPDATED_TIMESTAMP))
            }
        }
        return profile
    }
}
