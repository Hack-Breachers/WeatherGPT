package com.example.flutter_application_2

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy

import java.net.HttpURLConnection
import java.net.URL
import java.io.OutputStreamWriter

class MeshRelayService : Service() {

    companion object {
        private const val CHANNEL_ID = "weathergpt_mesh"
        private const val NOTIFICATION_ID = 9001
        private const val SERVICE_ID = "com.weathergpt.mesh"
        private const val ENDPOINT_NAME = "WeatherGPT-Relay"

        // Temporary testing action.
        // This does not affect the normal mesh/SOS flow.
        const val ACTION_TEST_RELAY_SMS =
            "com.example.flutter_application_2.TEST_RELAY_SMS"

        const val ACTION_DIRECT_SOS_SMS =
            "com.example.flutter_application_2.DIRECT_SOS_SMS"
        const val ACTION_SEND_RELAY_SOS =
            "com.example.flutter_application_2.SEND_RELAY_SOS"
        const val ACTION_START_RELAY =
            "com.example.flutter_application_2.START_RELAY"
        const val ACTION_STOP_RELAY =
            "com.example.flutter_application_2.STOP_RELAY"
        private const val PREF_RELAY_ENABLED = "relay_enabled"
    
    }

        
    private val strategy = Strategy.P2P_CLUSTER

    private val seenPacketIds =
        mutableSetOf<String>()

    private val connectedEndpoints =
        mutableSetOf<String>()

    // Nearby Connections state guards. These prevent repeated calls to
    // startAdvertising/startDiscovery/requestConnection for an already-active state.
    @Volatile
    private var isAdvertising = false

    @Volatile
    private var isDiscovering = false

    private val pendingConnectionEndpoints =
        mutableSetOf<String>()

    private val reverseRoutes =
        mutableMapOf<String, String>()
    private val pendingSosPackets =
        mutableListOf<String>()

    private val originatedSosPacketIds =
        mutableSetOf<String>()

    private val preferences: SharedPreferences by lazy {
        getSharedPreferences("weathergpt_rescue_relay", Context.MODE_PRIVATE)
    }

    private val relayEnabled: Boolean
        get() = preferences.getBoolean(PREF_RELAY_ENABLED, false)

    private fun setRelayEnabled(enabled: Boolean) {
        preferences.edit().putBoolean(PREF_RELAY_ENABLED, enabled).apply()
    }

    private fun stopServiceCleanly(startId: Int? = null) {
        val client = Nearby.getConnectionsClient(this@MeshRelayService)
        client.stopAllEndpoints()
        client.stopAdvertising()
        client.stopDiscovery()
        connectedEndpoints.clear()
        pendingConnectionEndpoints.clear()
        isAdvertising = false
        isDiscovering = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        if (startId != null) {
            stopSelf(startId)
        } else {
            stopSelf()
        }
    }

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()
        loadPendingSosPackets()
    }

    private fun startRelayForeground() {
        val notification: Notification =
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("WeatherGPT Rescue Relay")
                .setContentText("Emergency relay is active")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun logNearbyEnvironment() {

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== NEARBY ENVIRONMENT =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Device: ${Build.MANUFACTURER} ${Build.MODEL}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Android SDK: ${Build.VERSION.SDK_INT}"
    )

    val permissions = arrayOf(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.BLUETOOTH_SCAN,
        Manifest.permission.BLUETOOTH_ADVERTISE,
        Manifest.permission.BLUETOOTH_CONNECT,
        Manifest.permission.NEARBY_WIFI_DEVICES
    )

    for (permission in permissions) {

        val granted =
            ActivityCompat.checkSelfPermission(
                this,
                permission
            ) == PackageManager.PERMISSION_GRANTED

        android.util.Log.d(
            "WeatherGPTMesh",
            "Permission $permission = $granted"
        )
    }

    android.util.Log.d(
        "WeatherGPTMesh",
        "SERVICE_ID = $SERVICE_ID"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "ENDPOINT_NAME = $ENDPOINT_NAME"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Strategy = P2P_CLUSTER"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "========================================"
    )
}

    private fun startMesh(advertise: Boolean) {
        android.util.Log.d(
    "WeatherGPTMesh",
    "========== START MESH =========="
)

android.util.Log.d(
    "WeatherGPTMesh",
    "startMesh(advertise = $advertise)"
)

android.util.Log.d(
    "WeatherGPTMesh",
    "relayEnabled = $relayEnabled"
)

android.util.Log.d(
    "WeatherGPTMesh",
    "isAdvertising = $isAdvertising"
)

android.util.Log.d(
    "WeatherGPTMesh",
    "isDiscovering = $isDiscovering"
)

android.util.Log.d(
    "WeatherGPTMesh",
    "connectedEndpoints = ${connectedEndpoints.size}"
)

logNearbyEnvironment()

        val client = Nearby.getConnectionsClient(this@MeshRelayService)

        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(strategy)
            .setLowPower(true)
            .build()

        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(strategy)
            .build()

        if (advertise && !isAdvertising) {
            client.startAdvertising(
                ENDPOINT_NAME,
                SERVICE_ID,
                connectionLifecycleCallback,
                advertisingOptions
            ).addOnSuccessListener {

    isAdvertising = true

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== ADVERTISING SUCCESS =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint name = $ENDPOINT_NAME"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Service ID = $SERVICE_ID"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Strategy = P2P_CLUSTER"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Advertising state = ACTIVE"
    )
            }.addOnFailureListener { error ->
                android.util.Log.e(
                    "WeatherGPTMesh",
                    "Advertising failed",
                    error
                )
            }
        } else if (advertise) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Advertising already active; skipping duplicate start"
            )
        }

        if (!isDiscovering) {
            client.startDiscovery(
                SERVICE_ID,
                endpointDiscoveryCallback,
                discoveryOptions
            ).addOnSuccessListener {

    isDiscovering = true

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== DISCOVERY SUCCESS =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Looking for Service ID = $SERVICE_ID"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Strategy = P2P_CLUSTER"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Discovery state = ACTIVE"
    )
}.addOnFailureListener { error ->

    isDiscovering = false

    android.util.Log.e(
        "WeatherGPTMesh",
        "========== DISCOVERY FAILED =========="
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Error type = ${error.javaClass.name}"
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Error message = ${error.message}"
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Discovery state = FAILED"
    )

    error.printStackTrace()
}
        } else {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Discovery already active; skipping duplicate start"
            )
        }
    }

    private val endpointDiscoveryCallback =
        object : EndpointDiscoveryCallback() {

            override fun onEndpointFound(
    endpointId: String,
    info: DiscoveredEndpointInfo
) {

    android.util.Log.d(
        "WeatherGPTMesh",
        "========================================"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== ENDPOINT FOUND ==============="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint ID = $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint name = ${info.endpointName}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Connected endpoints = ${connectedEndpoints.size}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Pending connections = ${pendingConnectionEndpoints.size}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "========================================"
    )

                if (connectedEndpoints.contains(endpointId)) {
                    android.util.Log.d(
                        "WeatherGPTMesh",
                        "Already connected to $endpointId; skipping connection request"
                    )
                    return
                }

                if (!pendingConnectionEndpoints.add(endpointId)) {
                    android.util.Log.d(
                        "WeatherGPTMesh",
                        "Connection already pending for $endpointId; skipping duplicate request"
                    )
                    return
                }

                Nearby.getConnectionsClient(this@MeshRelayService)
                    .requestConnection(
                        ENDPOINT_NAME,
                        endpointId,
                        connectionLifecycleCallback
                    )
                    .addOnSuccessListener {

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== CONNECTION REQUEST SENT =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Target endpoint = $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Local endpoint name = $ENDPOINT_NAME"
    )
}
                    .addOnFailureListener { error ->

    pendingConnectionEndpoints.remove(endpointId)

    android.util.Log.e(
        "WeatherGPTMesh",
        "========== CONNECTION REQUEST FAILED =========="
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Target endpoint = $endpointId"
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Error type = ${error.javaClass.name}"
    )

    android.util.Log.e(
        "WeatherGPTMesh",
        "Error message = ${error.message}"
    )

    error.printStackTrace()
}
            }

            override fun onEndpointLost(endpointId: String) {

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== ENDPOINT LOST =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint = $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Connected = ${connectedEndpoints.contains(endpointId)}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Connection pending = ${pendingConnectionEndpoints.contains(endpointId)}"
    )
}
        }

    private val connectionLifecycleCallback =
        object : ConnectionLifecycleCallback() {

            override fun onConnectionInitiated(
    endpointId: String,
    connectionInfo: ConnectionInfo
) {

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== CONNECTION INITIATED =========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint = $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Incoming connection = ${connectionInfo.isIncomingConnection}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Accepting connection..."
    )

    Nearby.getConnectionsClient(this@MeshRelayService)
        .acceptConnection(
            endpointId,
            payloadCallback
        )
        .addOnSuccessListener {

            android.util.Log.d(
                "WeatherGPTMesh",
                "========== CONNECTION ACCEPT SUCCESS =========="
            )

            android.util.Log.d(
                "WeatherGPTMesh",
                "Endpoint = $endpointId"
            )
        }
        .addOnFailureListener { error ->

            android.util.Log.e(
                "WeatherGPTMesh",
                "========== CONNECTION ACCEPT FAILED =========="
            )

            android.util.Log.e(
                "WeatherGPTMesh",
                "Endpoint = $endpointId"
            )

            android.util.Log.e(
                "WeatherGPTMesh",
                "Error type = ${error.javaClass.name}"
            )

            android.util.Log.e(
                "WeatherGPTMesh",
                "Error message = ${error.message}"
            )

            error.printStackTrace()
        }
}

            override fun onConnectionResult(
    endpointId: String,
    result: ConnectionResolution
) {

    pendingConnectionEndpoints.remove(endpointId)

    android.util.Log.d(
        "WeatherGPTMesh",
        "========================================"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "========== CONNECTION RESULT ==========="
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Endpoint = $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Status code = ${result.status.statusCode}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Status message = ${result.status.statusMessage}"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Success = ${result.status.isSuccess}"
    )

    // Keep your existing if(result.status.isSuccess) logic below this.

                if (result.status.isSuccess) {
    connectedEndpoints.add(endpointId)

    android.util.Log.d(
        "WeatherGPTMesh",
        "Connected relay added: $endpointId"
    )

    android.util.Log.d(
        "WeatherGPTMesh",
        "Connected relays: ${connectedEndpoints.size}"
    )

    flushPendingSosPackets(endpointId)
}
            }

            override fun onDisconnected(endpointId: String) {
                connectedEndpoints.remove(endpointId)
                pendingConnectionEndpoints.remove(endpointId)

                android.util.Log.d(
                    "WeatherGPTMesh",
                    "Disconnected: $endpointId"
                )

                android.util.Log.d(
                    "WeatherGPTMesh",
                    "Connected relays remaining: ${connectedEndpoints.size}"
                )
            }

        }

    private fun flushPendingSosPackets(endpointId: String) {
    
        if (pendingSosPackets.isEmpty()) {
            return
        }
    
        android.util.Log.d(
            "WeatherGPTMesh",
            "Flushing ${pendingSosPackets.size} pending SOS packet(s) to $endpointId"
        )
    
        val packetsToSend = pendingSosPackets.toList()
    
        for (packetString in packetsToSend) {
    
            try {
                val packet = org.json.JSONObject(packetString)
                val packetId = packet.optString("packetId")
    
                reverseRoutes[packetId] = endpointId
    
                val payload = Payload.fromBytes(
                    packetString.toByteArray(
                        Charsets.UTF_8
                    )
                )
    
                Nearby.getConnectionsClient(
                    this@MeshRelayService
                )
                    .sendPayload(
                        endpointId,
                        payload
                    )
                    .addOnSuccessListener {
    
                        removePendingSos(packetString)
    
                        android.util.Log.d(
                            "WeatherGPTMesh",
                            "Queued SOS delivered to relay: $packetId -> $endpointId"
                        )
                    }
                    .addOnFailureListener { error ->
    
                        android.util.Log.e(
                            "WeatherGPTMesh",
                            "Queued SOS retry failed: $packetId -> $endpointId",
                            error
                        )
                    }
    
            } catch (error: Exception) {
    
                android.util.Log.e(
                    "WeatherGPTMesh",
                    "Failed to flush queued SOS packet",
                    error
                )
            }
        }
    }
    
    private fun loadPendingSosPackets() {
        pendingSosPackets.clear()
        pendingSosPackets.addAll(
            preferences.getStringSet("pending_sos", emptySet())?.toList()
                ?: emptyList()
        )
    }

    private fun persistPendingSosPackets() {
        preferences.edit()
            .putStringSet("pending_sos", pendingSosPackets.toSet())
            .apply()
    }

    private fun queuePendingSos(packetString: String) {
        if (!pendingSosPackets.contains(packetString)) {
            pendingSosPackets.add(packetString)
            persistPendingSosPackets()
        }
    }

    private fun removePendingSos(packetString: String) {
        if (pendingSosPackets.remove(packetString)) {
            persistPendingSosPackets()
        }
    }

    private fun flushPendingSosPacketsForAllEndpoints() {
        connectedEndpoints.toList().forEach { endpointId ->
            flushPendingSosPackets(endpointId)
        }
    }

    private val payloadCallback =
        object : PayloadCallback() {

            override fun onPayloadReceived(
    endpointId: String,
    payload: Payload
) {
    if (payload.type != Payload.Type.BYTES) {
        return
    }

    val bytes = payload.asBytes() ?: return
    val message = String(bytes, Charsets.UTF_8)

    android.util.Log.d(
        "WeatherGPTMesh",
        "PACKET received from $endpointId: $message"
    )

    try {
        val json = org.json.JSONObject(message)

        val packetType = json.optString(
            "packetType",
            "DATA"
        )

        val packetId = json.optString(
            "packetId"
        )

        if (packetId.isBlank()) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "Ignoring packet without packetId"
            )
            return
        }

        // ACK packets are handled separately.
        if (packetType == "ACK") {

    val ackFor =
        json.optString("ackFor")

    android.util.Log.d(
        "WeatherGPTMesh",
        "ACK received for packet: $ackFor"
    )

    if (originatedSosPacketIds.remove(ackFor)) {
        android.util.Log.d(
            "WeatherGPTMesh",
            "ACK reached originating phone: $ackFor"
        )
        reverseRoutes.remove(ackFor)
        return
    }

    val previousEndpoint =
        reverseRoutes[ackFor]

    if (previousEndpoint != null) {

        android.util.Log.d(
            "WeatherGPTMesh",
            "Forwarding ACK $ackFor -> $previousEndpoint"
        )

        Nearby.getConnectionsClient(this@MeshRelayService)
            .sendPayload(
                previousEndpoint,
                Payload.fromBytes(
                    message.toByteArray(
                        Charsets.UTF_8
                    )
                )
            )
            .addOnSuccessListener {
                android.util.Log.d(
                    "WeatherGPTMesh",
                    "ACK forwarded successfully: $ackFor"
                )

                reverseRoutes.remove(
                    ackFor
                )
            }
            .addOnFailureListener { error ->
                android.util.Log.e(
                    "WeatherGPTMesh",
                    "ACK forwarding failed: $ackFor",
                    error
                )
            }

    } else {

        android.util.Log.d(
            "WeatherGPTMesh",
            "ACK reached relay without reverse route: $ackFor"
        )
    }

    return
}

        // Duplicate protection.
        if (seenPacketIds.contains(packetId)) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Duplicate packet ignored: $packetId"
            )
            return
        }

        seenPacketIds.add(packetId)

// Remember where this packet came from.
// The gateway ACK will use this route to travel back.
        reverseRoutes[packetId] = endpointId

        handleSosPayload(message)

        forwardPacket(
            message,
            endpointId
        )

    } catch (error: Exception) {
        android.util.Log.e(
            "WeatherGPTMesh",
            "Failed to parse received packet",
            error
        )
    }
}

            override fun onPayloadTransferUpdate(
                endpointId: String,
                update: PayloadTransferUpdate
            ) {
                // Payload delivery is handled by Nearby Connections callbacks.
            }
        }

    private fun forwardPacket(
    message: String,
    excludeEndpointId: String
) {
    try {
        val json = org.json.JSONObject(message)

        val packetType = json.optString(
            "packetType",
            "DATA"
        )

        if (packetType != "DATA") {
            return
        }

        val packetId = json.optString("packetId")

        val currentHops = json.optInt(
            "hops",
            0
        )

        val currentTtl = json.optInt(
            "ttl",
            8
        )

        if (currentTtl <= 0) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "TTL expired, not forwarding: $packetId"
            )
            return
        }

        val forwardedJson =
            org.json.JSONObject(message)

        forwardedJson.put(
            "hops",
            currentHops + 1
        )

        forwardedJson.put(
            "ttl",
            currentTtl - 1
        )

        val forwardedMessage =
            forwardedJson.toString()

        if (connectedEndpoints.isEmpty()) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "No connected endpoints available for forwarding"
            )
            return
        }

        val payload =
            Payload.fromBytes(
                forwardedMessage.toByteArray(
                    Charsets.UTF_8
                )
            )

        for (endpointId in connectedEndpoints.toList()) {

            if (endpointId == excludeEndpointId) {
                continue
            }

            Nearby.getConnectionsClient(this@MeshRelayService)
                .sendPayload(
                    endpointId,
                    payload
                )
                .addOnSuccessListener {
                    android.util.Log.d(
                        "WeatherGPTMesh",
                        "Packet forwarded: $packetId -> $endpointId"
                    )
                }
                .addOnFailureListener { error ->
                    android.util.Log.e(
                        "WeatherGPTMesh",
                        "Packet forwarding failed: $endpointId",
                        error
                    )
                }
        }

    } catch (error: Exception) {
        android.util.Log.e(
            "WeatherGPTMesh",
            "Failed to forward packet",
            error
        )
    }
}

    private fun sendPacketToGateway(
    message: String
) {
    Thread {
        var connection: HttpURLConnection? = null

        try {
            val meshJson =
                org.json.JSONObject(message)

            val packetId =
                meshJson.optString("packetId")

            val phone =
                meshJson.optString("phone")

            val latitude =
                meshJson.optDouble("latitude")

            val longitude =
                meshJson.optDouble("longitude")

            val category =
                meshJson.optString(
                    "category",
                    "STRANDED"
                )

            val severity =
                meshJson.optInt(
                    "severity",
                    4
                )
            
            val locationCode =
                meshJson.optString(
                "locationCode",
                ""
            )

            val messageText =
                meshJson.optString(
                    "message",
                    ""
                )

            val gatewayJson =
                org.json.JSONObject().apply {
                    put(
                        "packet_id",
                        packetId
                    )
                    put(
                        "phone",
                        phone
                    )
                    put(
                        "latitude",
                        latitude
                    )
                    put(
                        "longitude",
                        longitude
                    )
                    put(
                        "category",
                        category
                    )
                    put(
                        "severity",
                        severity
                    )
                    put(
                        "location_code",
                        locationCode
                    )
                    put(
                        "message",
                        messageText
                    )
                }

            android.util.Log.d(
                "WeatherGPTMesh",
                "Sending SOS to gateway: $gatewayJson"
            )

            val url = URL(
                "http://192.168.1.4:8000/api/v1/sos"
            )

            connection =
                url.openConnection()
                    as HttpURLConnection

            connection.requestMethod = "POST"

            connection.setRequestProperty(
                "Content-Type",
                "application/json"
            )

            connection.doOutput = true
            connection.connectTimeout = 5000
            connection.readTimeout = 5000

            OutputStreamWriter(
                connection.outputStream
            ).use { writer ->
                writer.write(
                    gatewayJson.toString()
                )
                writer.flush()
            }

            val responseCode =
                connection.responseCode

            val responseBody =
                try {
                    connection.inputStream.bufferedReader().use { it.readText() }
                } catch (_: Exception) {
                    ""
                }

            android.util.Log.d(
                "WeatherGPTMesh",
                "Gateway response: $responseCode $responseBody"
            )

            if (responseCode in 200..299) {
                val gatewayStatus = try {
                    org.json.JSONObject(responseBody).optString("status")
                } catch (_: Exception) {
                    ""
                }

                if (gatewayStatus == "SUCCESS" || gatewayStatus == "DUPLICATE") {
                    android.util.Log.d(
                        "WeatherGPTMesh",
                        "Gateway accepted packet: $packetId ($gatewayStatus)"
                    )
                    sendGatewayAck(packetId)
                } else {
                    android.util.Log.e(
                        "WeatherGPTMesh",
                        "Gateway did not confirm packet: $packetId ($gatewayStatus)"
                    )
                }
            } else {
                android.util.Log.e(
                    "WeatherGPTMesh",
                    "Gateway rejected packet: $packetId"
                )
            }

        } catch (error: Exception) {

            android.util.Log.e(
                "WeatherGPTMesh",
                "Gateway delivery failed",
                error
            )

        } finally {
            connection?.disconnect()
        }

    }.start()
}

    private fun sendGatewayAck(
    packetId: String
) {
    val previousEndpoint =
        reverseRoutes[packetId]

    if (previousEndpoint == null) {
        android.util.Log.d(
            "WeatherGPTMesh",
            "No reverse route for ACK: $packetId"
        )
        return
    }

    val ackJson =
        org.json.JSONObject().apply {
            put(
                "packetId",
                "ACK-$packetId"
            )

            put(
                "packetType",
                "ACK"
            )

            put(
                "ackFor",
                packetId
            )

            put(
                "originId",
                "GATEWAY"
            )
        }

    android.util.Log.d(
        "WeatherGPTMesh",
        "Sending gateway ACK for $packetId -> $previousEndpoint"
    )

    Nearby.getConnectionsClient(this@MeshRelayService)
    .sendPayload(
        previousEndpoint,
        Payload.fromBytes(
            ackJson.toString()
                .toByteArray(Charsets.UTF_8)
        )
    )

        .addOnSuccessListener {

            android.util.Log.d(
                "WeatherGPTMesh",
                "Gateway ACK sent: $packetId"
            )

            reverseRoutes.remove(
                packetId
            )
        }
        .addOnFailureListener { error ->

            android.util.Log.e(
                "WeatherGPTMesh",
                "Gateway ACK failed: $packetId",
                error
            )
        }
}

    private fun handleSosPayload(message: String) {
    try {
        val json = org.json.JSONObject(message)

        val packetType = json.optString(
            "packetType",
            "DATA"
        )

        val packetId = json.optString("packetId")
        val phone = json.optString("phone")

        if (packetId.isBlank()) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "Invalid packet: missing packetId"
            )
            return
        }

        // ACK packets are handled separately.
        if (packetType == "ACK") {
            val ackFor = json.optString("ackFor")

            android.util.Log.d(
                "WeatherGPTMesh",
                "ACK received for packet: $ackFor"
            )

            return
        }

        if (packetType != "DATA") {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Ignoring unknown packet type: $packetType"
            )
            return
        }

        if (phone.isBlank()) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "Invalid DATA packet: missing phone"
            )
            return
        }

        val latitude = json.optDouble("latitude")
        val longitude = json.optDouble("longitude")
        val locationCode = json.optString(
            "locationCode",
            ""
        )
        val category = json.optString(
            "category",
            "STRANDED"
        )
        val messageText = json.optString(
            "message",
            ""
        )
        val severity = json.optInt("severity", 4)
        val hops = json.optInt("hops", 0)
        val ttl = json.optInt("ttl", 8)

        sendPacketToGateway(message)

        android.util.Log.d(
            "WeatherGPTMesh",
            "DATA packet received: $packetId"
        )

        android.util.Log.d(
            "WeatherGPTMesh",
            "Origin: $phone"
        )

        android.util.Log.d(
            "WeatherGPTMesh",
            "Hop: $hops / TTL: $ttl"
        )

        val smsBody = buildString {
    appendLine("EMERGENCY SOS ALERT")
    appendLine()
    appendLine(
        "WeatherGPT emergency packet received."
    )
    appendLine()
    appendLine("Source: $phone")

    if (locationCode.isNotBlank()) {
        appendLine("Location Code: $locationCode")
    }

    appendLine("Latitude: $latitude")
    appendLine("Longitude: $longitude")
    appendLine("Category: $category")
    appendLine("Severity: $severity")

    if (messageText.isNotBlank()) {
        appendLine()
        appendLine("Message: $messageText")
    }

    appendLine()
    appendLine("Hop: $hops")
    appendLine("TTL: $ttl")
    appendLine("SOS ID: $packetId")
    appendLine()
    appendLine(
        "Map: https://maps.google.com/?q=$latitude,$longitude"
    )
}

        // Keep the existing demo SMS path.
        sendSms(smsBody)

    } catch (error: Exception) {
        android.util.Log.e(
            "WeatherGPTMesh",
            "Failed to process SOS packet",
            error
        )
    }
}

    private fun sendSms(message: String) {

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.SEND_SMS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "SEND_SMS permission is not granted"
            )
            return
        }

        try {
            val smsManager = getSystemService(SmsManager::class.java)

            // TEMPORARY PROTOTYPE TEST NUMBER.
            // This is the number you already used successfully
            // for automatic SMS testing.
            val destination = "+919073723106"

            val parts = smsManager.divideMessage(message)

            if (parts.size <= 1) {
                smsManager.sendTextMessage(
                    destination,
                    null,
                    message,
                    null,
                    null
                )
            } else {
                smsManager.sendMultipartTextMessage(
                    destination,
                    null,
                    parts,
                    null,
                    null
                )
            }

            android.util.Log.d(
                "WeatherGPTMesh",
                "SOS packet SMS sent successfully"
            )

        } catch (error: Exception) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "Relay SMS failed",
                error
            )
        }
    }

    /*
     * TEMPORARY TEST ONLY
     *
     * Creates a fake encoded SOS packet and sends it through
     * the exact same handleSosPayload() -> sendSms() path
     * used by a real mesh packet.
     *
     * This does NOT change the Flutter UI or normal SOS flow.
     */
    private fun testRelaySms() {

        val testPacket = org.json.JSONObject().apply {
            put(
                "packetId",
                "TEST-SOS-${System.currentTimeMillis()}"
            )
            put(
                "phone",
                "+919999999999"
            )
            put(
                "latitude",
                22.5726
            )
            put(
                "longitude",
                88.3639
            )
            put(
                "severity",
                4
            )
        }

        android.util.Log.d(
            "WeatherGPTMesh",
            "TEST: Injecting SOS packet into relay"
        )

        handleSosPayload(
            testPacket.toString()
        )
    }

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "WeatherGPT Rescue Relay",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager =
                getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager

            manager.createNotificationChannel(channel)
        }
    }

    private fun sendDirectSosSms(intent: Intent) {
    val packetId =
        intent.getStringExtra("packetId") ?: return

    val phone =
        intent.getStringExtra("phone") ?: "SOS_USER"

    val latitude =
        intent.getDoubleExtra("latitude", 0.0)

    val longitude =
        intent.getDoubleExtra("longitude", 0.0)

    val locationCode =
        intent.getStringExtra("locationCode") ?: ""

    val category =
        intent.getStringExtra("category") ?: "STRANDED"

    val messageText =
        intent.getStringExtra("message") ?: ""

    val severity =
        intent.getIntExtra("severity", 4)

    // This SMS is an independent offline copy of the same logical SOS packet
    // created by the Flutter client. It does not depend on the backend or Wi-Fi.
    val packet = org.json.JSONObject().apply {
        put("packetType", "DATA")
        put("packetId", packetId)
        put("originId", "SOS_USER")
        put("ackFor", "")
        put("phone", phone)
        put("latitude", latitude)
        put("longitude", longitude)
        put("category", category)
        put("severity", severity)
        put("locationCode", locationCode)
        put("message", messageText)
        put("hops", 0)
        put("ttl", 8)
        put("timestamp", System.currentTimeMillis())
    }

    val smsBody = "WeatherGPT OFFLINE SOS PACKET\n${packet}"

    android.util.Log.d(
        "WeatherGPTMesh",
        "DIRECT SOS SMS requested: $packetId"
    )

    sendSms(smsBody)
}

private fun sendRelaySos(intent: Intent) {

    // SOS source discovers relays but does not advertise as a relay
    // unless the user explicitly enabled Rescue Relay.
    startMesh(advertise = false)

    val packetId =
        intent.getStringExtra("packetId")
            ?: "SOS-${System.currentTimeMillis()}"

    val phone =
        intent.getStringExtra("phone")
            ?: "SOS_USER"

    val latitude =
        intent.getDoubleExtra("latitude", 0.0)

    val longitude =
        intent.getDoubleExtra("longitude", 0.0)

    val locationCode =
        intent.getStringExtra("locationCode")
            ?: ""

    val category =
        intent.getStringExtra("category")
            ?: "STRANDED"

    val messageText =
        intent.getStringExtra("message")
            ?: ""

    val severity =
        intent.getIntExtra("severity", 4)

    val packet = org.json.JSONObject().apply {

        put("packetType", "DATA")
        put("packetId", packetId)
        put("originId", "SOS_USER")
        put("ackFor", "")
        put("phone", phone)

        put("latitude", latitude)
        put("longitude", longitude)

        put("category", category)
        put("severity", severity)

        put("locationCode", locationCode)
        put("message", messageText)

        put("hops", 0)
        put("ttl", 8)

        put(
            "timestamp",
            System.currentTimeMillis()
        )
    }

    val packetString =
        packet.toString()

   seenPacketIds.add(packetId)
   originatedSosPacketIds.add(packetId)

if (connectedEndpoints.isEmpty()) {

    queuePendingSos(packetString)

    android.util.Log.d(
        "WeatherGPTMesh",
        "No relay connected. SOS queued: $packetId"
    )

    return
}

val firstRelayEndpoint = connectedEndpoints.first()
reverseRoutes[packetId] = firstRelayEndpoint

    val payload =
        Payload.fromBytes(
            packetString.toByteArray(
                Charsets.UTF_8
            )
        )

    for (endpointId in connectedEndpoints.toList()) {

        Nearby.getConnectionsClient(
            this@MeshRelayService
        )
            .sendPayload(
                endpointId,
                payload
            )
            .addOnSuccessListener {

                android.util.Log.d(
                    "WeatherGPTMesh",
                    "SOS sent through Rescue Relay: $packetId -> $endpointId"
                )
            }
            .addOnFailureListener { error ->

                android.util.Log.e(
                    "WeatherGPTMesh",
                    "SOS relay send failed: $packetId -> $endpointId",
                    error
                )

                if (!pendingSosPackets.contains(packetString)) {
                    queuePendingSos(packetString)
                }
            }
    }
}

    override fun onStartCommand(
    intent: Intent?,
    flags: Int,
    startId: Int
): Int {

    // Android may recreate the service after process death.
    // Restore it only if the user explicitly enabled Rescue Relay.
    if (intent == null) {

        if (relayEnabled) {
            startRelayForeground()

            android.util.Log.d(
                "WeatherGPTMesh",
                "Restoring explicitly enabled Rescue Relay"
            )

            startMesh(advertise = true)
            flushPendingSosPacketsForAllEndpoints()

            return START_STICKY
        }

        android.util.Log.d(
            "WeatherGPTMesh",
            "Service recreated while Rescue Relay is OFF; stopping"
        )

        stopServiceCleanly(startId)
        return START_NOT_STICKY
    }

    when (intent.action) {

        ACTION_START_RELAY -> {

            setRelayEnabled(true)

            startRelayForeground()

            android.util.Log.d(
                "WeatherGPTMesh",
                "RESCUE RELAY participation enabled"
            )

            startMesh(advertise = true)
            flushPendingSosPacketsForAllEndpoints()

            return START_STICKY
        }

        ACTION_STOP_RELAY -> {

            setRelayEnabled(false)

            android.util.Log.d(
                "WeatherGPTMesh",
                "RESCUE RELAY participation disabled"
            )

            stopServiceCleanly(startId)

            return START_NOT_STICKY
        }

        ACTION_TEST_RELAY_SMS -> {

            startRelayForeground()

            android.util.Log.d(
                "WeatherGPTMesh",
                "TEST ACTION: Relay SMS requested"
            )

            testRelaySms()

            if (!relayEnabled) {
                stopServiceCleanly(startId)
                return START_NOT_STICKY
            }

            return START_STICKY
        }

        ACTION_SEND_RELAY_SOS -> {

            startRelayForeground()

            android.util.Log.d(
                "WeatherGPTMesh",
                "RESCUE RELAY SOS requested"
            )

            sendRelaySos(intent)

            // Temporary relay transport when the user has not
            // opted into persistent Rescue Relay participation.
            if (!relayEnabled) {
                android.os.Handler(mainLooper).postDelayed({

                    if (!relayEnabled) {
                        stopServiceCleanly()
                    }

                }, 30000L)

                return START_NOT_STICKY
            }

            return START_STICKY
        }

        ACTION_DIRECT_SOS_SMS -> {

            startRelayForeground()

            android.util.Log.d(
                "WeatherGPTMesh",
                "DIRECT SOS SMS requested"
            )

            sendDirectSosSms(intent)

            // SMS-only operation should not leave the relay
            // service running when persistent relay is OFF.
            if (!relayEnabled) {
                stopServiceCleanly(startId)
                return START_NOT_STICKY
            }

            return START_STICKY
        }

        else -> {

            android.util.Log.d(
                "WeatherGPTMesh",
                "Unknown service action; stopping"
            )

            stopServiceCleanly(startId)
            return START_NOT_STICKY
        }
    }
}

    override fun onDestroy() {

        val client = Nearby.getConnectionsClient(this@MeshRelayService)

        client.stopAllEndpoints()
        client.stopAdvertising()
        client.stopDiscovery()
        connectedEndpoints.clear()
        pendingConnectionEndpoints.clear()
        isAdvertising = false
        isDiscovering = false

        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Do not stop an explicitly enabled Rescue Relay when the app task is
        // dismissed. The foreground service is intentionally independent of
        // the Flutter UI lifecycle.
        if (relayEnabled) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "App task removed; Rescue Relay remains active"
            )
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {
        return null
    }
}