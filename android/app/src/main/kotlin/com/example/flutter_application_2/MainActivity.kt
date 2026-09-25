package com.example.flutter_application_2

import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "weathergpt/mesh_relay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getRelayStatus" -> {
                    try {
                        val enabled = getSharedPreferences(
                            "weathergpt_rescue_relay",
                            MODE_PRIVATE
                        ).getBoolean("relay_enabled", false)

                        result.success(enabled)
                    } catch (e: Exception) {
                        result.error(
                            "RELAY_STATUS_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "startRelay" -> {
                    try {
                        Log.d(
                            "WeatherGPTBridge",
                            "Starting Rescue Relay service"
                        )

                        val intent =
                            Intent(
                                this,
                                MeshRelayService::class.java
                            ).apply {
                                action = MeshRelayService.ACTION_START_RELAY
                            }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        Log.d(
                            "WeatherGPTBridge",
                            "Rescue Relay start requested"
                        )

                        result.success(true)

                    } catch (e: Exception) {
                        Log.e(
                            "WeatherGPTBridge",
                            "Failed to start MeshRelayService",
                            e
                        )

                        result.error(
                            "RELAY_START_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "sendDirectSosSms" -> {
    try {
        Log.d(
            "WeatherGPTBridge",
            "Sending direct SOS SMS"
        )

        val intent =
            Intent(
                this,
                MeshRelayService::class.java
            ).apply {
                action =
                    MeshRelayService.ACTION_DIRECT_SOS_SMS

                putExtra(
                    "packetId",
                    call.argument<String>("packetId")
                )

                putExtra(
                    "phone",
                    call.argument<String>("phone")
                )

                putExtra(
                    "latitude",
                    call.argument<Double>("latitude") ?: 0.0
                )

                putExtra(
                    "longitude",
                    call.argument<Double>("longitude") ?: 0.0
                )

                putExtra(
                    "locationCode",
                    call.argument<String>("locationCode") ?: ""
                )

                putExtra(
                    "category",
                    call.argument<String>("category") ?: "STRANDED"
                )

                putExtra(
                    "message",
                    call.argument<String>("message") ?: ""
                )

                putExtra(
                    "severity",
                    call.argument<Int>("severity") ?: 4
                )
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }

        Log.d(
            "WeatherGPTBridge",
            "Direct SOS SMS requested"
        )

        result.success(true)

    } catch (e: Exception) {
        Log.e(
            "WeatherGPTBridge",
            "Direct SOS SMS failed",
            e
        )

        result.error(
            "DIRECT_SOS_SMS_FAILED",
            e.message,
            null
        )
    }
}

"sendRelaySos" -> {
    try {
        Log.d(
            "WeatherGPTBridge",
            "Sending SOS through Rescue Relay"
        )

        val intent =
            Intent(
                this,
                MeshRelayService::class.java
            ).apply {
                action =
                    MeshRelayService.ACTION_SEND_RELAY_SOS

                putExtra(
                    "packetId",
                    call.argument<String>("packetId")
                )

                putExtra(
                    "phone",
                    call.argument<String>("phone") ?: "SOS_USER"
                )

                putExtra(
                    "latitude",
                    call.argument<Double>("latitude") ?: 0.0
                )

                putExtra(
                    "longitude",
                    call.argument<Double>("longitude") ?: 0.0
                )

                putExtra(
                    "locationCode",
                    call.argument<String>("locationCode") ?: ""
                )

                putExtra(
                    "category",
                    call.argument<String>("category") ?: "STRANDED"
                )

                putExtra(
                    "message",
                    call.argument<String>("message") ?: ""
                )

                putExtra(
                    "severity",
                    call.argument<Int>("severity") ?: 4
                )
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }

        Log.d(
            "WeatherGPTBridge",
            "Rescue Relay SOS requested"
        )

        result.success(true)

    } catch (e: Exception) {
        Log.e(
            "WeatherGPTBridge",
            "Rescue Relay SOS failed",
            e
        )

        result.error(
            "RELAY_SOS_FAILED",
            e.message,
            null
        )
    }
}

                "testRelaySms" -> {
                    try {
                        Log.d(
                            "WeatherGPTBridge",
                            "Starting relay SMS test"
                        )

                        val intent =
                            Intent(
                                this,
                                MeshRelayService::class.java
                            ).apply {
                                action =
                                    MeshRelayService.ACTION_TEST_RELAY_SMS
                            }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        Log.d(
                            "WeatherGPTBridge",
                            "Relay SMS test requested"
                        )

                        result.success(true)

                    } catch (e: Exception) {
                        Log.e(
                            "WeatherGPTBridge",
                            "Relay SMS test failed",
                            e
                        )

                        result.error(
                            "RELAY_TEST_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "stopRelay" -> {
                    try {
                        getSharedPreferences(
                            "weathergpt_rescue_relay",
                            MODE_PRIVATE
                        ).edit()
                            .putBoolean("relay_enabled", false)
                            .apply()

                        val intent =
                            Intent(
                                this,
                                MeshRelayService::class.java
                            )

                        stopService(intent)

                        Log.d(
                            "WeatherGPTBridge",
                            "Rescue Relay stopped"
                        )

                        result.success(true)

                    } catch (e: Exception) {
                        Log.e(
                            "WeatherGPTBridge",
                            "Failed to stop MeshRelayService",
                            e
                        )

                        result.error(
                            "RELAY_STOP_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}