package com.alom.romrom

import android.content.Context
import android.graphics.Canvas
import android.graphics.Outline
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
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
import android.widget.RelativeLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.FlutterInjector
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/// 홈 피드 네이티브 광고 팩토리: 물품 카드(HomeFeedItemWidget)와 같은 레이아웃
/// 치수·글자·색은 Dart HomeFeedNativeAdStyle customOptions에서 받음 (dp 값, 없으면 393x852 기준 기본값)
class FeedNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    // Pretendard 폰트 파일 경로 > Typeface (팩토리 1개, 메인 스레드 호출)
    private val typefaceByAssetPath = mutableMapOf<String, Typeface>()
    private val density = context.resources.displayMetrics.density

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val options = FeedNativeAdOptions(customOptions ?: emptyMap<String, Any>())
        val nativeAdView = NativeAdView(context)
        // 물품 카드 바탕 (AppColors.homeFeedCardBackground)
        nativeAdView.setBackgroundColor(options.color("cardBackgroundColorArgb", 0xFF000000.toInt()))

        // ── 메인 미디어: 물품 사진 자리, 카드 이미지 모서리(위 4, 아래 20) ──────────
        val mediaContainer = CornerClippingFrameLayout(
            context,
            topRadiusPx = toPx(options.number("mediaTopCornerRadius", 4f)),
            bottomRadiusPx = toPx(options.number("mediaBottomCornerRadius", 20f)),
        ).apply { id = View.generateViewId() }
        val mediaView = MediaView(context).apply {
            mediaContent = nativeAd.mediaContent
            // 물품 사진 BoxFit.cover와 동일 (비율 유지, 넘치는 부분만 잘림)
            setImageScaleType(ImageView.ScaleType.CENTER_CROP)
        }
        mediaContainer.addView(
            mediaView,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        nativeAdView.mediaView = mediaView

        // ── 헤드라인: 물품 이름 자리 (HomeFeedItemSummary.titleTextStyle) ──────────
        val headlineView = TextView(context).apply {
            applyTextStyle(this, options.nested("headlineText"), FeedNativeAdTextFallback.HEADLINE)
            text = nativeAd.headline
        }
        nativeAdView.headlineView = headlineView

        // ── 본문: 위치·등록일 줄 자리 (HomeFeedItemSummary.metaTextStyle) ──────────
        val bodyView = TextView(context).apply {
            applyTextStyle(this, options.nested("bodyText"), FeedNativeAdTextFallback.BODY)
            text = nativeAd.body
            visibility = if (nativeAd.body.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        nativeAdView.bodyView = bodyView

        // ── 광고 배지: 사용감 태그 자리·모양 (ItemDetailConditionTag, 정책상 필수 표시) ──
        val badgeOptions = options.nested("adBadge")
        val adBadge = TextView(context).apply {
            applyTextStyle(this, badgeOptions.nested("text"), FeedNativeAdTextFallback.AD_BADGE)
            text = badgeOptions.string("label", "광고")
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(badgeOptions.color("backgroundColorArgb", 0xFFFFF1C4.toInt()))
                // 높이 절반보다 큰 반경은 알약 모양으로 그려짐
                cornerRadius = toPx(badgeOptions.number("cornerRadius", 100f))
            }
            val horizontalPaddingPx = toPx(badgeOptions.number("horizontalPadding", 8f)).toInt()
            val verticalPaddingPx = toPx(badgeOptions.number("verticalPadding", 6f)).toInt()
            setPadding(horizontalPaddingPx, verticalPaddingPx, horizontalPaddingPx, verticalPaddingPx)
            // 사용감 태그 최소 50x23 (정책 최소 15x15 충족)
            minWidth = toPx(badgeOptions.number("minWidth", 50f)).toInt()
            minHeight = toPx(badgeOptions.number("minHeight", 23f)).toInt()
        }

        // ── CTA: 가격 줄 자리 (HomeFeedItemSummary.priceTextStyle) ────────────────
        val callToActionView = TextView(context).apply {
            applyTextStyle(this, options.nested("callToActionText"), FeedNativeAdTextFallback.CALL_TO_ACTION)
            text = nativeAd.callToAction
            visibility = if (nativeAd.callToAction.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        nativeAdView.callToActionView = callToActionView

        // ── 아이콘: 작성자 프로필 자리 (원형, HomeFeedCardLayout.profileAvatarSize) ──
        val iconView = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
            val iconDrawable = nativeAd.icon?.drawable
            setImageDrawable(iconDrawable)
            visibility = if (iconDrawable == null) View.GONE else View.VISIBLE
        }
        nativeAdView.iconView = iconView

        // ── 정보 패널: 이름 > 위치 > 태그 > 가격 (아래 여백으로 간격, 숨긴 줄은 간격도 함께 빠짐) ──
        val summaryLayout = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        summaryLayout.addView(headlineView, verticalItemParams(options.number("titleToMetaGap", 8f)))
        summaryLayout.addView(bodyView, verticalItemParams(options.number("metaToTagGap", 12f)))
        summaryLayout.addView(
            adBadge,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = toPx(options.number("tagToPriceGap", 10f)).toInt()
            },
        )
        summaryLayout.addView(callToActionView, verticalItemParams(0f))

        val infoRow = LinearLayout(context).apply {
            id = View.generateViewId()
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.TOP
        }
        // 남는 가로 폭은 요약이 차지 (Flutter Expanded)
        infoRow.addView(summaryLayout, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        val iconSizePx = toPx(options.number("iconSize", 50f)).toInt()
        infoRow.addView(iconView, LinearLayout.LayoutParams(iconSizePx, iconSizePx))

        // ── AdChoices: 광고 슬롯에서 숨긴 신고 버튼 자리 (정책상 필수, setNativeAd 전에 설정) ──
        val adChoicesView = AdChoicesView(context).apply {
            minimumWidth = toPx(15f).toInt()
            minimumHeight = toPx(15f).toInt()
        }

        // ── 배치: 미디어(위) ~ 정보 패널(아래, 카드 덱 위), 광고 애셋 위에 글자 겹침 없음 ──
        val horizontalPaddingPx = toPx(options.number("infoPanelHorizontalPadding", 24f)).toInt()
        val rootLayout = RelativeLayout(context)
        rootLayout.addView(
            infoRow,
            RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                leftMargin = horizontalPaddingPx
                rightMargin = horizontalPaddingPx
                bottomMargin = toPx(options.number("infoPanelBottomInset", 110f)).toInt()
            },
        )
        rootLayout.addView(
            mediaContainer,
            RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT).apply {
                addRule(RelativeLayout.ALIGN_PARENT_TOP)
                addRule(RelativeLayout.ABOVE, infoRow.id)
                bottomMargin = toPx(options.number("mediaToInfoPanelGap", 24f)).toInt()
            },
        )
        rootLayout.addView(
            adChoicesView,
            RelativeLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                addRule(RelativeLayout.ALIGN_PARENT_TOP)
                addRule(RelativeLayout.ALIGN_PARENT_END)
                topMargin = toPx(options.number("adChoicesTopInset", 63f)).toInt()
                marginEnd = toPx(options.number("adChoicesTrailingInset", 16f)).toInt()
            },
        )
        nativeAdView.addView(
            rootLayout,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        nativeAdView.adChoicesView = adChoicesView

        // 에셋 뷰·AdChoices 지정 후 마지막에 연결 (SDK 요구 순서)
        nativeAdView.setNativeAd(nativeAd)
        return nativeAdView
    }

    /// 세로 목록 한 줄: 가로 꽉 참, 아래 간격(dp)
    private fun verticalItemParams(bottomGapDp: Float): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = toPx(bottomGapDp).toInt()
        }

    /// 글자 스타일 옵션(크기·폰트 파일·색·줄 수) > TextView 적용
    private fun applyTextStyle(textView: TextView, options: FeedNativeAdOptions, fallback: FeedNativeAdTextFallback) {
        // Dart에서 앱 글자 배율(1.0~1.2) 반영한 값이라 시스템 글자 배율 재적용 방지 (DIP)
        textView.setTextSize(TypedValue.COMPLEX_UNIT_DIP, options.number("fontSize", fallback.fontSize))
        textView.typeface = pretendardTypeface(options.string("fontAssetPath", fallback.fontAssetPath))
        textView.setTextColor(options.color("colorArgb", fallback.colorArgb))
        textView.maxLines = options.integer("maxLines", fallback.maxLines)
        textView.ellipsize = TextUtils.TruncateAt.END
        // Flutter 글자 상자(height 1.0)에 가깝게 위아래 폰트 여백 제거
        textView.includeFontPadding = false
    }

    /// Flutter 에셋 Pretendard > Typeface (첫 사용 시 로드, 실패 시 시스템 굵은 글꼴)
    private fun pretendardTypeface(assetPath: String): Typeface {
        typefaceByAssetPath[assetPath]?.let { return it }
        return try {
            val lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
            Typeface.createFromAsset(context.assets, lookupKey).also { typefaceByAssetPath[assetPath] = it }
        } catch (exception: RuntimeException) {
            Typeface.DEFAULT_BOLD
        }
    }

    private fun toPx(dp: Float): Float = dp * density
}

/// 글자 역할별 기본값 (Dart 옵션 누락 시, 393x852·글자 배율 1.0 기준)
/// h3 18 w600 흰색 / p3 12 w500 흰색 / 10 w600 primaryBlack / p1 16 w600 흰색
private enum class FeedNativeAdTextFallback(
    val fontSize: Float,
    val fontAssetPath: String,
    val colorArgb: Int,
    val maxLines: Int,
) {
    HEADLINE(18f, "assets/fonts/pretendard/Pretendard-SemiBold.otf", 0xFFFFFFFF.toInt(), 2),
    BODY(12f, "assets/fonts/pretendard/Pretendard-Medium.otf", 0xFFFFFFFF.toInt(), 2),
    AD_BADGE(10f, "assets/fonts/pretendard/Pretendard-SemiBold.otf", 0xFF1D1E27.toInt(), 1),
    CALL_TO_ACTION(16f, "assets/fonts/pretendard/Pretendard-SemiBold.otf", 0xFFFFFFFF.toInt(), 1),
}

/// customOptions 읽기: 숫자·정수·문자열·ARGB 색·중첩 옵션
private class FeedNativeAdOptions(private val values: Map<*, *>) {
    fun number(key: String, fallback: Float): Float = (values[key] as? Number)?.toFloat() ?: fallback

    fun integer(key: String, fallback: Int): Int = (values[key] as? Number)?.toInt() ?: fallback

    fun string(key: String, fallback: String): String = values[key] as? String ?: fallback

    // ARGB 정수(Color.toARGB32): 0x7FFFFFFF 초과 값은 Long으로 들어와 하위 32비트만 사용
    fun color(key: String, fallback: Int): Int = (values[key] as? Number)?.toLong()?.toInt() ?: fallback

    fun nested(key: String): FeedNativeAdOptions = FeedNativeAdOptions(values[key] as? Map<*, *> ?: emptyMap<Any, Any>())
}

/// 모서리별 반경이 다른 클리핑 레이아웃 (위·아래 반경, 크기 바뀔 때마다 경로 재계산)
private class CornerClippingFrameLayout(
    context: Context,
    private val topRadiusPx: Float,
    private val bottomRadiusPx: Float,
) : FrameLayout(context) {
    private val clipPath = Path()

    override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
        super.onSizeChanged(width, height, oldWidth, oldHeight)
        clipPath.reset()
        // 순서: 왼쪽 위, 오른쪽 위, 오른쪽 아래, 왼쪽 아래 (x, y 쌍)
        val radii = floatArrayOf(
            topRadiusPx, topRadiusPx, topRadiusPx, topRadiusPx,
            bottomRadiusPx, bottomRadiusPx, bottomRadiusPx, bottomRadiusPx,
        )
        clipPath.addRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radii, Path.Direction.CW)
    }

    override fun dispatchDraw(canvas: Canvas) {
        val saveCount = canvas.save()
        canvas.clipPath(clipPath)
        super.dispatchDraw(canvas)
        canvas.restoreToCount(saveCount)
    }
}
