import UIKit
import Flutter
import google_mobile_ads

/// 앱 진입점: UIScene 생명주기(FlutterSceneDelegate, Info.plist) + 엔진 생성 시점 플러그인 등록 (#947)
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 장면이 만든 Flutter 엔진에 플러그인·네이티브 광고 팩토리 등록
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 홈 피드 네이티브 광고 팩토리 등록
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "feedNativeAd",
      nativeAdFactory: FeedNativeAdFactory()
    )
  }
}
