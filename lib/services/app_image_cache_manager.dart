import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 네트워크 이미지 디스크 캐시: 물품·프로필·채팅 이미지 공통 (CachedImage·채팅 이미지가 사용)
/// 기본 캐시(200개)보다 넉넉히 보관 > 홈 피드를 오래 넘겨도 앞 이미지 재다운로드 방지
class AppImageCacheManager {
  AppImageCacheManager._();

  // 디스크 캐시 키 (기본 캐시 'libCachedImageData'와 분리 > 같은 저장소를 두 인스턴스가 열지 않음)
  static const String cacheKey = 'romromImageCache';
  // 최대 보관 이미지 수 (초과 시 오래 안 쓴 순 삭제)
  static const int maximumCachedImageCount = 1000;
  // 마지막 사용 후 보관 기간
  static const Duration stalePeriod = Duration(days: 14);

  // 앱 전역 단일 인스턴스 (처음 접근 시 생성)
  static final CacheManager instance = CacheManager(
    Config(cacheKey, stalePeriod: stalePeriod, maxNrOfCacheObjects: maximumCachedImageCount),
  );
}
