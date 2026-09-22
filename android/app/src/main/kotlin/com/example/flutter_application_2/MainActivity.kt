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

                "startRelay" -> {
                    try {
                        Log.d(
                            "WeatherGPTBridge",
                            "Starting MeshRelayService"
                        )

                        val intent =
                            Intent(
                                this,
                                MeshRelayService::class.java
                            )

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        Log.d(
                            "WeatherGPTBridge",
                            "MeshRelayService start requested"
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
                        val intent =
                            Intent(
                                this,
                                MeshRelayService::class.java
                            )

                        stopService(intent)

                        Log.d(
                            "WeatherGPTBridge",
                            "MeshRelayService stopped"
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