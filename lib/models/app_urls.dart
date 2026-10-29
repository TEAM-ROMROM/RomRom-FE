import 'package:romrom_fe/debug/runtime_url_manager.dart';

/// 프로젝트 내 URL 관리
class AppUrls {
  static String get baseUrl => RuntimeUrlManager().baseUrl;
  static const String itemShareBaseUrl = "https://romrom-c4008.web.app";
  static const String imageBaseUrl = "https://suh-project.synology.me"; // 이미지 서버 주소
  static const String naverReverseGeoCodeApiUrl =
      "https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc"; // 네이버 주소 API
  static const String naverStaticMapApiUrl = 'https://maps.apigw.ntruss.com/map-static/v2/raster';

  // 채팅 웹소켓 경로 (서버 STOMP 엔드포인트)
  static const String chatWebSocketPath = '/chat';

  /// 현재 baseUrl 기준 채팅 웹소켓 주소
  static String get chatWebSocketUrl => toWebSocketUrl(baseUrl);

  /// http(s) 기준 주소 > ws(s) 채팅 주소 (https > wss, http > ws)
  static String toWebSocketUrl(String httpBaseUrl) {
    final trimmedBaseUrl = httpBaseUrl.endsWith('/') ? httpBaseUrl.substring(0, httpBaseUrl.length - 1) : httpBaseUrl;
    final webSocketBaseUrl = trimmedBaseUrl.startsWith('https://')
        ? trimmedBaseUrl.replaceFirst('https://', 'wss://')
        : trimmedBaseUrl.replaceFirst('http://', 'ws://');
    return '$webSocketBaseUrl$chatWebSocketPath';
  }

  /// 서버 이미지 경로 > 절대 주소 (http/https는 그대로, 빈 값은 빈 문자열)
  static String toAbsoluteImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) return imagePath;
    final pathWithoutLeadingSlash = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$imageBaseUrl/$pathWithoutLeadingSlash';
  }

  // 스토어 URL
  static const String androidStoreUrl = "https://play.google.com/store/apps/details?id=com.alom.romrom&hl=ko";
  static const String iosStoreUrl =
      "https://apps.apple.com/kr/app/%EB%A1%AC%EB%A1%AC-romrom-%ED%98%81%EC%8B%A0%EC%A0%81%EC%9D%B8-%EB%AC%BC%EB%AC%BC%EA%B5%90%ED%99%98/id$iosAppStoreId";

  // iOS App Store 앱 id (openStoreListing 필수 인자)
  static const String iosAppStoreId = '6748823976';

  // 리뷰 유도용 스토어 URL (지역·언어 파라미터 없는 짧은 주소)
  static const String androidStoreReviewUrl = 'https://play.google.com/store/apps/details?id=com.alom.romrom';
  static const String iosStoreReviewUrl = 'https://apps.apple.com/app/id$iosAppStoreId';

  // 운영 API 서버 주소 (RuntimeUrlManager 기본값·릴리스 빌드 고정값)
  static const String productionApiBaseUrl = 'https://api.romrom.suhsaechan.kr';
}
