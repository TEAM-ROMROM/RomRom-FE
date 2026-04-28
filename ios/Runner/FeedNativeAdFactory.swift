import Foundation
import GoogleMobileAds
import google_mobile_ads

/// 홈 피드용 네이티브 광고 팩토리
class FeedNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        // 배경 클릭 방지 (빈 공간 클릭 금지 정책)
        nativeAdView.isUserInteractionEnabled = false

        // ── 광고 배지 ("광고" 텍스트, 최소 15×15px) ──────────────────────
        let adBadge = UILabel()
        adBadge.text = "광고"
        adBadge.font = UIFont.systemFont(ofSize: 10)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 2
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        // ── 아이콘 (앱 아이콘 / 광고 로고) ───────────────────────────────
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 4
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = nativeAd.icon?.image
        nativeAdView.iconView = iconImageView

        // ── 메인 미디어 (이미지 또는 영상) ───────────────────────────────
        let mediaView = MediaView()
        mediaView.mediaContent = nativeAd.mediaContent
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.isUserInteractionEnabled = false // 배경 클릭 방지
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.mediaView = mediaView

        // ── 헤드라인 ─────────────────────────────────────────────────────
        let headlineLabel = UILabel()
        headlineLabel.textColor = .white
        headlineLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headlineLabel.numberOfLines = 2
        headlineLabel.text = nativeAd.headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.headlineView = headlineLabel

        // ── 본문 ─────────────────────────────────────────────────────────
        let bodyLabel = UILabel()
        bodyLabel.textColor = UIColor.lightGray
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.numberOfLines = 4 // 90자 잘림 방지 여유
        bodyLabel.text = nativeAd.body
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.bodyView = bodyLabel

        // ── CTA 버튼 ─────────────────────────────────────────────────────
        let ctaButton = UIButton(type: .custom)
        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        ctaButton.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // primaryYellow
        ctaButton.setTitleColor(.black, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ctaButton.layer.cornerRadius = 8
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.callToActionView = ctaButton
        // CTA만 클릭 허용, 다른 요소는 NativeAdView가 처리
        ctaButton.isUserInteractionEnabled = false

        // ── 상단 행: 아이콘 + 헤드라인 + 광고 배지 ──────────────────────
        let topRow = UIStackView(arrangedSubviews: [iconImageView, headlineLabel, adBadge])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // ── 전체 레이아웃 ─────────────────────────────────────────────────
        let mainStack = UIStackView(arrangedSubviews: [topRow, mediaView, bodyLabel, ctaButton])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            // 아이콘 크기 (최소 15px 이상, 가독성을 위해 40pt)
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            // 광고 배지 최소 크기 (정책: 15×15px 이상)
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            adBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),

            // 미디어 뷰 높이 (동영상 최소 120pt 이상 충족)
            mediaView.heightAnchor.constraint(equalToConstant: 240),

            // CTA 버튼 높이
            ctaButton.heightAnchor.constraint(equalToConstant: 48),

            // 수직 중앙 정렬
            mainStack.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
            mainStack.topAnchor.constraint(greaterThanOrEqualTo: nativeAdView.topAnchor, constant: 48),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -48),
            mainStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -24),
        ])

        nativeAdView.nativeAd = nativeAd
        // 클릭은 NativeAdView가 담당하므로 여기서 다시 활성화
        nativeAdView.isUserInteractionEnabled = true

        return nativeAdView
    }
}
