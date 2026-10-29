# 앱 리뷰 팝업 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 2단계 프리-스크린 팝업으로 긍정 유저만 필터링해 iOS/Android 스토어 리뷰를 유도하는 시스템 구현

**Architecture:** `AppReviewService`가 SharedPreferences 상태 관리 + 트리거 판단 담당. `AppReviewPopup`이 CommonModal 2단계 시퀀스 제어. 트리거는 거래 완료(`TradeReviewScreen`) 우선, 앱 종료(`MainScreen PopScope`) 폴백.

**Tech Stack:** Flutter, `in_app_review ^2.0.9`, `shared_preferences ^2.5.2` (기존), `url_launcher ^6.3.2` (기존)

---

## 파일 구조

| 파일 | 작업 | 역할 |
|------|------|------|
| `lib/services/app_review_service.dart` | 신규 생성 | SharedPreferences CRUD, 트리거 판단, in_app_review 호출 |
| `lib/widgets/common/app_review_popup.dart` | 신규 생성 | 2단계 CommonModal 시퀀스 제어 |
| `pubspec.yaml` | 수정 | `in_app_review` 패키지 추가 |
| `lib/screens/trade_review_screen.dart` | 수정 | 거래 완료 후 팝업 트리거 |
| `lib/screens/main_screen.dart` | 수정 | 앱 실행 횟수 기록 + PopScope 종료 트리거 |

---

## Task 1: `in_app_review` 패키지 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml에 패키지 추가**

`dependencies:` 블록에 추가:
```yaml
  in_app_review: ^2.0.9
```

- [ ] **Step 2: pub get 실행**

```bash
source ~/.zshrc && flutter pub get
```

Expected: `Got dependencies!` 출력, 에러 없음

- [ ] **Step 3: 빌드 확인**

```bash
source ~/.zshrc && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

Expected: `No issues found!` 또는 기존 warning만 있고 새 에러 없음

---

## Task 2: `AppReviewService` 구현

**Files:**
- Create: `lib/services/app_review_service.dart`

- [ ] **Step 1: 서비스 파일 생성**

```dart
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
  static const String _kAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.alom.romrom';

  /// 앱 실행 시 호출 — 실행 횟수 +1, 첫 실행일 기록
  Future<void> onAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    // 첫 실행일 기록 (한 번만)
    if (!prefs.containsKey(_kFirstLaunchDate)) {
      await prefs.setInt(
        _kFirstLaunchDate,
        DateTime.now().millisecondsSinceEpoch,
      );
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
      if (DateTime.now().difference(lastShown) < _kCooldown) {
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

  /// [별로예요] / [나중에] / 닫기 — 14일 쿨타임만 기록
  Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastShown, DateTime.now().millisecondsSinceEpoch);
    debugPrint('[AppReview] 닫기 기록 (14일 쿨타임)');
  }
}
```

- [ ] **Step 2: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/services/app_review_service.dart
```

Expected: 에러 없음

---

## Task 3: `AppReviewPopup` 위젯 구현

**Files:**
- Create: `lib/widgets/common/app_review_popup.dart`

- [ ] **Step 1: 팝업 위젯 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

/// 앱 리뷰 유도 2단계 팝업 시퀀스
/// Step 1: "잘 이용하고 계신가요?" 감성 질문
/// Step 2: [좋아요] 선택 시 → "스토어 리뷰 남겨주실래요?"
class AppReviewPopup {
  /// 팝업 시퀀스 실행
  /// context가 mounted 상태인지 호출 전 반드시 확인할 것
  static Future<void> show(
    BuildContext context,
    AppReviewService service,
  ) async {
    // 노출 기록 (Step 1이 뜨는 시점)
    await service.markShown();

    if (!context.mounted) return;

    // Step 1: 감성 질문 팝업
    final isPositive = await _showStep1(context);

    if (!isPositive) {
      // [별로예요] → 14일 쿨타임 (markShown에서 이미 last_shown 기록됨)
      return;
    }

    if (!context.mounted) return;

    // Step 2: 리뷰 유도 팝업
    final wantsReview = await _showStep2(context);

    if (wantsReview) {
      await service.requestReviewAndDisable();
    }
    // [나중에] 선택 시: markShown에서 already 기록됨, 추가 처리 없음
  }

  /// Step 1: "RomRom을 잘 이용하고 계신가요?"
  /// 반환값: true = [좋아요!], false = [별로예요] or 닫기
  static Future<bool> _showStep1(BuildContext context) async {
    bool isPositive = false;
    await CommonModal.confirm(
      context: context,
      message: 'RomRom을 잘 이용하고 계신가요?\n소중한 의견이 앱 개선에 도움이 됩니다 😊',
      cancelText: '별로예요',
      confirmText: '좋아요!',
      onCancel: () {
        isPositive = false;
        Navigator.of(context).pop();
      },
      onConfirm: () {
        isPositive = true;
        Navigator.of(context).pop();
      },
    );
    return isPositive;
  }

  /// Step 2: "스토어 리뷰를 남겨주실래요?"
  /// 반환값: true = [리뷰 남기기], false = [나중에] or 닫기
  static Future<bool> _showStep2(BuildContext context) async {
    bool wantsReview = false;
    await CommonModal.confirm(
      context: context,
      message: '별점 한 줄이 큰 힘이 됩니다! ⭐\n스토어에 리뷰를 남겨주실래요?',
      cancelText: '나중에',
      confirmText: '리뷰 남기기',
      onCancel: () {
        wantsReview = false;
        Navigator.of(context).pop();
      },
      onConfirm: () {
        wantsReview = true;
        Navigator.of(context).pop();
      },
    );
    return wantsReview;
  }
}
```

- [ ] **Step 2: CommonModal.confirm 팩토리 시그니처 확인**

```bash
source ~/.zshrc && grep -A 20 "static.*confirm" /Users/suhsaechan/Desktop/Programming/project/RomRom-FE/lib/widgets/common/common_modal.dart | head -25
```

`confirm` 팩토리가 없으면 아래 Step 3으로 이동. 있으면 Step 4로 건너뜀.

- [ ] **Step 3: (confirm 없는 경우만) CommonModal 팩토리 확인 후 맞는 메서드로 교체**

`common_modal.dart`의 실제 팩토리 메서드명 확인:
```bash
source ~/.zshrc && grep "static.*Future\|static.*show\|factory" /Users/suhsaechan/Desktop/Programming/project/RomRom-FE/lib/widgets/common/common_modal.dart
```

출력된 팩토리명으로 `_showStep1`, `_showStep2`의 `CommonModal.confirm(...)` 호출부를 실제 메서드명으로 교체.

- [ ] **Step 4: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/widgets/common/app_review_popup.dart
```

Expected: 에러 없음

---

## Task 4: `MainScreen` — 앱 실행 횟수 기록

**Files:**
- Modify: `lib/screens/main_screen.dart`

- [ ] **Step 1: import 추가**

`main_screen.dart` 상단 import 목록에 추가:
```dart
import 'package:romrom_fe/services/app_review_service.dart';
```

- [ ] **Step 2: initState에서 onAppLaunch 호출**

`_MainScreenState.initState()` 내 `WidgetsBinding.instance.addPostFrameCallback` 블록에 추가:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  if (!mounted) return;
  // 기존 코드 유지
  await _syncNotificationPermissionToBackend();
  // 앱 실행 횟수 기록
  await AppReviewService().onAppLaunch();
});
```

- [ ] **Step 3: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/main_screen.dart
```

Expected: 에러 없음

---

## Task 5: `MainScreen` — 앱 종료 시도 시 팝업 트리거

**Files:**
- Modify: `lib/screens/main_screen.dart`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/widgets/common/app_review_popup.dart';
```

- [ ] **Step 2: _MainScreenState에 종료 팝업 핸들러 추가**

`_MainScreenState` 클래스에 메서드 추가:

```dart
/// 앱 종료 시도 시 리뷰 팝업 조건 체크
Future<bool> _onWillPop() async {
  final service = AppReviewService();
  if (await service.shouldShow(tradeTriggered: false)) {
    if (mounted) {
      await AppReviewPopup.show(context, service);
    }
  }
  return true; // 팝업 여부와 관계없이 종료 허용
}
```

- [ ] **Step 3: build 메서드에 PopScope 래핑 확인 및 추가**

`MainScreen.build()`에서 최상위 위젯을 `PopScope`로 래핑:

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final shouldPop = await _onWillPop();
      if (shouldPop && mounted) {
        Navigator.of(context).pop(result);
      }
    },
    child: Scaffold(
      // 기존 Scaffold 내용 그대로 유지
      ...
    ),
  );
}
```

> 주의: 기존에 `PopScope`나 `WillPopScope`가 이미 있으면 새로 추가하지 말고 기존 콜백에 `_onWillPop()` 호출을 합쳐야 함. 먼저 확인:
> ```bash
> grep -n "PopScope\|WillPopScope" lib/screens/main_screen.dart
> ```

- [ ] **Step 4: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/main_screen.dart
```

Expected: 에러 없음

---

## Task 6: `TradeReviewScreen` — 거래 완료 후 팝업 트리거

**Files:**
- Modify: `lib/screens/trade_review_screen.dart`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/app_review_popup.dart';
```

- [ ] **Step 2: onTradeComplete 호출 + 팝업 트리거**

`_submit()` 메서드에서 `context.navigateTo(...)` 직전에 추가:

```dart
// 거래 완료 횟수 기록 및 리뷰 팝업 조건 체크
final reviewService = AppReviewService();
await reviewService.onTradeComplete();

if (!mounted) return;

// MainScreen으로 이동 전에 팝업 표시 (navigateTo 이후엔 context 무효)
if (await reviewService.shouldShow(tradeTriggered: true)) {
  if (mounted) {
    await AppReviewPopup.show(context, reviewService);
  }
}

if (!mounted) return;
context.navigateTo(
  screen: const MainScreen(),
  type: NavigationTypes.pushAndRemoveUntil,
  predicate: (route) => false,
);
```

- [ ] **Step 3: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/trade_review_screen.dart
```

Expected: 에러 없음

---

## Task 7: 전체 포맷 + 최종 분석

**Files:**
- 모든 수정 파일

- [ ] **Step 1: 전체 포맷 적용**

```bash
source ~/.zshrc && dart format --line-length=120 .
```

- [ ] **Step 2: 전체 린트 분석**

```bash
source ~/.zshrc && flutter analyze
```

Expected: `No issues found!` 또는 기존 warning만 있고 신규 에러 없음. 에러 발생 시 수정 후 재실행.

---

## 검증 체크리스트 (수동)

시뮬레이터 또는 실기기에서 확인:

- [ ] 앱 실행 2회 + 홈에서 뒤로가기 → Step 1 팝업 노출
- [ ] [좋아요!] → Step 2 팝업 노출
- [ ] [리뷰 남기기] → 네이티브 다이얼로그 또는 스토어 링크 열림
- [ ] 팝업 노출 후 14일 내 재실행 → 팝업 안 뜸
- [ ] 거래 완료 + 앱 사용 3일 → 거래 완료 직후 팝업 노출
- [ ] [별로예요] → 팝업 닫힘, 14일 후 재노출
- [ ] 3회 노출 후 → 영구 비활성
