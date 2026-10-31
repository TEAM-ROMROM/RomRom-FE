import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/enums/rewarded_ad_outcome.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';

/// AdMob 보상형 광고의 로드·표시·보상 콜백을 캡슐화한다.
/// 비즈니스 로직(우선노출)을 전혀 모른다 — 결과는 RewardedAdOutcome 하나.
///
/// 주의: 동시 호출에 안전하지 않다(단일 `_ad` 인스턴스 공유). 동시 호출 dedup은
/// 호출자 책임이다(`PromotionNotifier`가 `_inFlight`로 보장). 단일 탭 흐름만 가정.
class RewardedAdService {
  RewardedAd? _ad;
  bool _isLoading = false;

  /// 광고 미리 로드. 이미 로드됐거나 로딩 중이면 무시.
  Future<void> load() async {
    if (_ad != null || _isLoading) return;
    final unitId = AdMobService.rewardedAdUnitId;
    if (unitId == null) return; // 릴리스 광고 단위 미설정 > 로드 생략 (AdMobService.rewardedAdUnitId)
    _isLoading = true;
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAd] 로드 실패: $error');
          _ad = null;
          _isLoading = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// 광고 표시 > 결과 (적립 / 시청 중 이탈 / 미설정·로드·표시 실패)
  Future<RewardedAdOutcome> showAndAwaitReward() async {
    if (_ad == null) await load();
    final ad = _ad;
    if (ad == null) return RewardedAdOutcome.unavailable; // 미설정·로드 실패

    final completer = Completer<RewardedAdOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      // 보상 콜백(onUserEarnedReward)은 닫히기 전에 도착 → 닫힘 시점에 결과 확정
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) {
          completer.complete(earned ? RewardedAdOutcome.earned : RewardedAdOutcome.notEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAd] 표시 실패: $error');
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(RewardedAdOutcome.unavailable);
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }
}
