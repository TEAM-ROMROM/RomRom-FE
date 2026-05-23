import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 리뷰 팝업 상태 관리 및 트리거 판단 서비스
/// SharedPreferences 기반 로컬 저장, 백엔드 연동 없음
class AppReviewService {
  static final AppReviewService _instance = AppReviewService._internal();
  factory AppReviewService() => _instance;
  AppReviewService._internal();

  // SharedPreferences 키
  static const String _kDisabled = 'review_disabled';
  static const String _kLastShown = 'review_last_shown';
  static const String _kShownCount = 'review_shown_count';
  static const String _kLaunchCount = 'app_launch_count';
  static const String _kFirstLaunchDate = 'app_first_launch_date';
  static const String _kTradeCompleteCount = 'trade_complete_count';

  static const Duration _kCooldown = Duration(days: 14);
  static const int _kMaxShownCount = 3;
  static const int _kMinLaunchCount = 2;
  static const int _kMinUsageDays = 3;

  static const String _kIosStoreUrl = 'https://apps.apple.com/app/id6748823976';
  static const String _kAndroidStoreUrl = 'https://play.google.com/store/apps/details?id=com.alom.romrom';

  /// 앱 실행 시 호출 — 실행 횟수 +1, 첫 실행일 기록
  Future<void> onAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    // 첫 실행일 기록 (한 번만)
    if (!prefs.containsKey(_kFirstLaunchDate)) {
      await prefs.setInt(_kFirstLaunchDate, DateTime.now().millisecondsSinceEpoch);
    }

    final count = prefs.getInt(_kLaunchCount) ?? 0;
    await prefs.setInt(_kLaunchCount, count + 1);
    debugPrint('[AppReview] 앱 실행 횟수: ${count + 1}');
  }

  /// 거래 완료 시 호출 — 거래 완료 횟수 +1
  Future<void> onTradeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kTradeCompleteCount) ?? 0;
    await prefs.setInt(_kTradeCompleteCount, count + 1);
    debugPrint('[AppReview] 거래 완료 횟수: ${count + 1}');
  }

  /// 팝업 표시 여부 판단
  /// 거래 완료 트리거: tradeTriggered = true
  /// 종료 트리거: tradeTriggered = false
  Future<bool> shouldShow({bool tradeTriggered = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 영구 비활성
    if (prefs.getBool(_kDisabled) ?? false) {
      debugPrint('[AppReview] 영구 비활성 → 표시 안 함');
      return false;
    }

    // 노출 횟수 초과 → 영구 비활성 처리
    final shownCount = prefs.getInt(_kShownCount) ?? 0;
    if (shownCount >= _kMaxShownCount) {
      await prefs.setBool(_kDisabled, true);
      debugPrint('[AppReview] 노출 3회 초과 → 영구 비활성');
      return false;
    }

    // 쿨타임 체크
    final lastShownMs = prefs.getInt(_kLastShown);
    if (lastShownMs != null) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      if (DateTime.now().difference(lastShown) <= _kCooldown) {
        debugPrint('[AppReview] 쿨타임 미경과 → 표시 안 함');
        return false;
      }
    }

    if (tradeTriggered) {
      // 거래 완료 트리거: 거래 1회 이상 + 앱 사용 3일 이상
      final tradeCount = prefs.getInt(_kTradeCompleteCount) ?? 0;
      final firstLaunchMs = prefs.getInt(_kFirstLaunchDate);
      if (tradeCount < 1 || firstLaunchMs == null) return false;

      final firstLaunch = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
      final usageDays = DateTime.now().difference(firstLaunch).inDays;
      final ok = usageDays >= _kMinUsageDays;
      debugPrint('[AppReview] 거래 트리거: 거래=$tradeCount, 사용일수=$usageDays → ${ok ? '표시' : '미충족'}');
      return ok;
    } else {
      // 종료 트리거: 앱 실행 2회 이상
      final launchCount = prefs.getInt(_kLaunchCount) ?? 0;
      final ok = launchCount >= _kMinLaunchCount;
      debugPrint('[AppReview] 종료 트리거: 실행=$launchCount → ${ok ? '표시' : '미충족'}');
      return ok;
    }
  }

  /// 팝업 노출 기록
  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kShownCount) ?? 0;
    await prefs.setInt(_kShownCount, count + 1);
    await prefs.setInt(_kLastShown, DateTime.now().millisecondsSinceEpoch);
    debugPrint('[AppReview] 노출 기록: ${count + 1}회');
  }

  /// [리뷰 남기기] 클릭 시 — 영구 비활성 + 네이티브 리뷰 요청
  Future<void> requestReviewAndDisable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDisabled, true);
    debugPrint('[AppReview] 영구 비활성 처리');

    await _requestReview();
  }

  /// in_app_review 호출, 실패 시 스토어 링크 폴백
  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        debugPrint('[AppReview] 네이티브 리뷰 다이얼로그 호출 성공');
        return;
      }
    } catch (e) {
      debugPrint('[AppReview] 네이티브 리뷰 실패: $e');
    }
    // 폴백: 스토어 링크 열기
    await _openStoreLink();
  }

  Future<void> _openStoreLink() async {
    final url = Uri.parse(Platform.isIOS ? _kIosStoreUrl : _kAndroidStoreUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        debugPrint('[AppReview] 스토어 링크 열기 성공');
      }
    } catch (e) {
      debugPrint('[AppReview] 스토어 링크 열기 실패: $e');
    }
  }
}
