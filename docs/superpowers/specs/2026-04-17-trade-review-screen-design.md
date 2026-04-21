# 거래 후기 작성 화면 설계 스펙

**날짜:** 2026-04-17

---

## 개요

거래 완료 후 상대방에 대한 후기를 남기는 2단계 화면.
채팅방에서 거래 완료 요청 수락 후, 또는 요청 관리 탭에서 교환 완료 처리 후 진입.

---

## 진입 조건 및 파라미터

```dart
TradeReviewScreen({
  required String tradeRequestHistoryId,
  required String opponentNickname,
})
```

**진입 포인트 1 — 채팅방 (`chat_room_screen.dart`)**
- `_onConfirmTradeRequest()` 성공 후 `context.navigateTo(screen: TradeReviewScreen(...))`

**진입 포인트 2 — 요청 관리 탭 (`request_management_tab_screen.dart`)**
- 받은 요청에서 교환 완료 처리 성공 후 `context.navigateTo(screen: TradeReviewScreen(...))`

---

## 화면 구조

단일 `TradeReviewScreen` 위젯에서 `_step` (int: 1 또는 2) 으로 내부 전환.

### 내부 상태

| 변수 | 타입 | 설명 |
|------|------|------|
| `_step` | `int` | 현재 단계 (1 or 2) |
| `_rating` | `TradeReviewRating?` | 만족도 선택값, null이면 다음 버튼 비활성 |
| `_selectedTags` | `Set<TradeReviewTag>` | 선택된 칭찬 태그 목록 |
| `_commentController` | `TextEditingController` | 한마디 입력 |
| `_isSubmitting` | `bool` | API 중복 방지 |

---

## 1단계: 만족도 선택

- `Scaffold(backgroundColor: AppColors.primaryBlack)`
- 상단 좌측 X 아이콘 → `Navigator.pop(context)` (후기 작성 취소)
- 제목: `RichText` + `TextSpan`
  - 닉네임 부분: `AppColors.primaryYellow`
  - 나머지 텍스트: 흰색
  - 예: `"[상대방 닉네임]님과의\n교환은 어떠셨나요?"`
- 감정 선택 3개 (가로 배치):
  - 원형 Container placeholder (이미지 에셋 추후 교체 예정)
  - 미선택: 회색 배경 / 선택됨: 밝은 배경
  - 레이블: 별로예요(BAD) / 좋아요(GOOD) / 최고에요(GREAT)
- 하단 고정 버튼: `CompletionButton`
  - `isEnabled: _rating != null`
  - `buttonText: '다음'`
  - 탭 시 `setState(() => _step = 2)`

---

## 2단계: 세부 칭찬 입력 (`member_report_screen.dart` 구조 참고)

- `resizeToAvoidBottomInset: false`
- `Scaffold` + `Stack(fit: StackFit.expand)`
- 상단 좌측 < 아이콘 → `setState(() => _step = 1)` (화면 pop 아님)
- 제목: "어떤 점이 좋았나요?" (`CustomTextStyles.h2`)

**콘텐츠 (SingleChildScrollView → Column):**
- 체크박스 5개 (`_buildTagRow` 메서드):
  - 답장이 빨라요 (FAST_RESPONSE)
  - 물건 상태가 좋아요 (GOOD_ITEM_CONDITION)
  - 사진과 같아요 (MATCHES_PHOTO)
  - 약속을 잘 지켜요 (PUNCTUAL)
  - 친절해요 (KIND)
  - 체크박스: `activeColor: AppColors.primaryYellow`, `checkColor: AppColors.primaryBlack`
- "한마디를 남겨주세요" 헤더 (`CustomTextStyles.h3` 또는 h2)
- TextField:
  - 배경: `AppColors.secondaryBlack1`
  - placeholder: "매너 있는 교환 파트너를 칭찬해주세요"
  - `maxLines: null`, 테두리 `AppColors.opacity30White`
- `SizedBox(height: 180.h)` — 하단 버튼 겹침 방지

**하단 고정 버튼 (`Positioned`):**
- 건너뛰기: `CompletionButton(enabledBackgroundColor: AppColors.secondaryBlack2, buttonText: '건너뛰기')`
  - rating만 포함, tags/comment 비워서 제출
- 완료: `CompletionButton(buttonText: '완료', isLoading: _isSubmitting)`
  - 모든 데이터 포함하여 제출

---

## API 연동

### `trade_request.dart` 추가 필드

```dart
String? tradeReviewRating;      // BAD / GOOD / GREAT
List<String>? tradeReviewTags;  // FAST_RESPONSE 등
String? reviewComment;
```

`build_runner`로 `trade_request.g.dart` 재생성 필요.

### `trade_api.dart` 추가 메서드

```
POST /api/trade/review/post
인증: JWT 필요
```

```dart
Future<void> postTradeReview(TradeRequest request) async { ... }
```

### Enum 신규 파일

**`lib/enums/trade_review_rating.dart`**
```dart
enum TradeReviewRating { bad, good, great }
// serverName: BAD / GOOD / GREAT
// label: 별로예요 / 좋아요 / 최고에요
```

**`lib/enums/trade_review_tag.dart`**
```dart
enum TradeReviewTag { fastResponse, goodItemCondition, matchesPhoto, punctual, kind }
// serverName: FAST_RESPONSE / GOOD_ITEM_CONDITION / MATCHES_PHOTO / PUNCTUAL / KIND
// label: 답장이 빨라요 / 물건 상태가 좋아요 / 사진과 같아요 / 약속을 잘 지켜요 / 친절해요
```

---

## 제출 후 동작

- 건너뛰기 / 완료 버튼 → API 호출 성공 → 홈 화면으로 이동 (스택 클리어)
  - `context.navigateTo(screen: MainScreen(), type: NavigationTypes.pushAndRemoveUntil)`
- API 실패 시 `CommonModal.error` 표시, 화면 유지

---

## 신규/수정 파일 목록

| 파일 | 구분 |
|------|------|
| `lib/screens/trade_review_screen.dart` | 신규 |
| `lib/enums/trade_review_rating.dart` | 신규 |
| `lib/enums/trade_review_tag.dart` | 신규 |
| `lib/services/apis/trade_api.dart` | 수정 (postTradeReview 추가) |
| `lib/models/apis/requests/trade_request.dart` | 수정 (필드 3개 추가) |
| `lib/models/apis/requests/trade_request.g.dart` | build_runner 재생성 |
| `lib/screens/chat_room_screen.dart` | 수정 (진입 플로우 연결) |
| `lib/screens/request_management_tab_screen.dart` | 수정 (진입 플로우 연결) |
