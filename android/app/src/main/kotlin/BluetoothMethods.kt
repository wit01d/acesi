package com.example.company_app

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.ParcelUuid
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import org.json.JSONArray
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import android.app.Activity
import java.util.UUID
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class BluetoothMethods(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.company_app/bluetooth"
        private const val PERMISSION_REQUEST_CODE = 1234
        private const val LEGACY_DISCOVERY_DURATION = 120000


        private val DEFAULT_PROFILE_UUIDS = ProfileUUIDs(
            a2dpSink = "0000110B-0000-1000-8000-00805F9B34FB",
            hfp = "0000111E-0000-1000-8000-00805F9B34FB",
            hidHost = "00001124-0000-1000-8000-00805F9B34FB",
            sap = "0000112D-0000-1000-8000-00805F9B34FB",
            opp = "00001105-0000-1000-8000-00805F9B34FB",
            spp = "00001101-0000-1000-8000-00805F9B34FB"
        )
    }


    data class ProfileUUIDs(
        val a2dpSink: String,
        val hfp: String,
        val hidHost: String,
        val sap: String,
        val opp: String,
        val spp: String
    )

    private var profileUUIDs: ProfileUUIDs = DEFAULT_PROFILE_UUIDS


    private fun isValidUUID(uuid: String): Boolean {
        return try {
            UUID.fromString(uuid)
            true
        } catch (e: IllegalArgumentException) {
            false
        }
    }


    fun configureProfileUUIDs(uuids: Map<String, String>) {
        val current = profileUUIDs
        profileUUIDs = ProfileUUIDs(
            a2dpSink = uuids["a2dpSink"]?.takeIf { isValidUUID(it) } ?: current.a2dpSink,
            hfp = uuids["hfp"]?.takeIf { isValidUUID(it) } ?: current.hfp,
            hidHost = uuids["hidHost"]?.takeIf { isValidUUID(it) } ?: current.hidHost,
            sap = uuids["sap"]?.takeIf { isValidUUID(it) } ?: current.sap,
            opp = uuids["opp"]?.takeIf { isValidUUID(it) } ?: current.opp,
            spp = uuids["spp"]?.takeIf { isValidUUID(it) } ?: current.spp
        )
    }

    private val bluetoothManager: BluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null


    private var activity: Activity? = null
    private var flutterEngine: FlutterEngine? = null


    fun setActivity(activity: Activity) {
        this.activity = activity
    }

    fun setFlutterEngine(engine: FlutterEngine) {
        this.flutterEngine = engine
    }


    private val discoveryReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when(intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE)
                    device?.let {
                        val deviceInfo = JSONObject().apply {
                            put("address", it.address)
                            put("name", it.name ?: "Unknown")
                            put("rssi", rssi)
                            put("type", it.type)
                            put("bondState", it.bondState)
                            put("isLegacy", true)
                        }

                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {

                }
            }
        }
    }

    fun handleBluetoothMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isBluetoothAvailable" -> {

                result.success(bluetoothAdapter != null)
            }
            "isBluetoothEnabled" -> {

                result.success(bluetoothAdapter?.isEnabled == true)
            }
            "startScan" -> handleStartScan(result)
            "stopScan" -> handleStopScan(result)
            "getPairedDevices" -> handleGetPairedDevices(result)
            "startAdvertising" -> handleStartAdvertising(call.arguments as? Map<String, Any>, result)
            "stopAdvertising" -> handleStopAdvertising(result)
            "connectToDevice" -> handleConnectToDevice(call.arguments as? String, result)
            "pairDevice" -> handlePairDevice(call.arguments as? String, result)
            "connectProfile" -> handleConnectProfile(
                call.arguments as? Map<String, Any>,
                result
            )
            "getDeviceMetadata" -> handleGetDeviceMetadata(call.arguments as? String, result)
            "startLegacyDiscovery" -> handleStartLegacyDiscovery(result)
            "stopLegacyDiscovery" -> handleStopLegacyDiscovery(result)
            "createLegacyConnection" -> handleLegacyConnection(call.arguments as? Map<String, Any>, result)
            "configureProfileUUIDs" -> {
                val uuids = call.arguments as? Map<String, String>
                if (uuids != null) {
                    configureProfileUUIDs(uuids)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "UUIDs map required", null)
                }
            }
            "getBluetoothState" -> handleGetBluetoothState(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Ensures Bluetooth is enabled before performing operations.
     * Returns true if Bluetooth is enabled, false otherwise.
     * Automatically sends appropriate error to result if disabled.
     */
    private fun ensureBluetoothEnabled(result: MethodChannel.Result): Boolean {
        if (bluetoothAdapter?.isEnabled != true) {
            result.error("BLUETOOTH_OFF", "Bluetooth is disabled", null)
            return false
        }
        return true
    }

    private fun handleStartScan(result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!checkAndRequestPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
            return
        }

        bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
        if (bluetoothLeScanner == null) {
            result.error("SCAN_FAILED", "Bluetooth LE scanner not available", null)
            return
        }


        val scanFilters = mutableListOf<ScanFilter>()


        val manufacturerFilters = listOf(
            0x004C,
            0x0075,
            0x0002,
            0x0001
        )

        manufacturerFilters.forEach { manufacturerId ->
            scanFilters.add(
                ScanFilter.Builder()
                    .setManufacturerData(manufacturerId, byteArrayOf())
                    .build()
            )
        }

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
            .setNumOfMatches(ScanSettings.MATCH_NUM_MAX_ADVERTISEMENT)
            .setReportDelay(0)
            .build()

        scanCallback = object : ScanCallback() {
            private val discoveredDevices = mutableSetOf<String>()

            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                val device = scanResult.device
                val deviceAddress = device.address


                if (discoveredDevices.add(deviceAddress)) {
                    val scanRecord = scanResult.scanRecord
                    val deviceInfo = JSONObject().apply {
                        put("address", deviceAddress)
                        put("name", device.name ?: scanRecord?.deviceName ?: "Unknown")
                        put("rssi", scanResult.rssi)
                        put("timestamp", scanResult.timestampNanos)
                        put("isConnectable", scanResult.isConnectable)


                        val manufacturerData = scanRecord?.manufacturerSpecificData
                        if (manufacturerData != null) {
                            val manufacturerInfo = JSONObject()
                            for (i in 0 until manufacturerData.size()) {
                                val manufacturerId = manufacturerData.keyAt(i)
                                val data = manufacturerData.get(manufacturerId)
                                if (data != null) {
                                    manufacturerInfo.put(
                                        manufacturerId.toString(),
                                        android.util.Base64.encodeToString(data, android.util.Base64.NO_WRAP)
                                    )
                                }
                            }
                            put("manufacturerData", manufacturerInfo)
                        }


                        val serviceUuids = JSONArray()
                        scanRecord?.serviceUuids?.forEach { uuid ->
                            serviceUuids.put(uuid.uuid.toString())
                        }
                        put("serviceUuids", serviceUuids)


                        val serviceData = JSONObject()
                        scanRecord?.serviceData?.forEach { (uuid, data) ->
                            serviceData.put(
                                uuid.toString(),
                                android.util.Base64.encodeToString(data, android.util.Base64.NO_WRAP)
                            )
                        }
                        put("serviceData", serviceData)


                        put("txPower", scanResult.txPower)
                        scanRecord?.let { record ->
                            put("advertiseFlags", record.advertiseFlags)
                            put("deviceName", record.deviceName)
                            put("txPowerLevel", record.txPowerLevel)
                        }
                    }


                    activity?.runOnUiThread {
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, CHANNEL)
                                .invokeMethod("onScanResult", deviceInfo.toString())
                        }
                    }
                }
            }

            override fun onScanFailed(errorCode: Int) {
                val errorMessage = when(errorCode) {
                    ScanCallback.SCAN_FAILED_ALREADY_STARTED -> "Scan already started"
                    ScanCallback.SCAN_FAILED_APPLICATION_REGISTRATION_FAILED ->
                        "Application registration failed"
                    ScanCallback.SCAN_FAILED_FEATURE_UNSUPPORTED -> "Feature unsupported"
                    ScanCallback.SCAN_FAILED_INTERNAL_ERROR -> "Internal error"
                    else -> "Unknown error code: $errorCode"
                }
                result.error("SCAN_FAILED", errorMessage, errorCode)
            }
        }

        try {
            bluetoothLeScanner?.startScan(scanFilters, scanSettings, scanCallback)
            result.success(null)
        } catch (e: Exception) {
            result.error("SCAN_FAILED", "Failed to start scan: ${e.message}", null)
        }
    }

    private fun handleStopScan(result: MethodChannel.Result) {
        scanCallback?.let { bluetoothLeScanner?.stopScan(it) }
        scanCallback = null
        result.success(null)
    }

    private fun handleStartAdvertising(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
            return
        }

        advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (advertiser == null) {
            result.error("ADVERTISE_FAILED", "Bluetooth LE advertiser not available", null)
            return
        }

        val advertiseSettings = AdvertiseSettings.Builder().apply {
            setAdvertiseMode(arguments?.get("mode") as? Int ?: AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            setTxPowerLevel(arguments?.get("powerLevel") as? Int ?: AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            setConnectable(arguments?.get("connectable") as? Boolean ?: true)
            setTimeout((arguments?.get("timeoutMillis") as? Int) ?: 0)
        }.build()

        val advertiseData = AdvertiseData.Builder().apply {
            setIncludeDeviceName(arguments?.get("includeDeviceName") as? Boolean ?: true)
            setIncludeTxPowerLevel(arguments?.get("includeTxPowerLevel") as? Boolean ?: true)


            (arguments?.get("manufacturerData") as? Map<*, *>)?.forEach { (key, value) ->
                when {
                    key is Int && value is ByteArray -> addManufacturerData(key, value)
                    key is String && value is ByteArray -> addManufacturerData(key.toIntOrNull() ?: 0, value)
                }
            }


            (arguments?.get("serviceUuids") as? List<*>)?.forEach { uuid ->
                uuid?.toString()?.let { ParcelUuid.fromString(it) }?.let { addServiceUuid(it) }
            }
        }.build()


        val scanResponse = AdvertiseData.Builder().apply {
            setIncludeDeviceName(arguments?.get("includeScanResponseName") as? Boolean ?: false)
        }.build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                val advertisingInfo = JSONObject().apply {
                    put("status", "success")
                    put("mode", settingsInEffect.mode)
                    put("txPowerLevel", settingsInEffect.txPowerLevel)
                    put("timeout", settingsInEffect.timeout)
                    put("isConnectable", settingsInEffect.isConnectable)
                }

                activity?.runOnUiThread {
                    result.success(advertisingInfo.toString())
                }
            }

            override fun onStartFailure(errorCode: Int) {
                val errorMessage = when (errorCode) {
                    ADVERTISE_FAILED_ALREADY_STARTED -> "Advertising already started"
                    ADVERTISE_FAILED_DATA_TOO_LARGE -> "Advertising data too large"
                    ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "Advertising not supported"
                    ADVERTISE_FAILED_INTERNAL_ERROR -> "Internal advertising error"
                    ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "Too many advertisers"
                    else -> "Unknown advertising error: $errorCode"
                }

                activity?.runOnUiThread {
                    result.error("ADVERTISE_FAILED", errorMessage, errorCode)
                }
            }
        }

        try {
            advertiser?.startAdvertising(advertiseSettings, advertiseData, scanResponse, advertiseCallback)
        } catch (e: Exception) {
            result.error(
                "ADVERTISE_FAILED",
                "Failed to start advertising: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleStopAdvertising(result: MethodChannel.Result) {
        advertiseCallback?.let { advertiser?.stopAdvertising(it) }
        advertiseCallback = null
        result.success(null)
    }

    private fun handleGetPairedDevices(result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        try {
            val devices = ArrayList<Map<String, Any>>()
            bluetoothAdapter?.bondedDevices?.forEach { device ->
                devices.add(mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address,
                    "type" to getDeviceTypeName(device.type),
                    "bondState" to getBondStateName(device.bondState)
                ))
            }
            result.success(devices)
        } catch (e: Exception) {
            result.error("BLUETOOTH_ERROR", e.message, null)
        }
    }

    private fun handleConnectToDevice(address: String?, result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (address == null) {
            result.error("INVALID_ARGUMENT", "Device address is required", null)
            return
        }

        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Could not find device with address $address", null)
            return
        }



        try {
            when (device.type) {
                BluetoothDevice.DEVICE_TYPE_CLASSIC -> {

                }
                BluetoothDevice.DEVICE_TYPE_LE -> {

                }
                BluetoothDevice.DEVICE_TYPE_DUAL -> {

                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", e.message, null)
        }
    }

    private fun handlePairDevice(address: String?, result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        try {
            if (device?.bondState == BluetoothDevice.BOND_NONE) {
                device.createBond()
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("PAIRING_FAILED", e.message, null)
        }
    }

    private fun handleConnectProfile(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        val address = arguments?.get("address") as? String
        val profile = arguments?.get("profile") as? String

        if (address == null || profile == null) {
            result.error("INVALID_ARGUMENT", "Device address and profile required", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        try {
            when (profile) {
                "A2DP" -> connectA2DPProfile(device, result)
                "HFP" -> connectHFPProfile(device, result)
                "HID" -> connectHIDProfile(device, result)
                "SAP" -> connectSAPProfile(device, result)
                "FTP" -> connectFTPProfile(device, result)
                else -> result.error("UNSUPPORTED_PROFILE", "Profile not supported", null)
            }
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", e.message, null)
        }
    }

    private fun handleGetDeviceMetadata(address: String?, result: MethodChannel.Result) {
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        try {
            val metadata = JSONObject().apply {
                put("address", device?.address)
                put("name", device?.name)
                put("type", device?.type)
                put("bondState", device?.bondState)
                put("supportedProfiles", getSupportedProfiles(device))

                put("rssi", -1)
                put("batteryLevel", -1)
            }
            result.success(metadata.toString())
        } catch (e: Exception) {
            result.error("METADATA_FAILED", e.message, null)
        }
    }

    private fun connectA2DPProfile(device: BluetoothDevice, result: MethodChannel.Result) {
        bluetoothAdapter?.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.A2DP) {
                    try {

                        val a2dpClass = Class.forName("android.bluetooth.BluetoothA2dp")
                        val connectMethod = a2dpClass.getMethod("connect", BluetoothDevice::class.java)
                        connectMethod.invoke(proxy, device)
                        result.success(mapOf(
                            "success" to true,
                            "method" to "reflection"
                        ))
                    } catch (e: Exception) {

                        try {
                            val bluetoothA2dp = proxy as BluetoothA2dp

                            val connectedDevices = bluetoothA2dp.connectedDevices

                            if (!connectedDevices.contains(device)) {

                                result.success(mapOf(
                                    "success" to true,
                                    "method" to "manual",
                                    "message" to "Profile proxy ready for manual connection"
                                ))
                            } else {
                                result.success(mapOf(
                                    "success" to true,
                                    "method" to "already_connected"
                                ))
                            }
                        } catch (e2: Exception) {
                            result.error(
                                "A2DP_CONNECT_FAILED",
                                "Failed to establish A2DP connection: ${e.message}",
                                mapOf(
                                    "reflectionError" to e.message,
                                    "fallbackError" to e2.message
                                )
                            )
                        }
                    }
                }
            }

            override fun onServiceDisconnected(profile: Int) {
                result.error(
                    "A2DP_SERVICE_DISCONNECTED",
                    "A2DP service disconnected",
                    null
                )
            }
        }, BluetoothProfile.A2DP)
    }

    private fun connectHFPProfile(device: BluetoothDevice, result: MethodChannel.Result) {
        bluetoothAdapter?.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.HEADSET) {
                    try {

                        val headsetClass = Class.forName("android.bluetooth.BluetoothHeadset")
                        val connectMethod = headsetClass.getMethod("connect", BluetoothDevice::class.java)
                        connectMethod.invoke(proxy, device)
                        result.success(mapOf(
                            "success" to true,
                            "method" to "reflection"
                        ))
                    } catch (e: Exception) {

                        try {
                            val bluetoothHeadset = proxy as BluetoothHeadset
                            val connectedDevices = bluetoothHeadset.connectedDevices

                            if (!connectedDevices.contains(device)) {
                                result.success(mapOf(
                                    "success" to true,
                                    "method" to "manual",
                                    "message" to "Profile proxy ready for manual connection"
                                ))
                            } else {
                                result.success(mapOf(
                                    "success" to true,
                                    "method" to "already_connected"
                                ))
                            }
                        } catch (e2: Exception) {
                            result.error(
                                "HFP_CONNECT_FAILED",
                                "Failed to establish HFP connection: ${e.message}",
                                mapOf(
                                    "reflectionError" to e.message,
                                    "fallbackError" to e2.message
                                )
                            )
                        }
                    }
                }
            }

            override fun onServiceDisconnected(profile: Int) {
                result.error(
                    "HFP_SERVICE_DISCONNECTED",
                    "HFP service disconnected",
                    null
                )
            }
        }, BluetoothProfile.HEADSET)
    }

    private fun connectHIDProfile(device: BluetoothDevice, result: MethodChannel.Result) {

        result.error("UNSUPPORTED", "HID profile not supported directly", null)
    }

    private fun connectSAPProfile(device: BluetoothDevice, result: MethodChannel.Result) {


    }

    private fun connectFTPProfile(device: BluetoothDevice, result: MethodChannel.Result) {


    }

    private fun getSupportedProfiles(device: BluetoothDevice?): JSONArray {
        val profiles = JSONArray()
        val uuids = device?.uuids ?: return profiles

        for (uuid in uuids) {
            when (uuid.uuid.toString().uppercase()) {
                profileUUIDs.a2dpSink.uppercase() -> profiles.put("A2DP")
                profileUUIDs.hfp.uppercase() -> profiles.put("HFP")
                profileUUIDs.hidHost.uppercase() -> profiles.put("HID")
                profileUUIDs.sap.uppercase() -> profiles.put("SAP")
                profileUUIDs.opp.uppercase() -> profiles.put("FTP/OPP")
            }
        }
        return profiles
    }

    private fun getManufacturerData(scanRecord: ScanRecord?): JSONObject {
        val result = JSONObject()
        val manufacturerData = scanRecord?.manufacturerSpecificData
        if (manufacturerData != null) {
            for (i in 0 until manufacturerData.size()) {
                val id = manufacturerData.keyAt(i)
                val data = manufacturerData.get(id)
                if (data != null) {
                    result.put(id.toString(), android.util.Base64.encodeToString(data, android.util.Base64.NO_WRAP))
                }
            }
        }
        return result
    }

    private fun getServiceData(scanRecord: ScanRecord?): JSONObject {
        val result = JSONObject()
        scanRecord?.serviceData?.let { serviceData ->
            for ((uuid, data) in serviceData) {
                result.put(uuid.toString(), android.util.Base64.encodeToString(data, android.util.Base64.NO_WRAP))
            }
        }
        return result
    }

    private fun hasRequiredPermissions(): Boolean {
        val requiredPermissions = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

            requiredPermissions.addAll(listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT
            ))


            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                requiredPermissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        } else {

            requiredPermissions.addAll(listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            ))
        }

        return requiredPermissions.all { permission ->
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun checkAndRequestPermissions(): Boolean {
        val missingPermissions = getRequiredPermissions().filter { permission ->
            ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            return true
        }

        activity?.let { activity ->
            ActivityCompat.requestPermissions(
                activity,
                missingPermissions.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }

        return false
    }

    private fun getRequiredPermissions(): List<String> {
        val permissions = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

            permissions.addAll(listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT
            ))

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        } else {

            permissions.addAll(listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ))
        }

        return permissions
    }

    private fun handleStartLegacyDiscovery(result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!checkAndRequestPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
            return
        }

        try {

            context.registerReceiver(
                discoveryReceiver,
                IntentFilter(BluetoothDevice.ACTION_FOUND)
            )
            context.registerReceiver(
                discoveryReceiver,
                IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            )


            bluetoothAdapter?.cancelDiscovery()


            if (bluetoothAdapter?.startDiscovery() == true) {

                Handler(Looper.getMainLooper()).postDelayed({
                    handleStopLegacyDiscovery(result)
                }, LEGACY_DISCOVERY_DURATION.toLong())

                result.success(null)
            } else {
                result.error("DISCOVERY_FAILED", "Could not start device discovery", null)
            }
        } catch (e: Exception) {
            result.error("DISCOVERY_FAILED", e.message, null)
        }
    }

    private fun handleStopLegacyDiscovery(result: MethodChannel.Result) {
        try {
            bluetoothAdapter?.cancelDiscovery()
            try {
                context.unregisterReceiver(discoveryReceiver)
            } catch (e: IllegalArgumentException) {

            }
            result.success(null)
        } catch (e: Exception) {
            result.error("DISCOVERY_STOP_FAILED", e.message, null)
        }
    }

    private fun handleLegacyConnection(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        val address = arguments?.get("address") as? String
        val customUUID = arguments?.get("uuid") as? String

        if (address == null) {
            result.error("INVALID_ARGUMENT", "Device address required", null)
            return
        }

        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        val uuid = when {
            customUUID != null && isValidUUID(customUUID) -> customUUID
            else -> profileUUIDs.spp
        }

        try {

            val socket = device.createRfcommSocketToServiceRecord(UUID.fromString(uuid))


            CoroutineScope(Dispatchers.IO).launch {
                try {
                    bluetoothAdapter?.cancelDiscovery()
                    socket.connect()
                    withContext(Dispatchers.Main) {
                        result.success(true)
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("CONNECTION_FAILED", e.message, null)
                    }
                    try {
                        socket.close()
                    } catch (e2: Exception) {

                    }
                }
            }
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", e.message, null)
        }
    }


    private fun updateVisibility(visible: Boolean, duration: Int = 120, result: MethodChannel.Result) {
        if (!ensureBluetoothEnabled(result)) return
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        try {
            if (visible) {
                if (bluetoothAdapter?.scanMode != BluetoothAdapter.SCAN_MODE_CONNECTABLE_DISCOVERABLE) {
                    val discoverableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                    discoverableIntent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration)
                    discoverableIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(discoverableIntent)
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("VISIBILITY_FAILED", "Failed to update visibility: ${e.message}", null)
        }
    }

    private fun handleGetBluetoothState(result: MethodChannel.Result) {
        try {
            val stateMap = HashMap<String, Any>()
            stateMap["isAvailable"] = bluetoothAdapter != null
            stateMap["isEnabled"] = bluetoothAdapter?.isEnabled == true
            result.success(stateMap)
        } catch (e: Exception) {
            result.error("BLUETOOTH_ERROR", e.message, null)
        }
    }

    private fun getDeviceTypeName(type: Int): String = when (type) {
        BluetoothDevice.DEVICE_TYPE_CLASSIC -> "CLASSIC"
        BluetoothDevice.DEVICE_TYPE_LE -> "LE"
        BluetoothDevice.DEVICE_TYPE_DUAL -> "DUAL"
        BluetoothDevice.DEVICE_TYPE_UNKNOWN -> "UNKNOWN"
        else -> "UNKNOWN"
    }

    private fun getBondStateName(state: Int): String = when (state) {
        BluetoothDevice.BOND_NONE -> "NONE"
        BluetoothDevice.BOND_BONDING -> "BONDING"
        BluetoothDevice.BOND_BONDED -> "BONDED"
        else -> "UNKNOWN"
    }

    private fun handleConnect(
        address: String?,
        profileUuid: String?,
        result: MethodChannel.Result
    ) {
        if (!ensureBluetoothEnabled(result)) return
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        try {

            val uuid = when {
                profileUuid != null && isValidUUID(profileUuid) -> UUID.fromString(profileUuid)
                else -> UUID.fromString(profileUUIDs.spp)
            }


            val socket = device.createRfcommSocketToServiceRecord(uuid)


            CoroutineScope(Dispatchers.IO).launch {
                try {
                    bluetoothAdapter?.cancelDiscovery()
                    socket.connect()

                    withContext(Dispatchers.Main) {
                        val connectionInfo = JSONObject().apply {
                            put("status", "connected")
                            put("address", device.address)
                            put("name", device.name ?: "Unknown")
                            put("type", getDeviceTypeName(device.type))
                            put("bondState", getBondStateName(device.bondState))
                            put("uuid", uuid.toString())
                        }
                        result.success(connectionInfo.toString())
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("CONNECTION_FAILED", e.message, null)
                    }
                    try {
                        socket.close()
                    } catch (e2: Exception) {

                    }
                }
            }
        } catch (e: Exception) {
            result.error("CONNECTION_SETUP_FAILED", e.message, null)
        }
    }
}
