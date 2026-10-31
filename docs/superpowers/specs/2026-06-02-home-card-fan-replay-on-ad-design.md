# 홈탭 내 물건 카드 펼침 애니메이션 광고 진입 시 재실행 버그 — 설계

작성일: 2026-06-02

## 문제

홈탭 하단 "내 물건 카드 덱"(`HomeTabCardHand`)은 최초 렌더 시 카드들이 모여 있다가 부채꼴로 펼쳐지는 팬 애니메이션(`_fanController`, 1000ms)을 1회 재생한다. 그런데 PageView를 스와이프해 **광고 슬롯으로 전환될 때마다 이 펼침 애니메이션이 0부터 풀로 재생**된다. 일반 상품 → 일반 상품 전환에서는 발생하지 않고, **광고 슬롯이 끼는 전환에서만 100% 재현**된다. 사용자가 광고 등장을 애니메이션으로 미리 눈치챈다.

## 근본 원인

`lib/screens/home_tab_screen.dart`의 `_buildContent` 내부 `Stack` children이 광고 진입 시 **개수가 달라진다**.

```
[0] Positioned.fill(PageView)                         // 항상 존재, key 없음
[1] if (!isBlurShown && !_isAdAtVirtualIndex(...))    // 알림아이콘 블록 — 광고일 때 빠짐!
       Positioned(...)                                // key 없음
[2] if (!isBlurShown) HomeTabCardHand                 // key: ValueKey('home_card_hand')
    else if (...) 등록 버튼
```

- 일반 카드: `Stack.children = [PageView, 알림블록, HomeTabCardHand]` (3개)
- 광고 슬롯: `Stack.children = [PageView, HomeTabCardHand]` (2개, 알림블록 제거)

`onPageChanged`에서 `_currentVirtualIndex`가 갱신되며 `setState` → `Stack` rebuild. 광고 진입 시 `HomeTabCardHand` **앞 형제(알림블록)가 사라져 children 정렬이 한 칸 밀린다**. Flutter의 multi-child reconcile은 위치 + key로 element를 매칭하는데, keyed 위젯이라도 앞쪽 non-keyed 형제 개수가 바뀌면 매칭이 깨지며 `HomeTabCardHand`의 State가 **dispose → 새로 initState(remount)** 된다.

`_fanController`는 `initState`의 `_initializeAnimations()`에서 500ms 지연 후 `forward()`를 **1회만** 호출하고, `didUpdateWidget`/`build` 어디에서도 reset/forward를 재호출하지 않는다(검증 완료: `_fanController` 참조는 생성·forward·dispose·AnimatedBuilder listen뿐). 따라서 풀 펼침이 다시 재생되는 **유일한 경로는 위젯 remount**다. 일반→일반은 children 개수가 불변이라 remount가 없고, 광고 전환에서만 개수가 변해 remount → "광고일 때만 100%"와 정확히 일치한다.

## 해결 (접근법 A)

알림아이콘 블록을 **조건부 `if`로 트리에서 추가/제거하지 않는다.** 항상 `Stack`에 둔 채 광고 슬롯일 때 `Offstage`로 숨긴다. 그러면 `HomeTabCardHand` 앞 형제 개수가 광고 여부와 무관하게 항상 동일 → element 매칭 안정 → remount 사라짐 → 팬 애니메이션 1회 정책 유지.

### 변경 대상
`lib/screens/home_tab_screen.dart` — 알림아이콘 블록(현재 line 595 부근).

### 변경 전
```dart
// 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 숨김
if (!isBlurShown && !_isAdAtVirtualIndex(_currentVirtualIndex))
  Positioned(
    right: 16.w,
    top: ...,
    child: Row( ... ),
  ),
```

### 변경 후
```dart
// 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 Offstage로 숨김(트리에서 제거하지 않음)
// → Stack children 개수를 광고 여부와 무관하게 고정시켜 HomeTabCardHand remount(팬 애니메이션 재생) 방지
if (!isBlurShown)
  Positioned(
    right: 16.w,
    top: ...,
    child: Offstage(
      offstage: _isAdAtVirtualIndex(_currentVirtualIndex),
      child: Row( ... ),
    ),
  ),
```

핵심: 바깥 조건에서 `!_isAdAtVirtualIndex(...)`를 제거하고, 그 판정을 안쪽 `Offstage(offstage:)`로 옮긴다. `isBlurShown` 조건은 그대로 둔다.

### 왜 `isBlurShown` 갈래는 건드리지 않나
블러 상태(`myCards.isEmpty`)에서는 `HomeTabCardHand` 자체가 `if (!isBlurShown)` 갈래(line 655)에서 함께 빠지고 대신 등록버튼 갈래로 간다. 블러 토글은 광고 스와이프와 독립된 상태 전환이며 이번 버그(광고 전환 시 재생)와 무관하므로 범위에서 제외한다.

### Offstage 선택 이유
- `Offstage(offstage:true)`는 레이아웃·페인트·히트테스트를 모두 건너뛰어 시각/입력상 완전히 숨김 — 기존 `if` 제거와 동일한 사용자 경험.
- 단 element는 트리에 유지 → children 개수 고정 → reconcile 안정. 정확히 이 버그를 직격한다.
- `Visibility(maintainState:...)` 류 대비 가장 단순하고 의도가 명확.

## 영향 범위 / 회귀 가능성
- 광고 슬롯에서 알림아이콘·신고버튼은 여전히 보이지 않음(`offstage:true`) — UX 동일.
- 일반 슬롯에서는 그대로 노출.
- 광고 중에도 알림블록 element가 살아있으나 `Offstage`라 렌더 비용 거의 없음. `_hasUnreadNotification` 상태는 본래 별도 로드라 영향 없음.
- `HomeTabCardHand`는 광고 전환에도 더 이상 remount되지 않음 → 팬 애니메이션 1회 유지.

## 검증
- 내부망: `dart format --line-length=120 .`만 실행. 빌드/실기기 재현 테스트는 사용자가 별도 환경에서 수행.
- 수동 QA: 홈탭에서 광고가 끼는 전환을 반복 스와이프 → 내 물건 카드 펼침 애니메이션이 **재생되지 않아야** 함. 일반→일반 동작·드래그(`dragEnabled`)·알림/신고버튼 노출은 기존과 동일해야 함.
