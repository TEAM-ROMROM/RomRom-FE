package com.alom.romrom

import android.content.Context
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/// 홈 피드용 네이티브 광고 팩토리
class FeedNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = NativeAdView(context)
        // 배경 클릭 방지 (빈 공간 클릭 금지 정책)
        nativeAdView.isClickable = false

        // ── 광고 배지 ("광고" 텍스트, 최소 15×15px) ──────────────────────
        val adBadge = TextView(context).apply {
            text = "광고"
            textSize = 10f
            setTextColor(android.graphics.Color.WHITE)
            setBackgroundColor(android.graphics.Color.parseColor("#4D4D4D"))
            setPadding(8, 4, 8, 4)
            minWidth = 15
            minHeight = 15
        }

        // ── 아이콘 (앱 아이콘 / 광고 로고) ───────────────────────────────
        val iconView = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            adjustViewBounds = true
        }
        nativeAdView.iconView = iconView

        // ── 메인 미디어 (이미지 또는 영상) ───────────────────────────────
        val mediaView = MediaView(context).apply {
            mediaContent = nativeAd.mediaContent
            isClickable = false // 배경 클릭 방지
        }
        nativeAdView.mediaView = mediaView

        // ── 헤드라인 ─────────────────────────────────────────────────────
        val headlineView = TextView(context).apply {
            textSize = 16f
            setTextColor(android.graphics.Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
            maxLines = 2
        }
        nativeAdView.headlineView = headlineView
        headlineView.text = nativeAd.headline

        // ── 본문 ─────────────────────────────────────────────────────────
        val bodyView = TextView(context).apply {
            textSize = 12f
            setTextColor(android.graphics.Color.LTGRAY)
            maxLines = 4 // 90자 잘림 방지 여유
        }
        nativeAdView.bodyView = bodyView
        bodyView.text = nativeAd.body

        // ── CTA 버튼 ─────────────────────────────────────────────────────
        val ctaButton = Button(context).apply {
            text = nativeAd.callToAction
            setBackgroundColor(android.graphics.Color.parseColor("#FFD700"))
            setTextColor(android.graphics.Color.BLACK)
        }
        nativeAdView.callToActionView = ctaButton

        // ── 레이아웃 구성 ─────────────────────────────────────────────────
        val contentLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 48, 48, 48)
            setBackgroundColor(android.graphics.Color.parseColor("#1A1A1A"))
            gravity = android.view.Gravity.CENTER_VERTICAL
            isClickable = false // 배경 클릭 방지
        }

        // 상단 행: 아이콘 + 헤드라인 + 광고 배지
        val topRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER_VERTICAL
            isClickable = false
        }

        val iconParams = LinearLayout.LayoutParams(64, 64).apply { rightMargin = 12 }
        topRow.addView(iconView, iconParams)

        topRow.addView(
            headlineView,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
        )

        val badgeParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { leftMargin = 8 }
        topRow.addView(adBadge, badgeParams)

        val topRowParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { bottomMargin = 16 }
        contentLayout.addView(topRow, topRowParams)

        // 미디어
        val mediaParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 600,
        ).apply { bottomMargin = 16 }
        contentLayout.addView(mediaView, mediaParams)

        // 본문
        val bodyParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { bottomMargin = 16 }
        contentLayout.addView(bodyView, bodyParams)

        // CTA 버튼
        contentLayout.addView(
            ctaButton,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 120),
        )

        nativeAdView.addView(
            contentLayout,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )

        // 에셋 바인딩
        nativeAd.icon?.let { iconView.setImageDrawable(it.drawable) }
        nativeAdView.setNativeAd(nativeAd)

        return nativeAdView
    }
}
