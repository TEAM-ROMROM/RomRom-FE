# 물품 좋아요 연타 시 입력 누락 및 반응 지연 개선 (#853)

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/853
- 작성일: 2026-06-20

## 문제 정의

물품 카드/상세 화면에서 좋아요 버튼을 누를 때 두 가지 문제가 있다.

1. **반응 지연** — 홈 피드/상세 화면의 좋아요 핸들러가 `await MemberManager.isCurrentMember()`(본인 게시글 여부 확인)를 먼저 기다린 뒤에야 `toggle()`을 호출한다. 본인글 판별은 "내 ID == 글쓴이 ID" 비교가 전부인데 `Future`로 감싸여 `await`되므로, 최소 1 이벤트루프 틱(첫 호출 시엔 SharedPreferences I/O)만큼 하트 반응이 늦어진다.
2. **입력 누락(씹힘)** — `ItemLikeNotifier.toggle()`은 동일 itemId 요청이 진행 중(`_inFlight`)이면 추가 입력을 **그냥 버린다**. 연타하면 사용자의 마지막 클릭 의도와 다른 상태로 남을 수 있다.

핵심 사실: 내 `memberId`는 `UserInfo` 싱글톤의 메모리 필드라 로그인 후엔 `MemberManager.cachedMemberId`로 **await 없이 동기적으로 즉시** 읽을 수 있다. 본인글 판별을 굳이 await할 이유가 없다.

## 목표

- 좋아요 버튼을 누르는 즉시 하트 상태/카운트가 반응한다 (지연 제거).
- 연속 클릭 시에도 최종 UI 상태가 마지막 클릭 의도와 항상 일치한다 (큐잉/보정).
- 본인 게시글 좋아요 제한은 유지하되, 일반 물품 반응이 지연되지 않는다.
- optimistic 즉시 반영 / 실패 롤백 / 스낵바 등 기존 동작은 유지한다.

## 비목표 (YAGNI)

- `ItemLikeState` 모델 변경 없음 (큐 상태는 UI 노출 불필요한 내부값).
- 4-레이어 구조(repository/state/provider) 재설계 없음.
- 좋아요 외 다른 토글류(차단/알림설정 등)는 건드리지 않음.

## 설계

### 변경 범위

모든 변경은 `ItemLikeNotifier`(provider) 한 곳과 소비처 3곳에 집중된다.

| 파일 | 변경 |
|------|------|
| `lib/providers/item_like_provider.dart` | `toggle()`에 ① 연타 큐잉 ② 본인글 동기 체크 흡수 |
| `lib/widgets/home_feed_item_widget.dart` | `await isCurrentMember()` 제거 → `toggle(id, authorMemberId: ...)` 한 줄 |
| `lib/screens/item_detail_description_screen.dart` | `await isCurrentMember()` 제거 → `toggle(id, authorMemberId: ...)` 한 줄 |
| `lib/screens/my_page/my_like_list_screen.dart` | 변경 없음 (좋아요 목록엔 본인글 없으므로 authorMemberId 안 넘김) |

### `ItemLikeNotifier` 상태

```dart
final Set<String> _inFlight = <String>{};                 // 기존 — 요청 진행 중 추적
final Map<String, bool> _pendingIntent = <String, bool>{}; // 신규 — itemId별 "마지막 클릭 의도(isLiked)"
```

- `_pendingIntent[itemId]`: 진행 중 추가 탭이 들어올 때 사용자가 최종적으로 원하는 `isLiked` 값을 덮어쓰며 저장. 요청 완료 시점에 이 값과 서버 결과를 비교해 추가 동기화 여부를 결정한다.

### `toggle()` 동작 흐름

```
toggle(itemId, {authorMemberId}):
  ① 본인글 체크 (동기, await 없음)
     myId = MemberManager.cachedMemberId
     if (myId != null && authorMemberId != null && myId == authorMemberId):
       본인글 → 스낵바("본인 게시글에는 좋아요를 누를 수 없습니다.") 후 return
       (스낵바는 navigatorKey.currentContext 사용 — 기존 실패 스낵바와 동일 방식)

  ② 진행 중이면 큐잉 (버리지 않음)
     if (_inFlight.contains(itemId)):
       _pendingIntent[itemId] = !(현재 state[itemId].isLiked)   // 마지막 의도
       state = optimistic 반영 (UI 즉시 토글)
       return

  ③ 첫 요청 — optimistic 반영 + 서버 호출 (기존 로직)
     _inFlight.add(itemId)
     prev = state[itemId]; optimistic 반영
     try:
       res = await repo.postLike(itemId)
       state = 서버값으로 확정
     catch:
       state = prev 롤백 + 에러 스낵바
     finally:
       _inFlight.remove(itemId)

  ④ 요청 완료 후 — 큐 보정
     if (_pendingIntent.containsKey(itemId)):
       intent = _pendingIntent.remove(itemId)
       if (intent != 현재 확정된 state[itemId].isLiked):
         toggle(itemId)   // 1회 추가 동기화 (재귀, 이번엔 inFlight 비어있음)
       else:
         skip (이미 의도와 일치 — 불필요한 서버 호출 안 함)
```

**연타 시나리오** (탭1 좋아요 → 탭2 취소 → 탭3 좋아요):

- 탭1: 요청A 시작, UI=좋아요, `_inFlight={item}`
- 탭2: 진행 중 → UI=취소(즉시), `_pendingIntent[item]=false`
- 탭3: 진행 중 → UI=좋아요(즉시), `_pendingIntent[item]=true`
- 요청A 완료 → 서버 확정값과 `_pendingIntent[item]=true` 비교
  - 다르면 1회 추가 요청, 같으면 skip
- **결과: 마지막 의도(좋아요)와 항상 일치** ✅

### 소비처 변경 (Before/After)

`home_feed_item_widget.dart` (약 290라인):

```dart
// Before
onTap: () async {
  final id = widget.item.itemUuid;
  if (id == null || id.isEmpty) return;
  final isCurrentMember = await MemberManager.isCurrentMember(widget.item.authorMemberId);
  if (isCurrentMember) { ...스낵바...; return; }
  await ref.read(itemLikeProvider.notifier).toggle(id);
}

// After
onTap: () {
  final id = widget.item.itemUuid;
  if (id == null || id.isEmpty) return;
  ref.read(itemLikeProvider.notifier).toggle(id, authorMemberId: widget.item.authorMemberId);
}
```

`item_detail_description_screen.dart` `_toggleLike()` (약 1083라인): 동일 패턴. `await isCurrentMember()` 제거, `toggle(id, authorMemberId: item?.member?.memberId)` 호출.

## 엣지케이스 & 에러 처리

- **cachedMemberId 비어있음** (로그인 직후 등 드묾): 본인글 판별 불가 → toggle 진행. 서버가 본인글 좋아요를 거부하면 catch → 롤백 + 스낵바(기존 흐름). 캐시 miss여도 안전.
- **추가 동기화 요청도 실패**: 기존 catch로 직전 값 롤백 + 에러 스낵바.
- **여러 itemId 동시 연타**: `_inFlight`/`_pendingIntent`가 itemId별 Set/Map이라 서로 간섭 없음.
- **위젯 dispose 후 응답 도착**: notifier는 provider 소유라 위젯 생명주기와 무관. 스낵바만 `currentContext` null 체크.
- **무한 재귀 방지**: ④의 추가 toggle은 `_pendingIntent`를 먼저 `remove`한 뒤 호출하므로, 추가 요청 중 다시 연타가 없으면 한 번만 보정하고 끝난다.
- **④ 재귀 호출 시 authorMemberId 생략**: 본인글 체크(①)는 첫 호출에서 이미 통과했으므로 재귀 보정 호출엔 `authorMemberId`를 넘기지 않는다(다시 검사 불필요).

## 테스트 (TDD)

`test/providers/item_like_provider_test.dart` (repository를 override로 가짜 주입):

1. 단일 toggle → optimistic 즉시 반영 + 서버값 보정
2. 연타 3회(좋→취소→좋) → 최종 상태 = 좋아요 (큐잉 검증)
3. 연타 후 최종 의도 == 서버 결과 → 추가 요청 **안 함** (불필요 호출 방지)
4. 본인글(authorMemberId == cachedMemberId) → toggle 무시 + 상태 불변
5. 첫 요청 실패 → prev 롤백
6. 추가 동기화 요청 실패 → 롤백

## 작업 후 검증

```bash
source ~/.zshrc && dart format --line-length=120 .
source ~/.zshrc && flutter analyze
source ~/.zshrc && flutter test test/providers/item_like_provider_test.dart
```
