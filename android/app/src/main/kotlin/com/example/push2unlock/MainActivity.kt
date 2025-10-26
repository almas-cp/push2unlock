package com.example.push2unlock

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.push2unlock/app_control"
    private val TAG = "Push2Unlock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    try {
                        bringAppToForeground()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error bringing app to foreground: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "checkOverlayPermission" -> {
                    val hasPermission = checkOverlayPermission()
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun bringAppToForeground() {
        Log.d(TAG, "🚀 Attempting to bring app to foreground...")
        
        // Check if we have overlay permission
        if (!checkOverlayPermission()) {
            Log.w(TAG, "⚠️ Overlay permission not granted! Cannot force app to foreground.")
            Log.w(TAG, "💡 Request overlay permission from Flutter side first.")
        }
        
        try {
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            startActivity(intent)
            Log.d(TAG, "✅ Activity launched successfully!")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error bringing app to foreground: ${e.message}", e)
        }
    }
}
