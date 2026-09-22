package com.example.flutter_application_2

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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
    }

    private val strategy = Strategy.P2P_CLUSTER

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        val notification: Notification =
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("WeatherGPT Mesh Relay")
                .setContentText("Emergency relay is active")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .build()

        startForeground(NOTIFICATION_ID, notification)

        startMesh()
    }

    private fun startMesh() {
        val client = Nearby.getConnectionsClient(this)

        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(strategy)
            .build()

        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(strategy)
            .build()

        client.startAdvertising(
            ENDPOINT_NAME,
            SERVICE_ID,
            connectionLifecycleCallback,
            advertisingOptions
        ).addOnSuccessListener {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Advertising started"
            )
        }.addOnFailureListener { error ->
            android.util.Log.e(
                "WeatherGPTMesh",
                "Advertising failed",
                error
            )
        }

        client.startDiscovery(
            SERVICE_ID,
            endpointDiscoveryCallback,
            discoveryOptions
        ).addOnSuccessListener {
            android.util.Log.d(
                "WeatherGPTMesh",
                "Discovery started"
            )
        }.addOnFailureListener { error ->
            android.util.Log.e(
                "WeatherGPTMesh",
                "Discovery failed",
                error
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
                    "Found endpoint: $endpointId ${info.endpointName}"
                )

                Nearby.getConnectionsClient(this@MeshRelayService)
                    .requestConnection(
                        ENDPOINT_NAME,
                        endpointId,
                        connectionLifecycleCallback
                    )
                    .addOnSuccessListener {
                        android.util.Log.d(
                            "WeatherGPTMesh",
                            "Connection requested: $endpointId"
                        )
                    }
                    .addOnFailureListener { error ->
                        android.util.Log.e(
                            "WeatherGPTMesh",
                            "Connection request failed",
                            error
                        )
                    }
            }

            override fun onEndpointLost(endpointId: String) {
                android.util.Log.d(
                    "WeatherGPTMesh",
                    "Endpoint lost: $endpointId"
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
                    "Accepting connection from $endpointId"
                )

                Nearby.getConnectionsClient(this@MeshRelayService)
                    .acceptConnection(
                        endpointId,
                        payloadCallback
                    )
            }

            override fun onConnectionResult(
                endpointId: String,
                result: ConnectionResolution
            ) {
                android.util.Log.d(
                    "WeatherGPTMesh",
                    "Connection result $endpointId: ${result.status.statusCode}"
                )
            }

            override fun onDisconnected(endpointId: String) {
                android.util.Log.d(
                    "WeatherGPTMesh",
                    "Disconnected: $endpointId"
                )
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
                    "SOS received: $message"
                )

                handleSosPayload(message)
            }

            override fun onPayloadTransferUpdate(
                endpointId: String,
                update: PayloadTransferUpdate
            ) {
                // Not needed for prototype.
            }
        }

    private fun handleSosPayload(message: String) {
        try {
            val json = org.json.JSONObject(message)

            val packetId = json.optString("packetId")
            val phone = json.optString("phone")

            if (packetId.isBlank() || phone.isBlank()) {
                android.util.Log.e(
                    "WeatherGPTMesh",
                    "Invalid SOS packet"
                )
                return
            }

            val latitude = json.optDouble("latitude")
            val longitude = json.optDouble("longitude")
            val severity = json.optInt("severity", 4)

            val smsBody = buildString {
                appendLine("EMERGENCY SOS ALERT")
                appendLine()
                appendLine(
                    "WeatherGPT mesh relay received an emergency packet."
                )
                appendLine()
                appendLine("Source: $phone")
                appendLine("Latitude: $latitude")
                appendLine("Longitude: $longitude")
                appendLine("Severity: $severity")
                appendLine("SOS ID: $packetId")
                appendLine()
                appendLine(
                    "Map: https://maps.google.com/?q=$latitude,$longitude"
                )
            }

            sendSms(smsBody)

        } catch (error: Exception) {
            android.util.Log.e(
                "WeatherGPTMesh",
                "Failed to process SOS",
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

            smsManager.sendTextMessage(
                destination,
                null,
                message,
                null,
                null
            )

            android.util.Log.d(
                "WeatherGPTMesh",
                "Relay SMS sent successfully"
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
                "WeatherGPT Mesh Relay",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager =
                getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager

            manager.createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        /*
         * Temporary test trigger.
         *
         * The normal service startup remains unchanged.
         */
        if (
            intent?.action ==
            ACTION_TEST_RELAY_SMS
        ) {
            android.util.Log.d(
                "WeatherGPTMesh",
                "TEST ACTION: Relay SMS requested"
            )

            testRelaySms()
        }

        return START_STICKY
    }

    override fun onDestroy() {

        val client = Nearby.getConnectionsClient(this)

        client.stopAllEndpoints()
        client.stopAdvertising()
        client.stopDiscovery()

        super.onDestroy()
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {
        return null
    }
}