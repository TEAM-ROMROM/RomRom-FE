import 'package:romrom_fe/services/native_ad_handle.dart';

/// 홈 피드 광고 칸별 보관: 광고 칸 가상 index > 광고, 광고 칸 위젯은 빌려 그리고 반납 (폐기는 여기서만)
/// 폐기 3가지: 많이 지난 칸, 안 보인 채 오래된 광고(AdMob: 로드 후 1시간 안 표시 권장), 화면 종료
class HomeFeedNativeAdPreloader {
  HomeFeedNativeAdPreloader({DateTime Function()? now}) : _now = now ?? DateTime.now;

  // 안 보인 광고 최대 보관 시간
  static const Duration maximumUnshownAdAge = Duration(minutes: 50);
  // 지나온 광고 보관 범위 (페이지 수, 최대 광고 간격 11 + 1 > 직전 광고는 되돌아가도 다시 요청 없음)
  static const int retainedPassedPageCount = 12;
  // 광고 칸 하나당 최대 요청 횟수 (미리 받기 실패 시 다음 준비 때 1회 재요청)
  static const int maximumRequestCountPerAdSlot = 2;

  final DateTime Function() _now;
  final Map<int, NativeAdHandle> _adByVirtualIndex = {};
  final Map<int, int> _requestCountByVirtualIndex = {};
  // 피드 교체 때 남긴 안 보인 광고 (다음 광고 칸에 요청 대신 먼저 배정)
  final List<NativeAdHandle> _spareAds = [];
  // 광고 칸에 한 번이라도 빌려준 광고 (오래돼도 유지, 피드 교체 시 재사용 안 함)
  final Set<NativeAdHandle> _shownAds = {};
  // 지금 광고 칸이 그리는 중인 광고
  final Set<NativeAdHandle> _borrowedAds = {};
  // 보관 목록에서 빠졌지만 그리는 중 > 반납 때 폐기
  final Set<NativeAdHandle> _adsToDisposeOnReturn = {};

  /// 광고 칸 광고 미리 요청: 보관 중이면 생략 > 남은 광고 배정 > 요청 횟수 안이면 새 요청 ([requestAd] null = 광고 ID 없음)
  void preload(int adVirtualIndex, NativeAdHandle? Function() requestAd) {
    _discardExpiredUnshownAd(adVirtualIndex);
    if (_adByVirtualIndex.containsKey(adVirtualIndex)) return;
    final spareAd = _takeSpareAd();
    if (spareAd != null) {
      _store(adVirtualIndex, spareAd);
      return;
    }
    final requestCount = _requestCountByVirtualIndex[adVirtualIndex] ?? 0;
    if (requestCount >= maximumRequestCountPerAdSlot) return;
    final requestedAd = requestAd();
    if (requestedAd == null) return;
    _requestCountByVirtualIndex[adVirtualIndex] = requestCount + 1;
    _store(adVirtualIndex, requestedAd);
  }

  /// 광고 칸이 광고를 빌림 (없으면 요청, 로드 중이어도 전달, null = 광고 없음 > 칸 접기)
  NativeAdHandle? borrowAd(int adVirtualIndex, NativeAdHandle? Function() requestAd) {
    preload(adVirtualIndex, requestAd);
    final ad = _adByVirtualIndex[adVirtualIndex];
    // 같은 광고를 두 위젯이 동시에 그리면 AdWidget 오류
    if (ad == null || _borrowedAds.contains(ad)) return null;
    _borrowedAds.add(ad);
    _shownAds.add(ad);
    return ad;
  }

  /// 광고 칸 위젯 종료 시 반납 (보관 목록에서 빠진 광고면 이때 폐기)
  void returnAd(NativeAdHandle ad) {
    _borrowedAds.remove(ad);
    if (_adsToDisposeOnReturn.remove(ad)) ad.dispose();
  }

  /// 현재 위치보다 [retainedPassedPageCount] 넘게 지난 광고 칸 폐기
  void discardAdsFarBehind(int currentVirtualIndex) {
    bool isFarBehind(int adVirtualIndex) => currentVirtualIndex - adVirtualIndex > retainedPassedPageCount;
    final farBehindIndices = _adByVirtualIndex.keys.where(isFarBehind).toList();
    for (final adVirtualIndex in farBehindIndices) {
      _retire(_adByVirtualIndex.remove(adVirtualIndex)!);
    }
    _requestCountByVirtualIndex.removeWhere((adVirtualIndex, _) => isFarBehind(adVirtualIndex));
  }

  /// 광고 칸 접힘(로드 실패): 해당 칸 폐기 > 뒤 칸 index 1씩 당김 (HomeFeedAdSlotSchedule.removeAdAtVirtualIndex와 같은 규칙)
  void removeAdSlot(int adVirtualIndex) {
    final removedAd = _adByVirtualIndex.remove(adVirtualIndex);
    if (removedAd != null) _retire(removedAd);
    _requestCountByVirtualIndex.remove(adVirtualIndex);
    _shiftIndicesDown(_adByVirtualIndex, removedVirtualIndex: adVirtualIndex);
    _shiftIndicesDown(_requestCountByVirtualIndex, removedVirtualIndex: adVirtualIndex);
  }

  /// 피드 통째 교체: 보인 광고 폐기, 안 보인 광고는 칸 순서대로 남겨 다음 광고 칸에 재사용
  void resetForReplacedFeed() {
    final sortedIndices = _adByVirtualIndex.keys.toList()..sort();
    for (final adVirtualIndex in sortedIndices) {
      final ad = _adByVirtualIndex[adVirtualIndex]!;
      if (_shownAds.contains(ad)) {
        _retire(ad);
      } else {
        _spareAds.add(ad);
      }
    }
    _adByVirtualIndex.clear();
    _requestCountByVirtualIndex.clear();
  }

  /// 화면 종료: 보관·남은·반납 대기 광고 전부 폐기
  void dispose() {
    for (final ad in {..._adByVirtualIndex.values, ..._spareAds, ..._borrowedAds, ..._adsToDisposeOnReturn}) {
      ad.dispose();
    }
    _adByVirtualIndex.clear();
    _requestCountByVirtualIndex.clear();
    _spareAds.clear();
    _shownAds.clear();
    _borrowedAds.clear();
    _adsToDisposeOnReturn.clear();
  }

  /// 보관 등록 + 로드 실패 시 보관 해제 (다음 preload에서 재요청 가능)
  void _store(int adVirtualIndex, NativeAdHandle ad) {
    _adByVirtualIndex[adVirtualIndex] = ad;
    ad.isLoadedFuture.then((isLoaded) {
      if (isLoaded) return;
      _adByVirtualIndex.removeWhere((_, storedAd) => identical(storedAd, ad));
      _spareAds.remove(ad);
    });
  }

  /// 보관 해제된 광고 폐기 (그리는 중이면 반납 때로 미룸)
  void _retire(NativeAdHandle ad) {
    _shownAds.remove(ad);
    if (_borrowedAds.contains(ad)) {
      _adsToDisposeOnReturn.add(ad);
      return;
    }
    ad.dispose();
  }

  /// 남은 광고 1개 꺼냄 (오래된 광고는 폐기하고 다음 것)
  NativeAdHandle? _takeSpareAd() {
    while (_spareAds.isNotEmpty) {
      final spareAd = _spareAds.removeAt(0);
      if (!_isExpired(spareAd)) return spareAd;
      spareAd.dispose();
    }
    return null;
  }

  void _discardExpiredUnshownAd(int adVirtualIndex) {
    final ad = _adByVirtualIndex[adVirtualIndex];
    if (ad == null || _shownAds.contains(ad) || !_isExpired(ad)) return;
    _adByVirtualIndex.remove(adVirtualIndex);
    ad.dispose();
  }

  bool _isExpired(NativeAdHandle ad) => _now().difference(ad.requestedAt) > maximumUnshownAdAge;

  /// 지워진 칸 뒤 index 1씩 당김
  static void _shiftIndicesDown<T>(Map<int, T> valueByVirtualIndex, {required int removedVirtualIndex}) {
    final shifted = {
      for (final entry in valueByVirtualIndex.entries)
        (entry.key > removedVirtualIndex ? entry.key - 1 : entry.key): entry.value,
    };
    valueByVirtualIndex
      ..clear()
      ..addAll(shifted);
  }
}
