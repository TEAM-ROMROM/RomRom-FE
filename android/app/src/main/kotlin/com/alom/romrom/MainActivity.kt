package com.alom.romrom

import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "romrom/navigation_mode"
    private val NATIVE_AD_FACTORY_ID = "feedNativeAd"
    // 목록 광고 팩토리 ID (lib/widgets/list_native_ad/list_native_ad_cell.dart listNativeAdFactoryId와 같은 값)
    private val LIST_NATIVE_AD_FACTORY_ID = "listNativeAd"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 홈 피드 네이티브 광고 팩토리 등록
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            NATIVE_AD_FACTORY_ID,
            FeedNativeAdFactory(this)
        )

        // 목록(채팅·좋아요·내 물품) 네이티브 광고 팩토리 등록
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            LIST_NATIVE_AD_FACTORY_ID,
            ListNativeAdFactory(this)
        )

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

    override fun onDestroy() {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, NATIVE_AD_FACTORY_ID)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, LIST_NATIVE_AD_FACTORY_ID)
        super.onDestroy()
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
