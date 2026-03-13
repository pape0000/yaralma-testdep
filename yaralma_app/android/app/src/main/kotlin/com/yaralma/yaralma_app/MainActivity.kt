package com.yaralma.yaralma_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val settingsChannel = "com.yaralma.yaralma_app/settings"
    private val prefsChannel = "com.yaralma.yaralma_app/prefs"
    private val wolofChannel = "com.yaralma.yaralma_app/wolof"

    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val REQUEST_MEDIA_PROJECTION = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Settings channel (accessibility)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannel).setMethodCallHandler { call, result ->
            if (call.method == "openAccessibilitySettings") {
                try {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // SharedPreferences channel (for syncing data to Accessibility Service)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, prefsChannel).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("yaralma_override", Context.MODE_PRIVATE)

            when (call.method) {
                "setBlockedKeywords" -> {
                    val keywords = call.argument<String>("keywords") ?: ""
                    prefs.edit().putString("blocked_keywords", keywords).apply()
                    result.success(true)
                }
                "setIsLocked" -> {
                    val locked = call.argument<Boolean>("locked") ?: false
                    prefs.edit().putBoolean("is_locked", locked).apply()
                    result.success(true)
                }
                "getSearchesBlockedToday" -> {
                    val count = prefs.getInt("searches_blocked_today", 0)
                    result.success(count)
                }
                "resetSearchesBlockedToday" -> {
                    prefs.edit().putInt("searches_blocked_today", 0).apply()
                    result.success(true)
                }
                "setHiddenTitles" -> {
                    val titles = call.argument<String>("titles") ?: ""
                    prefs.edit().putString("hidden_titles", titles).apply()
                    result.success(true)
                }
                "setBlurScenes" -> {
                    val scenes = call.argument<String>("scenes") ?: ""
                    prefs.edit().putString("blur_scenes", scenes).apply()
                    result.success(true)
                }
                "setWolofApiUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    prefs.edit().putString("wolof_api_url", url).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Wolof Guardian channel (audio capture)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wolofChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAudioCapture" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        pendingResult = result
                        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
                    } else {
                        result.error("UNSUPPORTED", "Audio capture requires Android 10+", null)
                    }
                }
                "stopAudioCapture" -> {
                    val intent = Intent(this, WolofAudioService::class.java).apply {
                        action = WolofAudioService.ACTION_STOP
                    }
                    stopService(intent)
                    result.success(true)
                }
                "isAudioCaptureSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Start the foreground service with media projection
                val serviceIntent = Intent(this, WolofAudioService::class.java).apply {
                    action = WolofAudioService.ACTION_START
                    putExtra(WolofAudioService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(WolofAudioService.EXTRA_RESULT_DATA, data)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                pendingResult?.success(true)
            } else {
                pendingResult?.error("DENIED", "Media projection permission denied", null)
            }
            pendingResult = null
        }
    }
}
