import Flutter
import Foundation
import GoogleMobileAds
import UIKit
import google_mobile_ads

/// 목록(채팅·좋아요·내 물품) 네이티브 광고 팩토리: [아이콘] [광고 배지 + 헤드라인 / 본문] [CTA] 한 줄
/// 치수·글자·색은 Dart ListNativeAdStyle customOptions에서 받음, AdChoices는 SDK가 오른쪽 위에 자동 배치
class ListNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let options = FeedNativeAdOptions(values: customOptions ?? [:])
        let nativeAdView = NativeAdView()
        // 목록 행과 다른 바탕 (AppColors.listNativeAdBackground, 콘텐츠 위장 금지)
        nativeAdView.backgroundColor = options.color("backgroundColorArgb", fallback: 0xFF282933)
        nativeAdView.layer.cornerRadius = options.number("cornerRadius", fallback: 12)
        nativeAdView.clipsToBounds = true

        // ── 아이콘: 없으면 스택에서 접힘 ──────────────────────────────
        let iconSize = options.number("iconSize", fallback: 44)
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = options.number("iconCornerRadius", fallback: 8)
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
        nativeAdView.iconView = iconImageView

        // ── 광고 배지: 정책상 필수 표시 ─────────────────────────────────
        let badgeOptions = options.nested("adBadge")
        let adBadge = PaddedLabel()
        applyTextStyle(to: adBadge, options: badgeOptions.nested("text"), fallbackFontSize: 10, fallbackColorArgb: 0xFF1D1E27)
        adBadge.text = badgeOptions.string("label", fallback: "광고")
        adBadge.textAlignment = .center
        adBadge.backgroundColor = badgeOptions.color("backgroundColorArgb", fallback: 0xFFFFF1C4)
        let badgeHorizontalPadding = badgeOptions.number("horizontalPadding", fallback: 6)
        let badgeVerticalPadding = badgeOptions.number("verticalPadding", fallback: 3)
        adBadge.contentInsets = UIEdgeInsets(
            top: badgeVerticalPadding, left: badgeHorizontalPadding,
            bottom: badgeVerticalPadding, right: badgeHorizontalPadding
        )
        adBadge.maximumCornerRadius = badgeOptions.number("cornerRadius", fallback: 4)
        adBadge.clipsToBounds = true
        adBadge.setContentHuggingPriority(.required, for: .horizontal)
        adBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        // ── 헤드라인 (필수 애셋, 1줄 말줄임) ───────────────────────────
        let headlineLabel = UILabel()
        applyTextStyle(to: headlineLabel, options: options.nested("headlineText"), fallbackFontSize: 14, fallbackColorArgb: 0xFFFFFFFF)
        headlineLabel.text = nativeAd.headline
        headlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nativeAdView.headlineView = headlineLabel

        // ── 본문 (없으면 접힘) ─────────────────────────────────────────
        let bodyLabel = UILabel()
        applyTextStyle(to: bodyLabel, options: options.nested("bodyText"), fallbackFontSize: 12, fallbackColorArgb: 0x99FFFFFF)
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = (nativeAd.body ?? "").isEmpty
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nativeAdView.bodyView = bodyLabel

        // ── CTA: 알약 버튼 모양 (없으면 접힘) ──────────────────────────
        let callToActionOptions = options.nested("callToAction")
        let callToActionLabel = PaddedLabel()
        applyTextStyle(
            to: callToActionLabel, options: callToActionOptions.nested("text"),
            fallbackFontSize: 12, fallbackColorArgb: 0xFF1D1E27
        )
        callToActionLabel.text = nativeAd.callToAction
        callToActionLabel.isHidden = (nativeAd.callToAction ?? "").isEmpty
        callToActionLabel.textAlignment = .center
        callToActionLabel.backgroundColor = callToActionOptions.color("backgroundColorArgb", fallback: 0xFFFFC300)
        let callToActionHorizontalPadding = callToActionOptions.number("horizontalPadding", fallback: 12)
        callToActionLabel.contentInsets = UIEdgeInsets(
            top: 0, left: callToActionHorizontalPadding, bottom: 0, right: callToActionHorizontalPadding
        )
        // 높이 절반 반경 = 알약
        callToActionLabel.maximumCornerRadius = .greatestFiniteMagnitude
        callToActionLabel.clipsToBounds = true
        callToActionLabel.setContentHuggingPriority(.required, for: .horizontal)
        callToActionLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nativeAdView.callToActionView = callToActionLabel

        // ── 배치: 아이콘 > 글자 2줄 > CTA (가운데 정렬, 숨긴 애셋은 간격째 빠짐) ──
        let firstLineStack = UIStackView(arrangedSubviews: [adBadge, headlineLabel])
        firstLineStack.axis = .horizontal
        firstLineStack.alignment = .center
        firstLineStack.spacing = options.number("badgeToHeadlineGap", fallback: 6)

        let textStack = UIStackView(arrangedSubviews: [firstLineStack, bodyLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = options.number("headlineToBodyGap", fallback: 4)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [iconImageView, textStack, callToActionLabel])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.setCustomSpacing(options.number("iconToTextGap", fallback: 12), after: iconImageView)
        rowStack.setCustomSpacing(options.number("textToCallToActionGap", fallback: 12), after: textStack)
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(rowStack)

        let horizontalPadding = options.number("innerHorizontalPadding", fallback: 12)
        // 아이콘 없는 광고는 스택에서 접히므로 크기 제약이 양보하도록 999
        let iconWidth = iconImageView.widthAnchor.constraint(equalToConstant: iconSize)
        let iconHeight = iconImageView.heightAnchor.constraint(equalToConstant: iconSize)
        iconWidth.priority = UILayoutPriority(999)
        iconHeight.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: horizontalPadding),
            rowStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -horizontalPadding),
            rowStack.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
            iconWidth,
            iconHeight,
            callToActionLabel.heightAnchor.constraint(equalToConstant: callToActionOptions.number("height", fallback: 32)),
            callToActionLabel.widthAnchor.constraint(
                lessThanOrEqualToConstant: callToActionOptions.number("maximumWidth", fallback: 96)
            ),
        ])

        // 애셋 뷰 지정 후 마지막에 연결 (SDK 요구 순서)
        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }

    /// 글자 스타일 옵션(크기·폰트 파일·색) > 1줄 말줄임 UILabel
    private func applyTextStyle(
        to label: UILabel, options: FeedNativeAdOptions, fallbackFontSize: CGFloat, fallbackColorArgb: UInt32
    ) {
        let fontSize = options.number("fontSize", fallback: fallbackFontSize)
        let fontAssetPath = options.string("fontAssetPath", fallback: "assets/fonts/pretendard/Pretendard-SemiBold.otf")
        label.font = PretendardFontRegistry.shared.font(assetPath: fontAssetPath, size: fontSize)
        label.textColor = options.color("colorArgb", fallback: fallbackColorArgb)
        label.numberOfLines = options.integer("maxLines", fallback: 1)
        label.lineBreakMode = .byTruncatingTail
    }
}
