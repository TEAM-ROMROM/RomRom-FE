package com.alom.romrom

import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "romrom/navigation_mode"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "isGesture") {
                val isGesture = isGestureNavigationEnabled()
                result.success(isGesture)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isGestureNavigationEnabled(): Boolean {
        val navMode = Settings.Secure.getInt(
            contentResolver,
            "navigation_mode",
            0
        )
        // 2 = gesture, 0 or 1 = buttons
        return navMode == 2
    }
}
