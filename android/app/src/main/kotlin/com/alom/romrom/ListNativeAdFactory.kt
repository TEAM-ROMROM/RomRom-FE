package com.alom.romrom

import android.content.Context
import android.graphics.Outline
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/// 목록(채팅·좋아요·내 물품) 네이티브 광고 팩토리: [아이콘] [광고 배지 + 헤드라인 / 본문] [CTA] 한 줄
/// 치수·글자·색은 Dart ListNativeAdStyle customOptions에서 받음 (dp), AdChoices는 SDK가 오른쪽 위에 자동 배치
class ListNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    private val density = context.resources.displayMetrics.density

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val options = FeedNativeAdOptions(customOptions ?: emptyMap<String, Any>())
        val nativeAdView = NativeAdView(context)
        // 목록 행과 다른 바탕 (AppColors.listNativeAdBackground, 콘텐츠 위장 금지)
        nativeAdView.background = GradientDrawable().apply {
            setColor(options.color("backgroundColorArgb", 0xFF282933.toInt()))
            cornerRadius = toPx(options.number("cornerRadius", 12f))
        }
        nativeAdView.clipToOutline = true

        // ── 아이콘: 없으면 숨김 ──────────────────────────────────────
        val iconCornerRadiusPx = toPx(options.number("iconCornerRadius", 8f))
        val iconView = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, iconCornerRadiusPx)
                }
            }
            clipToOutline = true
            val iconDrawable = nativeAd.icon?.drawable
            setImageDrawable(iconDrawable)
            visibility = if (iconDrawable == null) View.GONE else View.VISIBLE
        }
        nativeAdView.iconView = iconView

        // ── 광고 배지: 정책상 필수 표시 ─────────────────────────────────
        val badgeOptions = options.nested("adBadge")
        val adBadge = TextView(context).apply {
            applyTextStyle(this, badgeOptions.nested("text"), 10f, 0xFF1D1E27.toInt())
            text = badgeOptions.string("label", "광고")
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(badgeOptions.color("backgroundColorArgb", 0xFFFFF1C4.toInt()))
                cornerRadius = toPx(badgeOptions.number("cornerRadius", 4f))
            }
            val horizontalPaddingPx = toPx(badgeOptions.number("horizontalPadding", 6f)).toInt()
            val verticalPaddingPx = toPx(badgeOptions.number("verticalPadding", 3f)).toInt()
            setPadding(horizontalPaddingPx, verticalPaddingPx, horizontalPaddingPx, verticalPaddingPx)
        }

        // ── 헤드라인 (필수 애셋, 1줄 말줄임) ───────────────────────────
        val headlineView = TextView(context).apply {
            applyTextStyle(this, options.nested("headlineText"), 14f, 0xFFFFFFFF.toInt())
            text = nativeAd.headline
        }
        nativeAdView.headlineView = headlineView

        // ── 본문 (없으면 숨김) ─────────────────────────────────────────
        val bodyView = TextView(context).apply {
            applyTextStyle(this, options.nested("bodyText"), 12f, 0x99FFFFFF.toInt())
            text = nativeAd.body
            visibility = if (nativeAd.body.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        nativeAdView.bodyView = bodyView

        // ── CTA: 알약 버튼 모양 (없으면 숨김) ──────────────────────────
        val callToActionOptions = options.nested("callToAction")
        val callToActionHeightPx = toPx(callToActionOptions.number("height", 32f)).toInt()
        val callToActionView = TextView(context).apply {
            applyTextStyle(this, callToActionOptions.nested("text"), 12f, 0xFF1D1E27.toInt())
            text = nativeAd.callToAction
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(callToActionOptions.color("backgroundColorArgb", 0xFFFFC300.toInt()))
                cornerRadius = callToActionHeightPx / 2f
            }
            val horizontalPaddingPx = toPx(callToActionOptions.number("horizontalPadding", 12f)).toInt()
            setPadding(horizontalPaddingPx, 0, horizontalPaddingPx, 0)
            maxWidth = toPx(callToActionOptions.number("maximumWidth", 96f)).toInt()
            visibility = if (nativeAd.callToAction.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        nativeAdView.callToActionView = callToActionView

        // ── 배치: 아이콘 > 글자 2줄 > CTA (세로 가운데, 숨긴 애셋은 간격째 빠짐) ──
        val firstLineLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        firstLineLayout.addView(adBadge, wrapContentParams())
        firstLineLayout.addView(
            headlineView,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = toPx(options.number("badgeToHeadlineGap", 6f)).toInt()
            },
        )

        val textLayout = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        textLayout.addView(
            firstLineLayout,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT),
        )
        textLayout.addView(
            bodyView,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = toPx(options.number("headlineToBodyGap", 4f)).toInt()
            },
        )

        val horizontalPaddingPx = toPx(options.number("innerHorizontalPadding", 12f)).toInt()
        val rowLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(horizontalPaddingPx, 0, horizontalPaddingPx, 0)
        }
        val iconSizePx = toPx(options.number("iconSize", 44f)).toInt()
        rowLayout.addView(iconView, LinearLayout.LayoutParams(iconSizePx, iconSizePx))
        rowLayout.addView(
            textLayout,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                // 아이콘 숨김이면 간격도 없음
                marginStart = if (iconView.visibility == View.GONE) 0 else toPx(options.number("iconToTextGap", 12f)).toInt()
            },
        )
        rowLayout.addView(
            callToActionView,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, callToActionHeightPx).apply {
                marginStart = toPx(options.number("textToCallToActionGap", 12f)).toInt()
            },
        )

        nativeAdView.addView(
            rowLayout,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )

        // 애셋 뷰 지정 후 마지막에 연결 (SDK 요구 순서)
        nativeAdView.setNativeAd(nativeAd)
        return nativeAdView
    }

    private fun wrapContentParams(): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)

    /// 글자 스타일 옵션(크기·폰트 파일·색) > 1줄 말줄임 TextView
    private fun applyTextStyle(textView: TextView, options: FeedNativeAdOptions, fallbackFontSize: Float, fallbackColorArgb: Int) {
        // Dart에서 앱 글자 배율 반영한 값이라 시스템 글자 배율 재적용 방지 (DIP)
        textView.setTextSize(TypedValue.COMPLEX_UNIT_DIP, options.number("fontSize", fallbackFontSize))
        textView.typeface = PretendardTypefaces.typeface(
            context,
            options.string("fontAssetPath", "assets/fonts/pretendard/Pretendard-SemiBold.otf"),
        )
        textView.setTextColor(options.color("colorArgb", fallbackColorArgb))
        textView.maxLines = options.integer("maxLines", 1)
        textView.ellipsize = TextUtils.TruncateAt.END
        textView.includeFontPadding = false
    }

    private fun toPx(dp: Float): Float = dp * density
}
