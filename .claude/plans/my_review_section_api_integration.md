# 🎯 MyReviewSection API 연동 전략 문서

## 1. 요약

`MyReviewSection`을 `StatefulWidget`으로 전환하고 `TradeApi().getTradeReview()`를 호출하여 실제 후기 데이터(rating별 개수, 태그별 개수, 코멘트 리스트)를 표시한다. `UserInfo().getCurrentMemberId()`로 추가 API 없이 현재 사용자 memberId를 가져와 요청한다.

---

## 2. 배경 및 목적

**문제/필요성**: `MyReviewSection` 전체가 하드코딩된 더미 데이터(`'24'`, `'닉네임'`, `'위치'`, `'후기 코멘트'`)로 되어 있고, 실제 서버 데이터 연동이 없는 상태.

**목표**: `TradeApi().getTradeReview()` 호출 → 응답 데이터로 rating 카운트, 태그 카운트(내림차순 정렬), 코멘트 리스트를 실제 렌더링

**범위**:
- 포함: `MyReviewSection` 위젯 단독 수정
- 제외: 페이지네이션(스크롤 시 더보기), 부모 스크린 수정

---

## 3. 요구사항

**필수 (P0)**:
- `StatelessWidget` → `StatefulWidget` 전환
- `UserInfo().getCurrentMemberId()`로 memberId 획득 (추가 API 호출 없음)
- `TradeApi().getTradeReview(TradeRequest(member: Member(memberId: id), pageNumber: 0, pageSize: 10))` 호출
- `TradeReviewRating` 별 카운트 (`BAD`/`GOOD`/`GREAT`) → `_buildRatingCountColumn` 표시
- `TradeReviewTag` 별 카운트, 내림차순 정렬 → `_buildRatingReviewTag` 표시
- `TradeReview` 리스트 → `reviewer.nickname`, `reviewer.locationAddress`, `reviewComment` 표시
- 로딩 중 `LoadingIndicator` 표시

**중요 (P1)**:
- 후기 없을 때 빈 상태 처리 (카운트 0, 코멘트 섹션 숨김)
- 에러 시 무시 (서버 오류여도 UI 깨지지 않도록 빈 리스트로 처리)

**선택 (P2)**:
- 페이지네이션 (무한 스크롤)

---

## 4. 선택한 접근 방식

**방식**: `MyReviewSection` 자체 데이터 로드 (self-contained)

**이유**:
- `MyExchangeSection`과 동일한 패턴 — 부모 스크린에 의존하지 않고 자체 `initState`에서 데이터 로드
- `UserInfo`가 싱글톤으로 캐시된 memberId를 제공하므로 추가 API 호출 불필요
- 부모(`MyProfileEditScreen`)를 수정하지 않아도 됨

**대안**: 부모에서 memberId 파라미터로 전달
- 부모 스크린도 수정해야 하고, `const MyReviewSection()` → `MyReviewSection(memberId: ...)` 로 변경 필요
- 패턴 일관성이 깨짐 (`MyExchangeSection`은 파라미터 없음)

---

## 5. 주요 결정사항

| 결정 | 선택 | 이유 |
|------|------|------|
| memberId 획득 | `UserInfo().getCurrentMemberId()` | 추가 API 호출 없이 캐시에서 바로 획득 |
| 첫 페이지 사이즈 | `pageSize: 10` | MVP 기준. 무한스크롤은 P2 |
| 태그 정렬 | 카운트 내림차순 | 많이 받은 태그가 앞에 오도록 |
| 코멘트 없는 리뷰 | 렌더링 포함 | reviewer 정보는 보여줌 (코멘트 null이면 빈 칸) |
| 에러 핸들링 | catch → empty list | UI가 깨지지 않는 것을 우선 |

---

## 6. 구현 상세

### 6-1. 상태 변수 (State)

```dart
List<TradeReview> _reviews = [];
bool _isLoading = true;
```

### 6-2. 데이터 처리 헬퍼 (State 내부)

```dart
// Rating별 카운트 Map
Map<TradeReviewRating, int> get _ratingCounts {
  final counts = {for (final r in TradeReviewRating.values) r: 0};
  for (final review in _reviews) {
    final rating = TradeReviewRating.values.firstWhereOrNull(
      (r) => r.serverName == review.tradeReviewRating,
    );
    if (rating != null) counts[rating] = (counts[rating] ?? 0) + 1;
  }
  return counts;
}

// Tag별 카운트 Map, 내림차순 정렬 Entry 리스트
List<MapEntry<TradeReviewTag, int>> get _sortedTagCounts {
  final counts = <TradeReviewTag, int>{};
  for (final review in _reviews) {
    for (final tagStr in review.tradeReviewTags ?? []) {
      final tag = TradeReviewTag.values.firstWhereOrNull(
        (t) => t.serverName == tagStr,
      );
      if (tag != null) counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
}
```

> `firstWhereOrNull`은 `package:collection` — 이미 의존성에 포함되어 있는지 확인 필요. 없으면 직접 for-loop으로 대체.

### 6-3. `_loadReviews` 메서드

```dart
Future<void> _loadReviews() async {
  try {
    final memberId = await UserInfo().getCurrentMemberId();
    final response = await TradeApi().getTradeReview(
      TradeRequest(
        member: Member(memberId: memberId),
        pageNumber: 0,
        pageSize: 10,
      ),
    );
    if (mounted) {
      setState(() => _reviews = response.tradeReviewPage?.content ?? []);
    }
  } catch (e) {
    debugPrint('거래 후기 로드 실패: $e');
    if (mounted) setState(() => _reviews = []);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### 6-4. UI 변경 포인트

| 위치 | 변경 전 | 변경 후 |
|------|---------|---------|
| `_buildRatingCountColumn` | `'24'` 하드코딩 | `_ratingCounts[rating].toString()` |
| Wrap 태그 목록 | `TradeReviewTag.values` 순회 | `_sortedTagCounts` 순회 |
| `_buildRatingReviewTag` | `'24'` 하드코딩 | `entry.value.toString()` |
| `_buildReviewComment()` | 단일 더미 | `ListView` / `Column`으로 `_reviews` 반복 |
| reviewer 아바타 | `UserProfileCircularAvatar` 고정 | `CachedImage` 또는 `UserProfileCircularAvatar` with `profileUrl` |
| 닉네임 | `'닉네임'` | `review.reviewer?.nickname ?? '-'` |
| 위치 | `'위치'` | `review.reviewer?.locationAddress ?? ''` |
| 후기 코멘트 | `'후기 코멘트'` | `review.reviewComment ?? ''` |

### 6-5. 로딩 처리

```dart
if (_isLoading) return const LoadingIndicator();
```

---

## 7. 의존성 확인 필요

- [ ] `package:collection` (`firstWhereOrNull`) — `pubspec.yaml` 확인
- [ ] `UserProfileCircularAvatar` — `profileUrl` 파라미터 수락 여부 확인. 안 되면 `CachedImage`로 대체

---

## 8. 수정 파일 목록

| 파일 | 변경 내용 |
|------|---------|
| `lib/widgets/profile/my_review_section.dart` | `StatefulWidget` 전환, API 연동, UI 실데이터 바인딩 |

> `trade_api.dart`, `trade_response.dart`, `trade_request.dart`는 이미 수정 완료된 상태로 추가 변경 불필요.

---

## 9. 성공 기준

- [ ] 화면 진입 시 로딩 인디케이터 표시
- [ ] 후기 데이터 로드 후 `BAD`/`GOOD`/`GREAT` 카운트 실제 값 표시
- [ ] 태그가 받은 개수 내림차순으로 정렬되어 표시
- [ ] 후기 코멘트 리스트: 닉네임, 위치, 코멘트 실제 값 표시
- [ ] 후기 없을 때 카운트 0, 코멘트 리스트 비어있음 (UI 깨짐 없음)
- [ ] `flutter analyze` 에러 없음

---

## 10. 다음 단계

→ `/analyze`로 `UserProfileCircularAvatar` 파라미터 및 `package:collection` 의존성 확인 후 `/implement` 진행
