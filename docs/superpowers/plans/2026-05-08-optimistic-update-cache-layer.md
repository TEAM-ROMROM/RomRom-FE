# Optimistic Update + Riverpod 캐시 레이어 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 좋아요·차단·알림 토글 액션을 Riverpod NotifierProvider 기반 캐시 레이어로 옮기고, Optimistic Update + 실패 롤백 + SnackBar 안내를 일관 적용한다.

**Architecture:** 3계층(Widget ↔ Notifier ↔ Repository ↔ Api). 각 도메인별로 Notifier가 캐시를 들고 있고 Optimistic 적용 후 Repository를 호출하며 실패 시 prev 값으로 롤백한다. SnackBar는 기존 `navigatorKey.currentContext`를 통해 띄운다.

**Tech Stack:** Flutter, flutter_riverpod ^2.6.1 (이미 설치), 기존 ItemApi/MemberApi, 기존 CommonSnackBar.

**Spec:** `docs/superpowers/specs/2026-05-08-optimistic-update-cache-layer-design.md`

**Issue:** [#835](https://github.com/TEAM-ROMROM/RomRom-FE/issues/835)

**Worktree:** `D:/0-suh/project/RomRom-FE-Worktree/20260508_#835_기능개선_좋아요_버튼_즉시_반영`

---

## File Structure

### 신규 생성
- `lib/states/item_like_state.dart` — `ItemLikeState` 불변 클래스
- `lib/repositories/item_repository.dart` — `ItemRepository` (ItemApi 래핑)
- `lib/repositories/member_block_repository.dart` — `MemberBlockRepository` (MemberApi 래핑)
- `lib/repositories/notification_setting_repository.dart` — `NotificationSettingRepository` (MemberApi 래핑)
- `lib/providers/item_like_provider.dart` — `itemRepositoryProvider` + `itemLikeProvider`
- `lib/providers/member_block_provider.dart` — `memberBlockRepositoryProvider` + `memberBlockProvider`
- `lib/providers/notification_setting_provider.dart` — `notificationSettingRepositoryProvider` + `notificationSettingProvider`
- `test/providers/item_like_provider_test.dart`
- `test/providers/member_block_provider_test.dart`
- `test/providers/notification_setting_provider_test.dart`

### 변경
- `lib/widgets/home_feed_item_widget.dart` — Stateful → ConsumerStateful, `_isLiked`/`_likeCount`/`_isLiking` 제거, 캐시 구독
- `lib/screens/item_detail_description_screen.dart` — `isLikedVN`/`likeCountVN`/`_likeInFlight` 제거, 캐시 구독, `Navigator.pop({...isLiked})` 제거
- `lib/screens/my_page/my_like_list_screen.dart` — pop result 분기 제거, `ref.listen`으로 좋아요 취소 감지
- `lib/screens/my_page/block_management_screen.dart` — `_unblockedMemberIds` 제거, 캐시 구독
- `lib/screens/notification_settings_screen.dart` — `_isMarketingEnabled` 등 5개 bool / `_pendingRequests` 제거, 캐시 구독

---

## PR 분할

| PR | Task 범위 |
|----|-----------|
| 1 | Task 1~7 (인프라 + 좋아요) |
| 2 | Task 8~10 (차단) |
| 3 | Task 11~13 (알림) |
| 4 | Task 14 (좋아요 pop result 동기화 정리, optional) |

---

## PR 1: 인프라 + 좋아요 마이그레이션

### Task 1: ItemLikeState 모델 작성

**Files:**
- Create: `lib/states/item_like_state.dart`
- Test: `test/states/item_like_state_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

```dart
// test/states/item_like_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/states/item_like_state.dart';

void main() {
  group('ItemLikeState', () {
    test('copyWith는 지정한 필드만 변경한다', () {
      const s = ItemLikeState(isLiked: false, likeCount: 3);
      final next = s.copyWith(isLiked: true);
      expect(next.isLiked, isTrue);
      expect(next.likeCount, 3);
    });

    test('동일 값이면 == true', () {
      const a = ItemLikeState(isLiked: true, likeCount: 5);
      const b = ItemLikeState(isLiked: true, likeCount: 5);
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `flutter test test/states/item_like_state_test.dart`
Expected: FAIL — `ItemLikeState` 미정의

- [ ] **Step 3: 최소 구현**

```dart
// lib/states/item_like_state.dart
import 'package:flutter/foundation.dart';

@immutable
class ItemLikeState {
  final bool isLiked;
  final int likeCount;

  const ItemLikeState({required this.isLiked, required this.likeCount});

  ItemLikeState copyWith({bool? isLiked, int? likeCount}) =>
      ItemLikeState(
        isLiked: isLiked ?? this.isLiked,
        likeCount: likeCount ?? this.likeCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemLikeState &&
          runtimeType == other.runtimeType &&
          isLiked == other.isLiked &&
          likeCount == other.likeCount;

  @override
  int get hashCode => Object.hash(isLiked, likeCount);

  @override
  String toString() => 'ItemLikeState(isLiked: $isLiked, likeCount: $likeCount)';
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/states/item_like_state_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋 (사용자 승인 후)**

> CLAUDE.md 규칙: Claude는 사용자 명시적 허락 없이 git commit 실행 금지. 사용자에게 diff 보여주고 "커밋해줘" 요청 시에만 진행.

커밋 메시지 템플릿:
```
좋아요 버튼 즉시 반영 : feat : ItemLikeState 모델 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 2: ItemRepository 작성

**Files:**
- Create: `lib/repositories/item_repository.dart`

- [ ] **Step 1: 코드 작성**

```dart
// lib/repositories/item_repository.dart
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

class ItemRepository {
  final ItemApi _api;

  ItemRepository(this._api);

  Future<ItemResponse> postLike(String itemId) =>
      _api.postLike(ItemRequest(itemId: itemId));
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `dart format --line-length=120 lib/repositories/item_repository.dart`
포매팅 후 lib 분석은 사용자 환경에서 진행 (내부망 환경에서 `flutter analyze`는 별도 실행).

- [ ] **Step 3: 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : ItemRepository 추가 (ItemApi 래핑) https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 3: itemLikeProvider 작성 + 단위 테스트

**Files:**
- Create: `lib/providers/item_like_provider.dart`
- Create: `test/providers/item_like_provider_test.dart`

- [ ] **Step 1: 실패 테스트 작성 (FakeItemRepository 포함)**

```dart
// test/providers/item_like_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/states/item_like_state.dart';

class FakeItemRepository implements ItemRepository {
  bool shouldThrow = false;
  bool? returnLiked;
  int? returnCount;
  int callCount = 0;

  @override
  Future<ItemResponse> postLike(String itemId) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
    return ItemResponse(
      isLiked: returnLiked,
      item: Item(itemId: itemId, likeCount: returnCount),
    );
  }
}

void main() {
  group('itemLikeProvider', () {
    late FakeItemRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeItemRepository();
      container = ProviderContainer(overrides: [
        itemRepositoryProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('seed 후 toggle은 즉시 isLiked를 반전시킨다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.returnLiked = true;
      fake.returnCount = 1;
      final future = notifier.toggle('A');

      // optimistic 적용 확인 (await 전)
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
      expect(container.read(itemLikeProvider)['A']?.likeCount, 1);

      await future;
      // 서버 응답으로 보정
      expect(container.read(itemLikeProvider)['A'],
          const ItemLikeState(isLiked: true, likeCount: 1));
    });

    test('API 실패 시 prev로 롤백한다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.shouldThrow = true;
      await notifier.toggle('A');

      expect(container.read(itemLikeProvider)['A'],
          const ItemLikeState(isLiked: false, likeCount: 0));
    });

    test('in-flight 중 toggle 재호출은 무시된다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.returnLiked = true;
      fake.returnCount = 1;
      final f1 = notifier.toggle('A');
      final f2 = notifier.toggle('A');
      await Future.wait([f1, f2]);

      expect(fake.callCount, 1);
    });

    test('이미 시드된 항목에 force=false로 재시드 시 무시', () {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: true, likeCount: 5);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
    });

    test('force=true 재시드는 덮어쓴다', () {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: true, likeCount: 5);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0, force: true);
      expect(container.read(itemLikeProvider)['A']?.isLiked, isFalse);
    });
  });
}
```

> 참고: `FakeItemRepository`는 `_api` 필드를 노출 안 해도 되도록, 다음 Step에서 `ItemRepository`에 `final ItemApi _api;`를 그대로 두되 Fake에서 throw로 처리한다(`@override` 표시는 Fake에서만 사용). 만약 Dart가 private field implements를 거부하면 `ItemRepository`를 abstract class 또는 interface로 분리. 단, 단순히 Fake에서 `_api` getter는 미사용이므로 컴파일러는 통과한다.

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `flutter test test/providers/item_like_provider_test.dart`
Expected: FAIL — `itemLikeProvider`/`itemRepositoryProvider` 미정의

- [ ] **Step 3: Provider + Notifier 구현**

```dart
// lib/providers/item_like_provider.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/states/item_like_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(ItemApi()),
);

final itemLikeProvider =
    NotifierProvider<ItemLikeNotifier, Map<String, ItemLikeState>>(
  ItemLikeNotifier.new,
);

class ItemLikeNotifier extends Notifier<Map<String, ItemLikeState>> {
  final Set<String> _inFlight = <String>{};

  @override
  Map<String, ItemLikeState> build() => const {};

  /// 캐시 시드. 이미 키가 있으면 [force]가 true가 아닐 때 덮어쓰지 않는다.
  void seed({
    required String itemId,
    required bool isLiked,
    required int likeCount,
    bool force = false,
  }) {
    if (!force && state.containsKey(itemId)) return;
    state = {
      ...state,
      itemId: ItemLikeState(isLiked: isLiked, likeCount: likeCount),
    };
  }

  /// Optimistic 토글. 시드 안 된 경우 silently return.
  Future<void> toggle(String itemId) async {
    if (_inFlight.contains(itemId)) return;
    final prev = state[itemId];
    if (prev == null) return;

    _inFlight.add(itemId);

    final optimistic = prev.copyWith(
      isLiked: !prev.isLiked,
      likeCount:
          prev.isLiked ? max(prev.likeCount - 1, 0) : prev.likeCount + 1,
    );
    state = {...state, itemId: optimistic};

    try {
      final repo = ref.read(itemRepositoryProvider);
      final res = await repo.postLike(itemId);
      state = {
        ...state,
        itemId: ItemLikeState(
          isLiked: res.isLiked == true,
          likeCount: res.item?.likeCount ?? optimistic.likeCount,
        ),
      };
    } catch (e) {
      debugPrint('itemLikeProvider.toggle 실패: $e');
      state = {...state, itemId: prev};
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(
          context: ctx,
          message: '좋아요 처리에 실패했어요',
          type: SnackBarType.error,
        );
      }
    } finally {
      _inFlight.remove(itemId);
    }
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/providers/item_like_provider_test.dart`
Expected: PASS (4~5 tests)

- [ ] **Step 5: 포매팅**

Run: `dart format --line-length=120 lib/providers/item_like_provider.dart test/providers/item_like_provider_test.dart`

- [ ] **Step 6: 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : itemLikeProvider 캐시 레이어 추가 + 단위 테스트 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 4: home_feed_item_widget을 ConsumerStateful로 전환

**Files:**
- Modify: `lib/widgets/home_feed_item_widget.dart`

- [ ] **Step 1: import 변경 및 클래스 선언 변경**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
```

`StatefulWidget` → `ConsumerStatefulWidget`, `State<HomeFeedItemWidget>` → `ConsumerState<HomeFeedItemWidget>`로 변경:

```dart
class HomeFeedItemWidget extends ConsumerStatefulWidget {
  // ... 기존 필드 동일
  const HomeFeedItemWidget({super.key, required this.item, required this.showBlur, this.onAiRecommend});

  @override
  ConsumerState<HomeFeedItemWidget> createState() => _HomeFeedItemWidgetState();
}

class _HomeFeedItemWidgetState extends ConsumerState<HomeFeedItemWidget> {
  // 기존 필드에서 _isLiked, _likeCount, _isLiking 삭제
  // 남는 것: _currentImageIndex, pageController, _useAiPrice, _isAiLoading, _isAiButtonActive
}
```

- [ ] **Step 2: initState에서 캐시 시드**

기존 `_isLiked = widget.item.isLiked;` `_likeCount = widget.item.likeCount;` 두 줄 삭제. 그 자리에 시드 호출:

```dart
@override
void initState() {
  super.initState();
  pageController = PageController(initialPage: _currentImageIndex);
  _useAiPrice = widget.item.aiPrice;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final id = widget.item.itemUuid;
    if (id != null && id.isNotEmpty) {
      ref.read(itemLikeProvider.notifier).seed(
        itemId: id,
        isLiked: widget.item.isLiked,
        likeCount: widget.item.likeCount,
      );
    }
  });

  _fetchItemLikeStatus();
}
```

- [ ] **Step 3: _fetchItemLikeStatus 수정**

기존 `setState`로 `_isLiked`/`_likeCount` 갱신하던 부분을 `seed(force: true)`로 변경:

```dart
Future<void> _fetchItemLikeStatus() async {
  try {
    if (widget.item.itemUuid == null || widget.item.itemUuid!.isEmpty) {
      return;
    }

    final itemApi = ItemApi();
    final response = await itemApi.getItemDetail(ItemRequest(itemId: widget.item.itemUuid));

    if (!mounted) return;
    setState(() {
      _useAiPrice = response.item?.isAiPredictedPrice ?? false;
    });
    final id = widget.item.itemUuid!;
    ref.read(itemLikeProvider.notifier).seed(
      itemId: id,
      isLiked: response.isLiked == true,
      likeCount: response.item?.likeCount ?? widget.item.likeCount,
      force: true,
    );
  } catch (e) {
    debugPrint('좋아요 상태 조회 실패: $e');
  }
}
```

- [ ] **Step 4: 좋아요 onTap 핸들러 변경**

기존 286~306 라인의 onTap async 핸들러 전체를 다음으로 교체:

```dart
onTap: () async {
  final id = widget.item.itemUuid;
  if (id == null || id.isEmpty) return;

  // 본인 게시글 차단
  final isCurrentMember = await MemberManager.isCurrentMember(widget.item.authorMemberId);
  if (isCurrentMember) {
    if (mounted) {
      CommonSnackBar.show(
        context: context,
        message: '본인 게시글에는 좋아요를 누를 수 없습니다.',
        type: SnackBarType.error,
      );
    }
    return;
  }

  await ref.read(itemLikeProvider.notifier).toggle(id);
},
```

- [ ] **Step 5: build 메서드에서 좋아요 표시 부분을 watch로 변경**

기존 `_isLiked`를 사용하던 부분 (예: 317~318라인 svg asset 결정):

```dart
final id = widget.item.itemUuid;
final liked = ref.watch(
  itemLikeProvider.select((s) =>
      (id != null && id.isNotEmpty)
          ? (s[id]?.isLiked ?? widget.item.isLiked)
          : widget.item.isLiked),
);
final likeCount = ref.watch(
  itemLikeProvider.select((s) =>
      (id != null && id.isNotEmpty)
          ? (s[id]?.likeCount ?? widget.item.likeCount)
          : widget.item.likeCount),
);
```

`_isLiked` → `liked`, `_likeCount` → `likeCount`로 모든 참조 치환.

- [ ] **Step 6: 포매팅**

Run: `dart format --line-length=120 lib/widgets/home_feed_item_widget.dart`

- [ ] **Step 7: 사용자 환경에서 빌드 확인 후 커밋 (사용자 승인 후)**

내부망 환경에서 `flutter analyze` 사용자 환경에서 별도 실행 필요. 사용자가 분석 통과 확인 후 커밋:

```
좋아요 버튼 즉시 반영 : feat : home_feed_item_widget 캐시 구독 전환 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 5: item_detail_description_screen에 캐시 구독 적용

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: import 추가 및 ConsumerStatefulWidget으로 전환**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
```

`StatefulWidget` → `ConsumerStatefulWidget`, `State<ItemDetailDescriptionScreen>` → `ConsumerState<ItemDetailDescriptionScreen>`.

- [ ] **Step 2: ValueNotifier 제거**

기존 `late final ValueNotifier<bool> isLikedVN;` `late final ValueNotifier<int> likeCountVN;` `bool _likeInFlight = false;` 모두 삭제.

기존 initState에서 `isLikedVN = ValueNotifier<bool>(false);` `likeCountVN = ValueNotifier<int>(0);` 같은 초기화 라인 삭제.

기존 dispose에서 `isLikedVN.dispose();` `likeCountVN.dispose();` 삭제.

- [ ] **Step 3: 상세 데이터 로드 후 캐시 시드**

기존 `isLikedVN.value = (response.isLiked == true);` 같은 부분을 다음으로 교체:

```dart
final id = item?.itemId;
if (id != null && id.isNotEmpty) {
  ref.read(itemLikeProvider.notifier).seed(
    itemId: id,
    isLiked: response.isLiked == true,
    likeCount: response.item?.likeCount ?? 0,
    force: true,
  );
}
```

- [ ] **Step 4: 좋아요 핸들러 교체 (1029~1054라인 부근)**

기존 `_handleLikeTap` 또는 좋아요 토글 함수 전체를 다음으로 교체:

```dart
Future<void> _handleLikeTap() async {
  final id = item?.itemId;
  if (id == null || id.isEmpty) return;

  final isCurrentMember = await MemberManager.isCurrentMember(item?.member?.memberId);
  if (isCurrentMember) {
    if (mounted) {
      CommonSnackBar.show(
        context: context,
        message: '본인 게시글에는 좋아요를 누를 수 없습니다.',
        type: SnackBarType.error,
      );
    }
    return;
  }

  await ref.read(itemLikeProvider.notifier).toggle(id);
}
```

- [ ] **Step 5: build 메서드의 ValueListenableBuilder를 ref.watch로 교체**

기존 `ValueListenableBuilder<bool>(valueListenable: isLikedVN, ...)` → 다음으로 교체:

```dart
Builder(
  builder: (context) {
    final id = item?.itemId;
    final liked = ref.watch(itemLikeProvider.select(
      (s) => id == null ? false : (s[id]?.isLiked ?? false),
    ));
    return /* 기존 child(좋아요 아이콘 등) */;
  },
)
```

`likeCountVN`도 동일하게 `ref.watch(itemLikeProvider.select((s) => s[id]?.likeCount ?? 0))`로 교체.

- [ ] **Step 6: Navigator.pop 결과 인자 정리**

기존 라인:
```dart
Navigator.of(context).pop(<String, dynamic>{'isLiked': isLikedVN.value, 'likeCount': likeCountVN.value});
```
→ 다음으로 변경:
```dart
final id = item?.itemId;
final cached = id == null ? null : ref.read(itemLikeProvider)[id];
Navigator.of(context).pop(<String, dynamic>{
  'isLiked': cached?.isLiked ?? false,
  'likeCount': cached?.likeCount ?? 0,
});
```

(Task 14에서 pop result 자체를 제거할 예정이지만, PR 1 단위에서는 호출자가 아직 의존하므로 남겨둔다)

- [ ] **Step 7: 포매팅**

Run: `dart format --line-length=120 lib/screens/item_detail_description_screen.dart`

- [ ] **Step 8: 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : item_detail 캐시 구독 전환, ValueNotifier 제거 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 6: my_like_list_screen에 캐시 구독 + listen으로 좋아요 취소 감지

**Files:**
- Modify: `lib/screens/my_page/my_like_list_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget으로 전환**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
```

클래스 선언 변경 (HomeFeedItemWidget Task 4와 동일 패턴).

- [ ] **Step 2: 목록 로드 후 캐시 시드**

`_convertToLikeItems` 또는 페이지 로드 후 setState로 `_items`를 채우는 부분 직후, 각 아이템에 대해 시드:

```dart
for (final item in serverItems) {
  final id = item.itemId;
  if (id != null && id.isNotEmpty) {
    ref.read(itemLikeProvider.notifier).seed(
      itemId: id,
      isLiked: true,
      likeCount: item.likeCount ?? 0,
      force: true,
    );
  }
}
```

- [ ] **Step 3: 기존 좋아요 취소 onTap 핸들러 캐시 토글로 변경**

기존 330라인 부근의 `await ItemApi().postLike(...)` 호출 부분을 다음으로 교체:

```dart
onPressed: () async {
  await ref.read(itemLikeProvider.notifier).toggle(itemId);
},
```

`item.isLiked = !item.isLiked` 같은 로컬 상태 변경 코드 제거. 표시는 캐시 watch로:

```dart
final liked = ref.watch(itemLikeProvider.select((s) => s[itemId]?.isLiked ?? true));
final iconAsset = liked ? AppIcons.itemRegisterHeart : AppIcons.profilelikecount;
```

- [ ] **Step 4: ref.listen으로 좋아요 취소 감지 후 목록에서 제거**

build 메서드 시작 부분에 추가:

```dart
@override
Widget build(BuildContext context) {
  ref.listen<Map<String, ItemLikeState>>(itemLikeProvider, (prev, next) {
    if (!mounted) return;
    final removed = <String>[];
    for (final it in _items) {
      final liked = next[it.itemId]?.isLiked;
      if (liked == false) removed.add(it.itemId);
    }
    if (removed.isNotEmpty) {
      setState(() {
        _items.removeWhere((it) => removed.contains(it.itemId));
      });
    }
  });
  // ... 기존 build
}
```

`ItemLikeState` import 추가:
```dart
import 'package:romrom_fe/states/item_like_state.dart';
```

- [ ] **Step 5: 기존 pop result 분기 유지 (PR 1 한정)**

기존:
```dart
final result = await Navigator.push<dynamic>(...);
if (result is Map<String, dynamic> && mounted) {
  final isLiked = result['isLiked'] as bool? ?? true;
  if (!isLiked) {
    setState(() => _items.removeWhere((it) => it.itemId == itemId));
  }
}
```
은 PR 1에서는 그대로 남긴다. ref.listen이 같은 동작을 하므로 결과적으로 중복 제거(`removeWhere`는 멱등) 발생하지만 동작 영향 없음. PR 4(Task 14)에서 pop result 분기 제거.

- [ ] **Step 6: 포매팅**

Run: `dart format --line-length=120 lib/screens/my_page/my_like_list_screen.dart`

- [ ] **Step 7: 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : my_like_list 캐시 구독 + listen 자동 제거 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 7: PR 1 통합 검증

**Files:**
- (없음, 검증만)

- [ ] **Step 1: 사용자 환경에서 lint 실행**

사용자에게 다음 실행 요청:
```
flutter analyze
flutter test test/states/ test/providers/
```

Expected:
- analyze: no issues
- test: 모두 PASS

- [ ] **Step 2: 사용자 환경에서 디바이스 테스트 시나리오**

- 홈 피드에서 좋아요 클릭 → 즉시 색상 변경 확인 (네트워크 지연 시뮬레이션 권장)
- 좋아요 후 상세 진입 → 상세에서 취소 → 뒤로가기 → 홈에서도 즉시 반영 확인
- 마이페이지 좋아요 목록에서 좋아요 취소 → 즉시 항목 사라짐 확인
- 네트워크 끊긴 상태에서 좋아요 → 롤백 + SnackBar "좋아요 처리에 실패했어요" 확인

- [ ] **Step 3: PR 1 머지 후 PR 2 진행**

---

## PR 2: 차단 마이그레이션

### Task 8: MemberBlockRepository + Provider + 테스트

**Files:**
- Create: `lib/repositories/member_block_repository.dart`
- Create: `lib/providers/member_block_provider.dart`
- Create: `test/providers/member_block_provider_test.dart`

- [ ] **Step 1: Repository 작성**

```dart
// lib/repositories/member_block_repository.dart
import 'package:romrom_fe/services/apis/member_api.dart';

class MemberBlockRepository {
  final MemberApi _api;

  MemberBlockRepository(this._api);

  Future<bool> block(String memberId) => _api.blockMember(memberId);
  Future<bool> unblock(String memberId) => _api.unblockMember(memberId);
}
```

- [ ] **Step 2: 실패 테스트 작성**

```dart
// test/providers/member_block_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class FakeMemberBlockRepository implements MemberBlockRepository {
  bool throwOnBlock = false;
  bool throwOnUnblock = false;
  bool blockReturn = true;
  bool unblockReturn = true;
  int blockCalls = 0;
  int unblockCalls = 0;

  @override
  Future<bool> block(String memberId) async {
    blockCalls++;
    if (throwOnBlock) throw Exception('boom');
    return blockReturn;
  }

  @override
  Future<bool> unblock(String memberId) async {
    unblockCalls++;
    if (throwOnUnblock) throw Exception('boom');
    return unblockReturn;
  }
}

void main() {
  group('memberBlockProvider', () {
    late FakeMemberBlockRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeMemberBlockRepository();
      container = ProviderContainer(overrides: [
        memberBlockRepositoryProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('seed 후 setBlocked(false)는 즉시 Set에서 제거한다', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A', 'B'});
      final f = n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).contains('A'), isFalse);
      await f;
      expect(fake.unblockCalls, 1);
    });

    test('차단 해제 실패 시 prev로 롤백', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A'});
      fake.throwOnUnblock = true;
      await n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).contains('A'), isTrue);
    });

    test('서버 응답이 false인 경우도 롤백', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A'});
      fake.unblockReturn = false;
      await n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).contains('A'), isTrue);
    });
  });
}
```

- [ ] **Step 3: 테스트 실행 → 실패 확인**

Run: `flutter test test/providers/member_block_provider_test.dart`
Expected: FAIL — provider 미정의

- [ ] **Step 4: Provider + Notifier 구현**

```dart
// lib/providers/member_block_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final memberBlockRepositoryProvider = Provider<MemberBlockRepository>(
  (ref) => MemberBlockRepository(MemberApi()),
);

final memberBlockProvider =
    NotifierProvider<MemberBlockNotifier, Set<String>>(MemberBlockNotifier.new);

class MemberBlockNotifier extends Notifier<Set<String>> {
  final Set<String> _inFlight = <String>{};

  @override
  Set<String> build() => <String>{};

  void seed(Set<String> ids, {bool force = false}) {
    if (!force && state.isNotEmpty) return;
    state = {...ids};
  }

  Future<void> setBlocked(String memberId, bool block) async {
    if (_inFlight.contains(memberId)) return;
    _inFlight.add(memberId);

    final wasBlocked = state.contains(memberId);
    state = block
        ? {...state, memberId}
        : (state.toSet()..remove(memberId));

    try {
      final repo = ref.read(memberBlockRepositoryProvider);
      final ok = block ? await repo.block(memberId) : await repo.unblock(memberId);
      if (!ok) throw Exception('서버 응답이 false');
    } catch (e) {
      debugPrint('memberBlockProvider.setBlocked 실패: $e');
      state = wasBlocked
          ? {...state, memberId}
          : (state.toSet()..remove(memberId));
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(
          context: ctx,
          message: block ? '차단에 실패했어요' : '차단 해제에 실패했어요',
          type: SnackBarType.error,
        );
      }
    } finally {
      _inFlight.remove(memberId);
    }
  }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `flutter test test/providers/member_block_provider_test.dart`
Expected: PASS

- [ ] **Step 6: 포매팅 + 커밋 (사용자 승인 후)**

Run: `dart format --line-length=120 lib/repositories/member_block_repository.dart lib/providers/member_block_provider.dart test/providers/member_block_provider_test.dart`

```
좋아요 버튼 즉시 반영 : feat : memberBlockProvider 캐시 레이어 추가 + 단위 테스트 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 9: block_management_screen 캐시 구독 전환

**Files:**
- Modify: `lib/screens/my_page/block_management_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget으로 전환 + import**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
```

`StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`.

- [ ] **Step 2: `_unblockedMemberIds` 제거**

기존:
```dart
final Set<String> _unblockedMemberIds = {};
```
삭제.

- [ ] **Step 3: `_loadBlockedMembers`에서 캐시 시드**

기존 setState 후 추가:
```dart
final ids = (response.members ?? [])
    .map((m) => m.memberId)
    .whereType<String>()
    .toSet();
ref.read(memberBlockProvider.notifier).seed(ids, force: true);
```

- [ ] **Step 4: `_handleUnblock`/`_handleBlock` 캐시 호출로 교체**

```dart
Future<void> _handleUnblock(String memberId) =>
    ref.read(memberBlockProvider.notifier).setBlocked(memberId, false);

Future<void> _handleBlock(String memberId) =>
    ref.read(memberBlockProvider.notifier).setBlocked(memberId, true);
```

- [ ] **Step 5: 버튼 라벨/색상 토글에 사용하는 `_unblockedMemberIds.contains(...)` 분기를 캐시 watch로 교체**

기존:
```dart
final isUnblocked = _unblockedMemberIds.contains(memberId);
```
→
```dart
final isCurrentlyBlocked = ref.watch(
  memberBlockProvider.select((s) => s.contains(memberId)),
);
final isUnblocked = !isCurrentlyBlocked;
```

- [ ] **Step 6: 포매팅 + 커밋 (사용자 승인 후)**

Run: `dart format --line-length=120 lib/screens/my_page/block_management_screen.dart`

```
좋아요 버튼 즉시 반영 : feat : block_management 캐시 구독 전환 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 10: PR 2 통합 검증

- [ ] **Step 1: lint + test 실행 (사용자 환경)**

```
flutter analyze
flutter test test/providers/member_block_provider_test.dart
```

- [ ] **Step 2: 디바이스 테스트 시나리오**

- 차단 관리 화면 진입 → 차단 해제 클릭 → 즉시 라벨 변경
- 네트워크 끊긴 상태에서 차단 해제 → 라벨 원복 + SnackBar "차단 해제에 실패했어요"
- 차단 해제 후 다시 차단 → 즉시 라벨 변경

---

## PR 3: 알림 설정 마이그레이션

### Task 11: NotificationSettingRepository + Provider + 테스트

**Files:**
- Create: `lib/repositories/notification_setting_repository.dart`
- Create: `lib/providers/notification_setting_provider.dart`
- Create: `test/providers/notification_setting_provider_test.dart`

- [ ] **Step 1: Repository 작성**

```dart
// lib/repositories/notification_setting_repository.dart
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class NotificationSettingRepository {
  final MemberApi _api;

  NotificationSettingRepository(this._api);

  Future<void> update(NotificationSettingType type, bool value) async {
    await _api.updateNotificationSetting(
      isMarketingInfoAgreed: type == NotificationSettingType.marketing ? value : null,
      isActivityNotificationAgreed: type == NotificationSettingType.activity ? value : null,
      isChatNotificationAgreed: type == NotificationSettingType.chat ? value : null,
      isContentNotificationAgreed: type == NotificationSettingType.content ? value : null,
      isTradeNotificationAgreed: type == NotificationSettingType.transaction ? value : null,
    );
  }
}
```

- [ ] **Step 2: 실패 테스트 작성**

```dart
// test/providers/notification_setting_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class FakeNotificationSettingRepository implements NotificationSettingRepository {
  bool shouldThrow = false;
  int callCount = 0;

  @override
  Future<void> update(NotificationSettingType type, bool value) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
  }
}

void main() {
  group('notificationSettingProvider', () {
    late FakeNotificationSettingRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeNotificationSettingRepository();
      container = ProviderContainer(overrides: [
        notificationSettingRepositoryProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('seed 후 setEnabled은 즉시 변경한다', () async {
      final n = container.read(notificationSettingProvider.notifier);
      n.seed({NotificationSettingType.marketing: false});

      final f = n.setEnabled(NotificationSettingType.marketing, true);
      expect(
        container.read(notificationSettingProvider)[NotificationSettingType.marketing],
        isTrue,
      );
      await f;
      expect(fake.callCount, 1);
    });

    test('실패 시 prev로 롤백', () async {
      final n = container.read(notificationSettingProvider.notifier);
      n.seed({NotificationSettingType.activity: false});
      fake.shouldThrow = true;
      await n.setEnabled(NotificationSettingType.activity, true);
      expect(
        container.read(notificationSettingProvider)[NotificationSettingType.activity],
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 3: 테스트 실행 → 실패 확인**

Run: `flutter test test/providers/notification_setting_provider_test.dart`
Expected: FAIL — provider 미정의

- [ ] **Step 4: Provider + Notifier 구현**

```dart
// lib/providers/notification_setting_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final notificationSettingRepositoryProvider =
    Provider<NotificationSettingRepository>(
  (ref) => NotificationSettingRepository(MemberApi()),
);

final notificationSettingProvider = NotifierProvider<
    NotificationSettingNotifier, Map<NotificationSettingType, bool>>(
  NotificationSettingNotifier.new,
);

class NotificationSettingNotifier
    extends Notifier<Map<NotificationSettingType, bool>> {
  final Set<NotificationSettingType> _inFlight = {};

  @override
  Map<NotificationSettingType, bool> build() => const {};

  void seed(Map<NotificationSettingType, bool> values, {bool force = false}) {
    if (!force && state.isNotEmpty) return;
    state = {...values};
  }

  Future<void> setEnabled(NotificationSettingType type, bool value) async {
    if (_inFlight.contains(type)) return;
    _inFlight.add(type);

    final prev = state[type] ?? !value;
    state = {...state, type: value};

    try {
      await ref.read(notificationSettingRepositoryProvider).update(type, value);
    } catch (e) {
      debugPrint('notificationSettingProvider.setEnabled 실패: $e');
      state = {...state, type: prev};
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(
          context: ctx,
          message: '알림 설정 변경에 실패했어요',
          type: SnackBarType.error,
        );
      }
    } finally {
      _inFlight.remove(type);
    }
  }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `flutter test test/providers/notification_setting_provider_test.dart`
Expected: PASS

- [ ] **Step 6: 포매팅 + 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : notificationSettingProvider 캐시 레이어 추가 + 단위 테스트 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 12: notification_settings_screen 캐시 구독 전환

**Files:**
- Modify: `lib/screens/notification_settings_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget으로 전환 + import**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
```

- [ ] **Step 2: 5개 bool 필드 + `_pendingRequests` 제거**

기존:
```dart
bool _isMarketingEnabled = false;
bool _isActivityEnabled = false;
bool _isChatEnabled = false;
bool _isContentEnabled = false;
bool _isTransactionEnabled = false;
final Set<NotificationSettingType> _pendingRequests = {};
```
모두 삭제.

`_setSettingValue` / `_getSettingValue` 두 헬퍼 메서드 모두 제거 (캐시 watch로 대체).

- [ ] **Step 3: `_loadNotificationSettings`에서 캐시 시드**

```dart
Future<void> _loadNotificationSettings() async {
  try {
    final response = await _memberApi.getMemberInfo();
    final Member? member = response.member;
    if (member != null && mounted) {
      ref.read(notificationSettingProvider.notifier).seed({
        NotificationSettingType.marketing: member.isMarketingInfoAgreed ?? false,
        NotificationSettingType.activity: member.isActivityNotificationAgreed ?? false,
        NotificationSettingType.chat: member.isChatNotificationAgreed ?? false,
        NotificationSettingType.content: member.isContentNotificationAgreed ?? false,
        NotificationSettingType.transaction: member.isTradeNotificationAgreed ?? false,
      }, force: true);
      setState(() => _isLoading = false);
    }
  } catch (e) {
    debugPrint('알림 설정 로딩 실패: $e');
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] **Step 4: `_onSettingChanged`를 캐시 호출로 교체**

권한 분기는 유지하되 setState/`_pendingRequests` 제거:

```dart
Future<void> _onSettingChanged(NotificationSettingType type, bool newValue) async {
  if (newValue) {
    final granted = await NotificationPermissionService().isPermissionGranted();
    if (!granted) {
      if (!mounted) return;
      await CommonModal.confirm(
        context: context,
        message: '시스템 알림 허용이 필요합니다.',
        cancelText: '취소',
        confirmText: '알림 켜기',
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          _pendingEnableType = type;
          Navigator.pop(context);
          NotificationPermissionService().openSettings();
        },
      );
      return;
    }
  }
  await ref.read(notificationSettingProvider.notifier).setEnabled(type, newValue);
}
```

`_handleReturnFromSystemSettings`도 동일 패턴으로 교체:

```dart
Future<void> _handleReturnFromSystemSettings() async {
  final type = _pendingEnableType!;
  _pendingEnableType = null;
  final granted = await NotificationPermissionService().isPermissionGranted();
  if (granted) {
    await ref.read(notificationSettingProvider.notifier).setEnabled(type, true);
  }
}
```

- [ ] **Step 5: build에서 토글 값 watch로 변경**

`_buildSettingRow`:
```dart
Widget _buildSettingRow(NotificationSettingType type) {
  final value = ref.watch(
    notificationSettingProvider.select((s) => s[type] ?? false),
  );
  // ... 기존 UI, value 사용
}
```

- [ ] **Step 6: 기존 `_updateNotificationSetting` 메서드 제거**

캐시 호출 경로로 일원화되었으므로 삭제.

- [ ] **Step 7: 포매팅 + 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : feat : notification_settings 캐시 구독 전환 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

### Task 13: PR 3 통합 검증

- [ ] **Step 1: lint + test (사용자 환경)**

```
flutter analyze
flutter test test/providers/notification_setting_provider_test.dart
```

- [ ] **Step 2: 디바이스 테스트 시나리오**

- 알림 설정 화면 진입 → 마케팅 토글 클릭 → 즉시 토글 변경
- 네트워크 끊긴 상태에서 토글 → 토글 원복 + SnackBar "알림 설정 변경에 실패했어요"
- 시스템 권한 OFF 상태에서 ON 시도 → 모달 표시 → 시스템 설정 이동 → 권한 허용 후 복귀 → 토글 ON 정상 처리 확인

---

## PR 4: 좋아요 pop result 동기화 정리 (optional)

### Task 14: 좋아요 pop result 분기 제거

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`
- Modify: `lib/screens/my_page/my_like_list_screen.dart`
- Modify: `lib/widgets/home_feed_item_widget.dart` (호출자가 result를 받는 경우)

- [ ] **Step 1: item_detail_description_screen에서 pop 인자 제거**

기존:
```dart
Navigator.of(context).pop(<String, dynamic>{
  'isLiked': cached?.isLiked ?? false,
  'likeCount': cached?.likeCount ?? 0,
});
```
→
```dart
Navigator.of(context).pop();
```

- [ ] **Step 2: my_like_list_screen의 result 분기 제거**

기존:
```dart
final result = await Navigator.push<dynamic>(...);
if (result is Map<String, dynamic> && mounted) {
  final isLiked = result['isLiked'] as bool? ?? true;
  if (!isLiked) {
    setState(() => _items.removeWhere((it) => it.itemId == itemId));
  }
}
```
→
```dart
await Navigator.push<void>(...);
// 좋아요 취소 감지는 ref.listen이 처리
```

- [ ] **Step 3: home_feed_item_widget에서 push result 처리 제거 (해당하는 경우)**

`home_feed_item_widget.dart` 187라인 부근:
```dart
final result = await Navigator.push<dynamic>(...);
if (result is Map<String, dynamic>) {
  setState(() {
    _isLiked = result['isLiked'] as bool? ?? _isLiked;
  });
}
```
→ Task 4에서 이미 `_isLiked`를 캐시 구독으로 바꿨으므로 이 result 처리는 불필요. 단순 push로 변경:
```dart
await Navigator.push<void>(...);
```

- [ ] **Step 4: 포매팅**

Run: `dart format --line-length=120 lib/screens/item_detail_description_screen.dart lib/screens/my_page/my_like_list_screen.dart lib/widgets/home_feed_item_widget.dart`

- [ ] **Step 5: 디바이스 회귀 테스트**

- 홈 → 상세 → 좋아요 취소 → 뒤로가기 → 홈 즉시 반영
- 마이페이지 → 상세 → 좋아요 취소 → 뒤로가기 → 목록에서 즉시 사라짐

- [ ] **Step 6: 커밋 (사용자 승인 후)**

```
좋아요 버튼 즉시 반영 : refactor : 좋아요 pop result 동기화 코드 제거 https://github.com/TEAM-ROMROM/RomRom-FE/issues/835
```

---

## 최종 확인 (전체 PR 머지 후)

- [ ] `lib/widgets/home_feed_item_widget.dart`에서 `_isLiked`/`_likeCount`/`_isLiking` 식별자 검색 결과 없음
- [ ] `lib/screens/item_detail_description_screen.dart`에서 `isLikedVN`/`likeCountVN`/`_likeInFlight` 식별자 검색 결과 없음
- [ ] `lib/screens/my_page/my_like_list_screen.dart`에서 `result['isLiked']` 검색 결과 없음
- [ ] `lib/screens/notification_settings_screen.dart`에서 `_isMarketingEnabled` 외 4개 bool 필드 검색 결과 없음
- [ ] `lib/screens/my_page/block_management_screen.dart`에서 `_unblockedMemberIds` 검색 결과 없음
- [ ] `flutter test` 모든 신규 테스트 PASS
- [ ] `flutter analyze` 통과

---

## 의존성 / 호환성 메모

- 새 패키지 추가 없음. `flutter_riverpod ^2.6.1` 기존 설치본 사용.
- `MaterialApp.navigatorKey`는 `lib/utils/common_utils.dart`의 `navigatorKey`로 이미 연결됨. 추가 변경 없음.
- 기존 ItemApi/MemberApi 시그니처 변경 없음.
- `HomeFeedItem.isLiked`/`likeCount` 필드는 시드 초기값으로 유지. 이후 별도 이슈에서 deprecated 처리 가능.

## 절대 규칙

- **Claude는 사용자 명시적 허락 없이 git commit을 실행하지 않는다.** 각 Task의 Step "커밋"은 사용자가 diff 확인 후 "커밋해줘" 요청 시에만 진행.
- 코드 수정 후 `dart format --line-length=120 .` 실행.
- `flutter analyze` / `flutter test`는 사용자 환경(외부망 환경)에서 별도 실행.
