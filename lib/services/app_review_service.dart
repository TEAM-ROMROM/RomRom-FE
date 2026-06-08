import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 리뷰 팝업 상태 관리 및 트리거 판단 서비스
/// SharedPreferences 기반 로컬 저장, 백엔드 연동 없음
class AppReviewService with WidgetsBindingObserver {
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

  /// iOS App Store ID (openStoreListing iOS 필수 인자)
  static const String _kIosAppStoreId = '6748823976';

  /// 인앱 리뷰 카드 표출 여부를 라이프사이클로 추정할 때 대기 시간.
  /// 이 시간 내 앱이 inactive/paused로 안 바뀌면 "카드 안 떴다"로 추정 → 스토어 폴백.
  static const Duration _kReviewSheetWait = Duration(milliseconds: 1200);

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

  /// [리뷰 남기기] 진행 중 플래그 — 재진입 차단용.
  /// 싱글톤이라 공유 가변 상태(_sheetShownSignal·옵저버)를 두 호출이 덮어쓰면
  /// 신호 유실·옵저버 조기 해제로 스토어 중복 이동/폴백 누락이 생긴다. (#910)
  bool _reviewInFlight = false;

  /// [리뷰 남기기] 클릭 시 — 영구 비활성 + 네이티브 리뷰 요청
  Future<void> requestReviewAndDisable() async {
    // 빠른 연타 등으로 인한 동시 재진입 차단
    if (_reviewInFlight) {
      debugPrint('[AppReview] 리뷰 요청 진행 중 → 중복 호출 무시');
      return;
    }
    _reviewInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDisabled, true);
      debugPrint('[AppReview] 영구 비활성 처리');

      await _requestReview();
    } finally {
      _reviewInFlight = false;
    }
  }

  // ── 인앱 리뷰 카드 표출 추정용 라이프사이클 감시 상태 ──
  // requestReview()는 카드를 띄웠는지/실패했는지 결과를 반환하지 않는다(OS/플러그인 정책).
  // 카드가 뜨면 시스템 오버레이가 앱 위에 올라와 앱이 inactive/paused로 전환되는 점을
  // 이용해, 호출 직후 일정 시간 내 상태 변화가 없으면 "카드 안 떴다"고 추정한다.
  Completer<void>? _sheetShownSignal;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final signal = _sheetShownSignal;
    if (signal == null || signal.isCompleted) return;
    // 인앱 리뷰 카드(또는 스토어)가 앞에 떴다는 신호로 간주
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      debugPrint('[AppReview] 라이프사이클 $state → 리뷰 카드 표출로 추정');
      signal.complete();
    }
  }

  /// in_app_review 호출 후 라이프사이클로 카드 표출 추정.
  /// 카드 안 떴다고 추정되면 스토어 리뷰 페이지로 폴백.
  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;

    // isAvailable=false(플레이서비스 없음 등)면 추정 없이 바로 스토어
    bool available = false;
    try {
      available = await inAppReview.isAvailable();
    } catch (e) {
      debugPrint('[AppReview] isAvailable 확인 실패: $e');
    }
    if (!available) {
      debugPrint('[AppReview] 인앱 리뷰 불가 → 스토어 폴백');
      await _openStoreLink();
      return;
    }

    // 라이프사이클 감시 시작
    final signal = Completer<void>();
    _sheetShownSignal = signal;
    WidgetsBinding.instance.addObserver(this);

    try {
      try {
        // 결과를 기다려도 카드 표출 여부는 알 수 없으므로 await만 한다(예외만 캐치)
        await inAppReview.requestReview();
        debugPrint('[AppReview] requestReview() 호출 완료(표출 여부 불명)');
      } catch (e) {
        debugPrint('[AppReview] requestReview 실패: $e → 스토어 폴백');
        await _openStoreLink();
        return;
      }

      // 카드가 떴으면 didChangeAppLifecycleState가 signal을 완료시킨다.
      // 대기 시간 내 신호가 없으면 "안 떴다"로 추정 → 스토어 폴백.
      final shown = await Future.any<bool>([
        signal.future.then((_) => true),
        Future<bool>.delayed(_kReviewSheetWait, () => false),
      ]);

      if (!shown) {
        debugPrint('[AppReview] 카드 미표출 추정 → 스토어 폴백');
        await _openStoreLink();
      } else {
        debugPrint('[AppReview] 카드 표출 추정 → 스토어 폴백 안 함');
      }
    } finally {
      WidgetsBinding.instance.removeObserver(this);
      _sheetShownSignal = null;
    }
  }

  /// 스토어 리뷰 페이지로 이동.
  /// 1차: in_app_review의 openStoreListing()(스토어 앱 직행, iOS는 appStoreId 필요)
  /// 2차(예외 시): url_launcher로 스토어 웹 URL 열기
  Future<void> _openStoreLink() async {
    try {
      await InAppReview.instance.openStoreListing(
        // iOS/MacOS에서 필수. Android는 무시됨.
        appStoreId: _kIosAppStoreId,
      );
      debugPrint('[AppReview] openStoreListing 성공');
      return;
    } catch (e) {
      debugPrint('[AppReview] openStoreListing 실패: $e → URL 폴백');
    }

    final url = Uri.parse(Platform.isIOS ? _kIosStoreUrl : _kAndroidStoreUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        debugPrint('[AppReview] 스토어 URL 열기 성공');
      }
    } catch (e) {
      debugPrint('[AppReview] 스토어 URL 열기 실패: $e');
    }
  }
}
