import 'package:romrom_fe/debug/runtime_url_manager.dart';

/// 프로젝트 내 URL 관리
class AppUrls {
  static String get baseUrl => RuntimeUrlManager().baseUrl;
  static const String itemShareBaseUrl = "https://romrom-c4008.web.app";
  static const String imageBaseUrl = "https://suh-project.synology.me"; // 이미지 서버 주소
  static const String naverReverseGeoCodeApiUrl =
      "https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc"; // 네이버 주소 API
  static const String naverStaticMapApiUrl = 'https://maps.apigw.ntruss.com/map-static/v2/raster';

  // 스토어 URL
  static const String androidStoreUrl = "https://play.google.com/store/apps/details?id=com.alom.romrom&hl=ko";
  static const String iosStoreUrl =
      "https://apps.apple.com/kr/app/%EB%A1%AC%EB%A1%AC-romrom-%ED%98%81%EC%8B%A0%EC%A0%81%EC%9D%B8-%EB%AC%BC%EB%AC%BC%EA%B5%90%ED%99%98/id6748823976";
}
