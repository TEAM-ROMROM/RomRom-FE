import CoreText
import Flutter
import Foundation
import GoogleMobileAds
import UIKit
import google_mobile_ads

/// 홈 피드 네이티브 광고 팩토리: 물품 카드(HomeFeedItemWidget)와 같은 레이아웃
/// 치수·글자·색은 Dart HomeFeedNativeAdStyle customOptions에서 받음 (없으면 393x852 기준 기본값)
class FeedNativeAdFactory: NSObject, FLTNativeAdFactory {

    // Pretendard 폰트 파일 경로 > 등록된 PostScript 이름 (팩토리 1개, 메인 스레드 호출)
    private var fontNameByAssetPath: [String: String] = [:]

    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let options = FeedNativeAdOptions(values: customOptions ?? [:])
        let nativeAdView = NativeAdView()
        // 물품 카드 바탕 (AppColors.homeFeedCardBackground)
        nativeAdView.backgroundColor = options.color("cardBackgroundColorArgb", fallback: 0xFF000000)

        // ── 메인 미디어: 물품 사진 자리, 카드 이미지 모서리(위 4, 아래 20) ──────────
        let mediaContainer = CornerClippingView()
        mediaContainer.topCornerRadius = options.number("mediaTopCornerRadius", fallback: 4)
        mediaContainer.bottomCornerRadius = options.number("mediaBottomCornerRadius", fallback: 20)
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false

        let mediaView = MediaView()
        mediaView.mediaContent = nativeAd.mediaContent
        // 물품 사진 BoxFit.cover와 동일 (비율 유지, 넘치는 부분만 잘림)
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.isUserInteractionEnabled = false // 기존 클릭 영역 유지 (미디어 탭 비활성)
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(mediaView)
        nativeAdView.mediaView = mediaView

        // ── 헤드라인: 물품 이름 자리 (HomeFeedItemSummary.titleTextStyle) ──────────
        let headlineLabel = UILabel()
        applyTextStyle(to: headlineLabel, options: options.nested("headlineText"), fallback: .headline)
        headlineLabel.text = nativeAd.headline
        nativeAdView.headlineView = headlineLabel

        // ── 본문: 위치·등록일 줄 자리 (HomeFeedItemSummary.metaTextStyle) ──────────
        let bodyLabel = UILabel()
        applyTextStyle(to: bodyLabel, options: options.nested("bodyText"), fallback: .body)
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = (nativeAd.body ?? "").isEmpty
        nativeAdView.bodyView = bodyLabel

        // ── 광고 배지: 사용감 태그 자리·모양 (ItemDetailConditionTag, 정책상 필수 표시) ──
        let badgeOptions = options.nested("adBadge")
        let adBadge = PaddedLabel()
        applyTextStyle(to: adBadge, options: badgeOptions.nested("text"), fallback: .adBadge)
        adBadge.text = badgeOptions.string("label", fallback: "광고")
        adBadge.textAlignment = .center
        adBadge.backgroundColor = badgeOptions.color("backgroundColorArgb", fallback: 0xFFFFF1C4)
        let badgeHorizontalPadding = badgeOptions.number("horizontalPadding", fallback: 8)
        let badgeVerticalPadding = badgeOptions.number("verticalPadding", fallback: 6)
        adBadge.contentInsets = UIEdgeInsets(
            top: badgeVerticalPadding, left: badgeHorizontalPadding,
            bottom: badgeVerticalPadding, right: badgeHorizontalPadding
        )
        adBadge.maximumCornerRadius = badgeOptions.number("cornerRadius", fallback: 100)
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        // ── CTA: 가격 줄 자리 (HomeFeedItemSummary.priceTextStyle) ────────────────
        let callToActionLabel = UILabel()
        applyTextStyle(to: callToActionLabel, options: options.nested("callToActionText"), fallback: .callToAction)
        callToActionLabel.text = nativeAd.callToAction
        callToActionLabel.isHidden = (nativeAd.callToAction ?? "").isEmpty
        nativeAdView.callToActionView = callToActionLabel

        // ── 아이콘: 작성자 프로필 자리 (원형, HomeFeedCardLayout.profileAvatarSize) ──
        let iconSize = options.number("iconSize", fallback: 50)
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = iconSize / 2
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.iconView = iconImageView

        // ── 정보 패널: 이름 > 위치 > 태그 > 가격 (간격 HomeFeedCardLayout) ─────────
        let summaryStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel, adBadge, callToActionLabel])
        summaryStack.axis = .vertical
        summaryStack.alignment = .leading
        summaryStack.setCustomSpacing(options.number("titleToMetaGap", fallback: 8), after: headlineLabel)
        summaryStack.setCustomSpacing(options.number("metaToTagGap", fallback: 12), after: bodyLabel)
        summaryStack.setCustomSpacing(options.number("tagToPriceGap", fallback: 10), after: adBadge)
        // 남는 가로 폭은 요약이 차지 (Flutter Expanded)
        summaryStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        summaryStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let infoRow = UIStackView(arrangedSubviews: [summaryStack, iconImageView])
        infoRow.axis = .horizontal
        infoRow.alignment = .top
        infoRow.translatesAutoresizingMaskIntoConstraints = false
        // 세로: 미디어 고유 높이(이미지 비율)를 가장 약하게 > 남는 높이는 미디어가 차지 (물품 카드처럼 글자 하단 정렬)
        mediaView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        // ── AdChoices: 광고 슬롯에서 숨긴 신고 버튼 자리 (정책상 필수, nativeAd 지정 전에 설정) ──
        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false

        nativeAdView.addSubview(mediaContainer)
        nativeAdView.addSubview(infoRow)
        nativeAdView.addSubview(adChoicesView)
        nativeAdView.adChoicesView = adChoicesView

        let horizontalPadding = options.number("infoPanelHorizontalPadding", fallback: 24)
        // AdChoices 아이콘 최소 크기 (정책 15x15, SDK가 펼칠 때 양보하도록 낮은 우선순위)
        // 아이콘 없는 광고는 스택에서 접히므로 크기 제약이 양보하도록 999
        let iconWidth = iconImageView.widthAnchor.constraint(equalToConstant: iconSize)
        let iconHeight = iconImageView.heightAnchor.constraint(equalToConstant: iconSize)
        iconWidth.priority = UILayoutPriority(999)
        iconHeight.priority = UILayoutPriority(999)
        // 정보 패널 높이: 내용만큼만 (스택뷰는 고유 크기가 없어 약한 0 높이로 최소화, 글자 압축 저항이 이김)
        let infoRowMinimumHeight = infoRow.heightAnchor.constraint(equalToConstant: 0)
        infoRowMinimumHeight.priority = UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1)
        let adChoicesWidth = adChoicesView.widthAnchor.constraint(equalToConstant: 15)
        let adChoicesHeight = adChoicesView.heightAnchor.constraint(equalToConstant: 15)
        adChoicesWidth.priority = .defaultHigh
        adChoicesHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // 미디어: 카드 위 전체 폭 ~ 정보 패널 위 간격까지 (광고 애셋 위에 글자 겹침 없음)
            mediaContainer.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaContainer.bottomAnchor.constraint(
                equalTo: infoRow.topAnchor, constant: -options.number("mediaToInfoPanelGap", fallback: 24)
            ),
            mediaView.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),

            // 정보 패널: 물품 카드와 같은 좌우 여백·하단 거리 (카드 덱 위)
            infoRow.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: horizontalPadding),
            infoRow.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -horizontalPadding),
            infoRow.bottomAnchor.constraint(
                equalTo: nativeAdView.bottomAnchor, constant: -options.number("infoPanelBottomInset", fallback: 110)
            ),

            iconWidth,
            iconHeight,
            infoRowMinimumHeight,

            // 광고 배지 최소 크기 (사용감 태그 50x23, 정책 최소 15x15 충족)
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: badgeOptions.number("minWidth", fallback: 50)),
            adBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: badgeOptions.number("minHeight", fallback: 23)),

            adChoicesView.topAnchor.constraint(
                equalTo: nativeAdView.topAnchor, constant: options.number("adChoicesTopInset", fallback: 55)
            ),
            adChoicesView.trailingAnchor.constraint(
                equalTo: nativeAdView.trailingAnchor, constant: -options.number("adChoicesTrailingInset", fallback: 16)
            ),
            adChoicesWidth,
            adChoicesHeight,
        ])

        // 에셋 뷰·AdChoices 지정 후 마지막에 연결 (SDK 요구 순서)
        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }

    /// 글자 스타일 옵션(크기·폰트 파일·색·줄 수) > UILabel 적용
    private func applyTextStyle(to label: UILabel, options: FeedNativeAdOptions, fallback: FeedNativeAdTextFallback) {
        let fontSize = options.number("fontSize", fallback: fallback.fontSize)
        let fontAssetPath = options.string("fontAssetPath", fallback: fallback.fontAssetPath)
        label.font = pretendardFont(assetPath: fontAssetPath, size: fontSize)
        label.textColor = options.color("colorArgb", fallback: fallback.colorArgb)
        label.numberOfLines = options.integer("maxLines", fallback: fallback.maxLines)
        label.lineBreakMode = .byTruncatingTail
    }

    /// Flutter 에셋 Pretendard > UIFont (첫 사용 시 프로세스에 등록, 실패 시 시스템 폰트)
    private func pretendardFont(assetPath: String, size: CGFloat) -> UIFont {
        if let fontName = fontNameByAssetPath[assetPath] ?? registerFont(assetPath: assetPath),
           let font = UIFont(name: fontName, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    /// 에셋 경로 > 번들 파일 등록 > PostScript 이름 (이미 등록된 폰트면 등록 실패를 무시하고 이름만 사용)
    private func registerFont(assetPath: String) -> String? {
        let lookupKey = FlutterDartProject.lookupKey(forAsset: assetPath)
        guard let filePath = Bundle.main.path(forResource: lookupKey, ofType: nil) else { return nil }
        let fontUrl = URL(fileURLWithPath: filePath) as CFURL
        CTFontManagerRegisterFontsForURL(fontUrl, .process, nil)
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontUrl) as? [CTFontDescriptor],
              let firstDescriptor = descriptors.first,
              let fontName = CTFontDescriptorCopyAttribute(firstDescriptor, kCTFontNameAttribute) as? String
        else { return nil }
        fontNameByAssetPath[assetPath] = fontName
        return fontName
    }
}

/// 글자 역할별 기본값 (Dart 옵션 누락 시, 393x852·글자 배율 1.0 기준)
private struct FeedNativeAdTextFallback {
    let fontSize: CGFloat
    let fontAssetPath: String
    let colorArgb: UInt32
    let maxLines: Int

    private static let semiBoldAssetPath = "assets/fonts/pretendard/Pretendard-SemiBold.otf"
    private static let mediumAssetPath = "assets/fonts/pretendard/Pretendard-Medium.otf"

    // h3 18 w600 흰색 / p3 12 w500 흰색 / 10 w600 primaryBlack / p1 16 w600 흰색
    static let headline = FeedNativeAdTextFallback(
        fontSize: 18, fontAssetPath: semiBoldAssetPath, colorArgb: 0xFFFFFFFF, maxLines: 2)
    static let body = FeedNativeAdTextFallback(
        fontSize: 12, fontAssetPath: mediumAssetPath, colorArgb: 0xFFFFFFFF, maxLines: 2)
    static let adBadge = FeedNativeAdTextFallback(
        fontSize: 10, fontAssetPath: semiBoldAssetPath, colorArgb: 0xFF1D1E27, maxLines: 1)
    static let callToAction = FeedNativeAdTextFallback(
        fontSize: 16, fontAssetPath: semiBoldAssetPath, colorArgb: 0xFFFFFFFF, maxLines: 1)
}

/// customOptions 읽기: 숫자·정수·문자열·ARGB 색·중첩 옵션
private struct FeedNativeAdOptions {
    let values: [AnyHashable: Any]

    func number(_ key: String, fallback: CGFloat) -> CGFloat {
        guard let value = values[key] as? NSNumber else { return fallback }
        return CGFloat(value.doubleValue)
    }

    func integer(_ key: String, fallback: Int) -> Int {
        (values[key] as? NSNumber)?.intValue ?? fallback
    }

    func string(_ key: String, fallback: String) -> String {
        values[key] as? String ?? fallback
    }

    /// ARGB 정수(Color.toARGB32) > UIColor
    func color(_ key: String, fallback: UInt32) -> UIColor {
        let argb = (values[key] as? NSNumber).map { UInt32(truncatingIfNeeded: $0.int64Value) } ?? fallback
        return UIColor(
            red: CGFloat((argb >> 16) & 0xFF) / 255,
            green: CGFloat((argb >> 8) & 0xFF) / 255,
            blue: CGFloat(argb & 0xFF) / 255,
            alpha: CGFloat((argb >> 24) & 0xFF) / 255
        )
    }

    func nested(_ key: String) -> FeedNativeAdOptions {
        FeedNativeAdOptions(values: values[key] as? [AnyHashable: Any] ?? [:])
    }
}

/// 모서리별 반경이 다른 클리핑 뷰 (위·아래 반경, 크기 바뀔 때마다 마스크 재계산)
private final class CornerClippingView: UIView {
    var topCornerRadius: CGFloat = 0
    var bottomCornerRadius: CGFloat = 0
    private let maskLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.path = makeRoundedPath(in: bounds).cgPath
        layer.mask = maskLayer
    }

    /// 시계 방향: 위 변 > 오른쪽 위 > 오른쪽 아래 > 왼쪽 아래 > 왼쪽 위
    private func makeRoundedPath(in rect: CGRect) -> UIBezierPath {
        let width = rect.width
        let height = rect.height
        let top = min(topCornerRadius, width / 2, height / 2)
        let bottom = min(bottomCornerRadius, width / 2, height / 2)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: top, y: 0))
        path.addLine(to: CGPoint(x: width - top, y: 0))
        path.addArc(withCenter: CGPoint(x: width - top, y: top), radius: top,
                    startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: width, y: height - bottom))
        path.addArc(withCenter: CGPoint(x: width - bottom, y: height - bottom), radius: bottom,
                    startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: bottom, y: height))
        path.addArc(withCenter: CGPoint(x: bottom, y: height - bottom), radius: bottom,
                    startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: top))
        path.addArc(withCenter: CGPoint(x: top, y: top), radius: top,
                    startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        path.close()
        return path
    }
}

/// 안쪽 여백 있는 알약형 라벨 (모서리 반경은 높이 절반 이하로 제한)
private final class PaddedLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero
    var maximumCornerRadius: CGFloat = 0

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let textSize = super.intrinsicContentSize
        return CGSize(
            width: textSize.width + contentInsets.left + contentInsets.right,
            height: textSize.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(maximumCornerRadius, bounds.height / 2)
    }
}
