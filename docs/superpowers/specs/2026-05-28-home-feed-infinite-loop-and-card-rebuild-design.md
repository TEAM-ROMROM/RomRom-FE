# 홈 피드 무한 순환 + 카드 재로딩 애니메이션 제거 설계

- 작성일: 2026-05-28
- 대상 파일: `lib/screens/home_tab_screen.dart`, `lib/widgets/home_feed_item_widget.dart`
- 범위: **FE 전용** (BE 변경 없음)

## 배경 / 문제

홈 탭 추천 물품 피드에서 두 가지 문제가 보고됨.

### 이슈 A — 끝 도달 시 멈춤 (순환 안 됨)
세로 `PageView`로 물품을 넘기다 전체 물품을 다 보면 더 내려가지지 않고 멈춘다.
현재 `_loadMoreItems()`는 서버가 빈 배열을 반환하면 `_hasMoreItems = false`로 두어
추가 로드를 중단한다(`home_tab_screen.dart:368`). 사용자는 **끊김 없이 다시 처음으로
되감아 이어지는(또돌이표)** 동작을 원한다.

### 이슈 B — 카드 넘길 때마다 재로딩(shimmer) 애니메이션
물품 카드를 한 칸 넘길 때마다 이미지 로딩 placeholder(shimmer)가 다시 뜬다.
이미 본 카드인데도 재로딩처럼 보여 거슬린다.

근본 원인: 세로 `PageView.builder`(`home_tab_screen.dart:586`)가 생성하는
`HomeFeedItemWidget`에 **`key`가 없다**. Flutter가 State를 인덱스 기반으로 재활용해,
카드를 넘기면 이미 본 카드도 재빌드되며 `CachedNetworkImage`가 shimmer placeholder를
다시 표시한다.

## 범위에서 제외 (결정 사항)

- **"안 본 물품부터 시작" / 진행 위치 복원 / 순서 다양화** — 제외.
  - 탭 전환은 `MainScreen`이 `IndexedStack`이라 이미 세션 내 위치가 메모리에 유지된다.
  - 추천 피드(RECOMMENDED 정렬)에서 "본 위치 SharedPreferences 복원"은 적합하지 않다
    (시간이 지나면 새 물품이 등록되므로 옛 위치 복원은 오히려 신규 물품 노출을 막음).
  - 유저별 "이미 본 물품" 추적은 BE 변경(seen/커서)이 필요하며 별도 일감으로 분리한다.
- **순환 시 `_feedItems` 메모리 상한/트리밍** — 제외 (YAGNI).
  - 카드 객체는 가볍고(텍스트 + 캐시된 이미지 URL) 앱 재시작 시 비워진다.
  - 앞부분 트리밍은 `PageController` 위치·광고 가상인덱스 보정이 복잡해 버그 위험만 키운다.

## 설계

### 이슈 A — 끝 순환 (page 0 리셋 후 이어붙이기)

대상: `home_tab_screen.dart`의 `_loadMoreItems()` 한 곳.

변경 동작:
1. 기존대로 `_currentPage += 1` 후 다음 페이지를 요청한다.
2. 응답 `content`가 **비어 있으면** = 한 바퀴 끝에 도달:
   - `_currentPage = 0`으로 리셋하고 page 0을 다시 요청한다.
   - 재요청 결과를 `_feedItems`에 `addAll` 한다.
   - `_hasMoreItems`는 **true로 유지**한다(계속 순환 가능).
   - **엣지 케이스**: 리셋 후 받은 page 0 결과도 비어 있으면 = 전체 물품이 0개.
     이때만 `_hasMoreItems = false`로 두어 무한 루프를 방지한다.
3. 응답 `content`가 있으면: 기존대로 `addAll`, `_currentPage`/`_hasMoreItems` 유지.

`sortField`는 순환 후에도 `_currentSortField`를 그대로 사용한다(정렬 일관성 유지).
무한 스크롤 트리거(`NotificationListener` → `maxScrollExtent` 감지, `home_tab_screen.dart:581`)와
광고 삽입 로직(`_virtualItemCount` 등)은 변경하지 않는다 — `_feedItems`가 계속 늘어나는
구조를 그대로 활용한다.

### 이슈 B — 카드 재빌드/재로딩 제거 (ValueKey 부여)

대상: `home_tab_screen.dart`의 `itemBuilder`에서 `HomeFeedItemWidget` 생성부(`:617`).

변경: 카드에 `key`를 부여해 각 카드가 고유 State를 유지하게 한다.

```dart
return HomeFeedItemWidget(
  key: ValueKey('${item.itemUuid ?? item.id}_$feedIndex'),
  item: item,
  showBlur: _isBlurShown,
  onAiRecommend: _onAiRecommend,
);
```

키 설계 근거:
- 순환(이슈 A)으로 같은 `itemUuid` 카드가 리스트에 **중복 등장**한다.
  `ValueKey(itemUuid)`만 쓰면 키가 충돌해 서로 다른 카드가 같은 State를 공유하는 버그가 생긴다.
- 따라서 키에 `_feedItems` 내 **절대 위치(`feedIndex`)**를 포함해 유일성을 보장한다.
- 이미지 캐시는 URL 기반(`CachedNetworkImage`)이라 키가 달라도 재다운로드는 일어나지 않는다
  → shimmer placeholder가 다시 뜨지 않는다.

`onPageChanged`의 `setState`(`:595`)는 상단 알림/리포트 버튼 표시 조건에 필요하므로 유지한다.
key가 붙으면 itemBuilder가 재실행돼도 각 카드 State가 보존되어 shimmer 재등장은 사라진다.
즉 ValueKey 부여만으로 핵심이 해결되며, `onPageChanged` 추가 최적화는 적용 후 실기기 확인으로
필요성을 판단한다(현 시점 변경 대상 아님).

## 검증 (실기기)

폐쇄망이므로 빌드/실행은 사용자가 별도 환경에서 수행한다.

- 이슈 A: 피드를 끝까지 내린다 → 멈추지 않고 처음 물품들이 이어서 다시 나타난다(또돌이표).
  스크롤이 끊기지 않는다.
- 이슈 B: 카드를 위로 여러 개 넘긴 뒤 다시 아래로 스크롤 → shimmer 없이 즉시 이미지가 표시된다.
- 회귀 점검: 광고 슬롯이 기존 패턴([아이템 2, 광고 1])대로 끼고, AI 추천 하이라이트 및
  상단 알림/리포트 버튼이 정상 동작한다.

## 영향 범위

- `home_tab_screen.dart`: `_loadMoreItems()` 로직, `itemBuilder`의 카드 key 추가. 2개 지점.
- 광고/AI/이벤트버스 로직은 건드리지 않음.
- BE·API·모델 변경 없음.
