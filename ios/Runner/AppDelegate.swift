import UIKit
import Flutter
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 홈 피드 네이티브 광고 팩토리 등록
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "feedNativeAd",
      nativeAdFactory: FeedNativeAdFactory()
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
