# 앱 리뷰 팝업 구현 스펙

**이슈:** [#811](https://github.com/TEAM-ROMROM/RomRom-FE/issues/811)  
**작성일:** 2026-05-24

---

## 개요

스토어 별점/리뷰 유도를 위한 2단계 팝업 시스템 구현.  
긍정적 사용자만 필터링해 스토어 리뷰로 유도하고, 부정적 사용자는 쿨타임 처리.

---

## 플로우

```
[트리거 조건 충족]
        ↓
  [Step 1 팝업]
  "RomRom을 잘 이용하고 계신가요?"
  [좋아요! 😊]         [별로예요 😞]
       ↓                     ↓
  [Step 2 팝업]          14일 쿨타임
  "스토어 리뷰를 남겨주실래요?"
  [리뷰 남기기 ✍️]      [나중에]
       ↓                     ↓
  in_app_review           14일 쿨타임
  네이티브 다이얼로그
  (실패 시 스토어 링크 폴백)
       ↓
   영구 비활성
```

---

## 트리거 조건

둘 중 하나 충족 시 팝업 표시 (우선순위 순):

### 1순위 — 거래 완료 후
- 거래 완료(`TradeReviewScreen` 완료 콜백) 직후
- 앱 사용 누적 3일 이상 (`app_first_launch_date` 기준)

### 2순위 (폴백) — 앱 종료 시도 시
- 앱 접속 누적 2회 이상
- `PopScope` onPopInvokedWithResult 콜백에서 체크

### 공통 필터
- `review_disabled == true` → 팝업 안 띄움 (영구 비활성)
- `review_last_shown` 기준 14일 미경과 → 팝업 안 띄움
- `review_shown_count >= 3` → 영구 비활성 처리 후 팝업 안 띄움

---

## 상태 관리 (SharedPreferences)

| 키 | 타입 | 설명 |
|----|------|------|
| `review_disabled` | bool | 영구 비활성 여부 |
| `review_last_shown` | int | 마지막 노출 Unix timestamp (ms) |
| `review_shown_count` | int | 누적 팝업 노출 횟수 |
| `app_launch_count` | int | 앱 접속 누적 횟수 |
| `app_first_launch_date` | int | 첫 실행 Unix timestamp (ms) |
| `trade_complete_count` | int | 거래 완료 누적 횟수 |

---

## 유저 행동별 상태 변화

| 행동 | 상태 변화 |
|------|----------|
| Step 1 [좋아요!] | `review_shown_count++`, `review_last_shown = now` |
| Step 1 [별로예요] | `review_shown_count++`, `review_last_shown = now` |
| Step 2 [리뷰 남기기] | `review_disabled = true` (영구 비활성) |
| Step 2 [나중에] | `review_last_shown = now` (14일 쿨타임) |
| 팝업 외부 탭/닫기 | `review_last_shown = now` (14일 쿨타임) |
| `shown_count >= 3` | `review_disabled = true` (영구 비활성) |

---

## 컴포넌트 설계

### `AppReviewService` (신규)
위치: `lib/services/app_review_service.dart`

책임:
- SharedPreferences CRUD (모든 리뷰 팝업 상태)
- 팝업 표시 여부 판단 (`shouldShow()`)
- `in_app_review` 호출 + 스토어 링크 폴백
- 앱 실행 횟수, 첫 실행일 기록

```dart
class AppReviewService {
  Future<bool> shouldShow();          // 팝업 표시 여부 판단
  Future<void> markShown();           // 노출 기록 (shown_count++, last_shown)
  Future<void> markPermanentlyDone(); // 영구 비활성
  Future<void> requestReview();       // in_app_review → 폴백
  Future<void> incrementLaunchCount(); // 앱 실행 시 호출
  Future<void> incrementTradeCount(); // 거래 완료 시 호출
}
```

### `AppReviewPopup` (신규)
위치: `lib/widgets/common/app_review_popup.dart`

책임:
- Step 1/2 팝업 순서 제어
- `CommonModal` 팩토리 메서드 호출
- `AppReviewService` 콜백 처리

```dart
class AppReviewPopup {
  // static 메서드로 팝업 시퀀스 실행
  static Future<void> show(BuildContext context, AppReviewService service);
}
```

### 트리거 포인트 (기존 파일 수정)

| 파일 | 수정 내용 |
|------|----------|
| `lib/main.dart` | 앱 시작 시 `incrementLaunchCount()` 호출 |
| `lib/screens/trade_review_screen.dart` | 거래 완료 콜백에서 `AppReviewPopup.show()` 호출 |
| 홈 화면 최상위 Scaffold | `PopScope` → 앱 종료 시도 시 `AppReviewPopup.show()` 호출 |

---

## 의존성

| 패키지 | 용도 | 현재 상태 |
|--------|------|----------|
| `in_app_review` | 네이티브 리뷰 다이얼로그 | **신규 추가 필요** |
| `shared_preferences` | 상태 저장 | 이미 있음 (`^2.5.2`) |
| `url_launcher` | 스토어 링크 폴백 | 이미 있음 (`^6.3.2`) |

`pubspec.yaml`에 추가:
```yaml
in_app_review: ^2.0.9
```

---

## 스토어 링크 (폴백용)

- **iOS (App Store):** `https://apps.apple.com/app/id6748823976`
- **Android (Play Store):** `https://play.google.com/store/apps/details?id=com.alom.romrom`

플랫폼 분기: `Platform.isIOS` / `Platform.isAndroid`

---

## 에러 처리

- `in_app_review.isAvailable()` → false이면 스토어 링크로 폴백
- 스토어 링크 `canLaunchUrl` 실패 시 조용히 무시 (팝업만 닫기)
- `BuildContext` unmounted 체크 필수 (비동기 콜백 이후)

---

## 구현 범위 외

- 백엔드 연동 없음 (순수 로컬 상태)
- 별점 수집/분석 서버 전송 없음
- 커스텀 별점 UI 없음 (네이티브 다이얼로그 사용)
