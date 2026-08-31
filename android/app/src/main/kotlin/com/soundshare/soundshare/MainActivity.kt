package com.soundshare.soundshare

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val audioChannel = "com.soundshare/audio"
    private val btChannel = "com.soundshare/bluetooth"
    private val beatSyncChannel = "com.soundshare/beatsync"
    private val beatSyncEventsChannel = "com.soundshare/beatsync_events"
    private val spatialAudioChannel = "com.soundshare/spatial_audio"
    private val spatialAudioEventsChannel = "com.soundshare/spatial_audio_events"

    private var beatSyncEngine: BeatSyncNativeEngine? = null
    private var spatialAudioEngine: SpatialAudioNativeEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        beatSyncEngine = BeatSyncNativeEngine(applicationContext)
        spatialAudioEngine = SpatialAudioNativeEngine(applicationContext)

        // Spatial Audio Channels
        val spatialMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, spatialAudioChannel)
        val spatialEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, spatialAudioEventsChannel)
        spatialAudioEngine?.registerChannels(spatialMethodChannel, spatialEventChannel)

        // BeatSync Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, beatSyncEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    beatSyncEngine?.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    beatSyncEngine?.setEventSink(null)
                }
            })

        // BeatSync Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, beatSyncChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapabilities" -> {
                        result.success(beatSyncEngine?.getCapabilities() ?: emptyMap<String, Any>())
                    }
                    "startBeatSync" -> {
                        val success = beatSyncEngine?.startAnalysis() ?: false
                        result.success(success)
                    }
                    "stopBeatSync" -> {
                        beatSyncEngine?.stopAnalysis()
                        result.success(true)
                    }
                    "updateSettings" -> {
                        val intensity = call.argument<Double>("intensity") ?: 1.0
                        val sensitivity = call.argument<Double>("sensitivity") ?: 1.0
                        val bass = call.argument<Double>("bass") ?: 1.0
                        beatSyncEngine?.updateSettings(intensity, sensitivity, bass)
                        result.success(true)
                    }
                    "testPulse" -> {
                        beatSyncEngine?.triggerTestPulse()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Audio method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canShareAudio" -> {
                        result.success(checkAudioSharingCapability())
                    }
                    "getAudioOutputDevices" -> {
                        result.success(getAudioOutputDevices())
                    }
                    "getActiveOutputDevice" -> {
                        result.success(getActiveOutputDevice())
                    }
                    "startForegroundService" -> {
                        AudioShareForegroundService.startService(this)
                        result.success(true)
                    }
                    "stopForegroundService" -> {
                        AudioShareForegroundService.stopService(this)
                        result.success(true)
                    }
                    "openPlayStore" -> {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(webIntent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Bluetooth info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, btChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBluetoothEnabled" -> {
                        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                        result.success(btManager?.adapter?.isEnabled ?: false)
                    }
                    "getConnectedDevices" -> {
                        result.success(getBluetoothConnectedDevices())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkAudioSharingCapability(): Map<String, Any> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val canShare: Boolean
        val reason: String

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            canShare = true
            reason = "android_audio_routing"
        } else {
            canShare = false
            reason = "android_version_unsupported"
        }

        return mapOf(
            "canShare" to canShare,
            "reason" to reason,
            "androidVersion" to Build.VERSION.SDK_INT
        )
    }

    private fun getAudioOutputDevices(): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = mutableListOf<Map<String, Any>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).forEach { device ->
                devices.add(
                    mapOf(
                        "id" to device.id,
                        "type" to device.type,
                        "productName" to device.productName.toString(),
                        "address" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address else "")
                    )
                )
            }
        }

        return devices
    }

    private fun getActiveOutputDevice(): Map<String, Any> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return mapOf(
            "isBluetoothA2dpOn" to audioManager.isBluetoothA2dpOn,
            "isHeadsetOn" to audioManager.isWiredHeadsetOn,
            "isSpeakerphoneOn" to audioManager.isSpeakerphoneOn
        )
    }

    @Suppress("MissingPermission")
    private fun getBluetoothConnectedDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: return devices

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                return devices
            }

            val connectedDevices = adapter.bondedDevices ?: return devices
            connectedDevices.forEach { device ->
                devices.add(
                    mapOf(
                        "address" to device.address,
                        "name" to (device.name ?: "Unknown"),
                        "type" to device.type,
                        "bondState" to device.bondState
                    )
                )
            }
        } catch (e: Exception) {
        }
        return devices
    }

    override fun onDestroy() {
        beatSyncEngine?.stopAnalysis()
        spatialAudioEngine?.dispose()
        super.onDestroy()
    }
}
