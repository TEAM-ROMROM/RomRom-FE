# 보상형 광고 기반 '내 물건 우선 노출' Implementation Plan (이슈 #819)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 내 물건 관리 탭에서 보상형 광고를 끝까지 시청하면 해당 물건을 백엔드 우선노출 대상으로 활성화한다.

**Architecture:** AdMob 보상형 광고 생명주기는 `RewardedAdService`가 캡슐화(결과 boolean), 백엔드 활성화는 `PromotionRepository`가 래핑, 둘의 오케스트레이션과 우선노출 상태는 동기 `Notifier`(`promotionProvider`)가 단일 소유한다. 화면은 provider를 구독해 버튼/뱃지를 전환하고, notifier가 반환하는 `PromoteResult` enum으로 토스트를 분기한다.

**Tech Stack:** Flutter, Riverpod(Notifier), google_mobile_ads(RewardedAd), 기존 `ApiClient`/`AppColors`/`CustomTextStyles`/`CommonSnackBar`.

> **백엔드 미확정:** 우선노출 API 엔드포인트·요청 바디는 가정값(`POST /api/item/promote`)이다. BE 확정 시 `PromotionApi`/`PromotionRepository` 내부만 교체하면 상위 레이어 무영향. 가정 지점은 코드에 `// TODO(#819 BE)` 주석으로 표시한다.

> **커밋 규칙(CLAUDE.md):** 각 Task의 커밋 step은 **사용자 명시 허락 시에만** 실행한다. 무단 `git add`/`git commit` 금지. 서브에이전트에게도 커밋 금지를 명시 전달한다.

---

## File Structure

**신규**
- `lib/enums/promote_result.dart` — 우선노출 시도 결과 enum
- `lib/services/rewarded_ad_service.dart` — 보상형 광고 로드/표시/보상 콜백
- `lib/states/promotion_state.dart` — 우선노출 활성 itemId 집합(immutable)
- `lib/services/apis/promotion_api.dart` — 백엔드 우선노출 HTTP 호출
- `lib/repositories/promotion_repository.dart` — PromotionApi 래핑
- `lib/providers/promotion_repository_provider.dart` — repository/service 주입 provider
- `lib/providers/promotion_provider.dart` — 오케스트레이터 Notifier + provider
- `test/providers/promotion_provider_test.dart` — notifier 단위 테스트

**수정**
- `lib/screens/my_page/my_register_item_screen.dart` — item tile에 버튼/뱃지, provider 구독, 토스트 분기

---

### Task 1: PromoteResult enum

**Files:**
- Create: `lib/enums/promote_result.dart`

- [ ] **Step 1: enum 작성**

```dart
/// 우선노출(롬업) 시도 결과.
/// 화면은 이 값으로 토스트를 분기한다. notifier가 UI에 의존하지 않게 하기 위함.
enum PromoteResult {
  success, // 광고 보상 + 백엔드 활성화 성공
  adNotEarned, // 광고 미시청/중도이탈/로드실패 — 보상 미적립
  failed, // 보상은 받았으나 백엔드 활성화 실패
  alreadyInFlight, // 동일 itemId 처리 중 — 중복 무시
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/enums/promote_result.dart`
Expected: No issues found.

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add lib/enums/promote_result.dart
git commit -m "feat: 우선노출 결과 enum PromoteResult 추가"
```

---

### Task 2: PromotionState

**Files:**
- Create: `lib/states/promotion_state.dart`

- [ ] **Step 1: 상태 모델 작성**

`my_items_state.dart`의 `@immutable` + `copyWith`/`==`/`hashCode` 패턴을 따른다.

```dart
import 'package:flutter/foundation.dart';

/// 우선노출(롬업) 활성화된 itemId 집합을 단일 소유하는 상태.
@immutable
class PromotionState {
  final Set<String> promotedItemIds;

  const PromotionState({this.promotedItemIds = const {}});

  bool isPromoted(String itemId) => promotedItemIds.contains(itemId);

  PromotionState copyWith({Set<String>? promotedItemIds}) =>
      PromotionState(promotedItemIds: promotedItemIds ?? this.promotedItemIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionState &&
          runtimeType == other.runtimeType &&
          setEquals(promotedItemIds, other.promotedItemIds);

  @override
  int get hashCode => Object.hashAll(promotedItemIds);

  @override
  String toString() => 'PromotionState(promoted: ${promotedItemIds.length})';
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/states/promotion_state.dart`
Expected: No issues found.

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add lib/states/promotion_state.dart
git commit -m "feat: 우선노출 상태 PromotionState 추가"
```

---

### Task 3: RewardedAdService

**Files:**
- Create: `lib/services/rewarded_ad_service.dart`

- [ ] **Step 1: 서비스 작성**

`AdMobService.rewardedAdUnitId`를 unit ID로 사용한다. 결과는 boolean 하나로 수렴(보상 받음/아님). 로드 실패·표시 실패·중도 이탈 전부 false.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';

/// AdMob 보상형 광고의 로드·표시·보상 콜백을 캡슐화한다.
/// 비즈니스 로직(우선노출)을 전혀 모른다 — 결과는 "보상 받았나" boolean 하나.
class RewardedAdService {
  RewardedAd? _ad;
  bool _isLoading = false;

  /// 광고 미리 로드. 이미 로드됐거나 로딩 중이면 무시.
  Future<void> load() async {
    if (_ad != null || _isLoading) return;
    final unitId = AdMobService.rewardedAdUnitId;
    if (unitId == null) return; // 실제 unit ID는 .env 기반(테스트 빌드만 테스트 ID 반환)
    _isLoading = true;
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAd] 로드 실패: $error');
          _ad = null;
          _isLoading = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// 광고를 표시하고 보상 여부를 반환한다.
  /// true = 보상 적립 / false = 미적립(이탈·실패·미로드).
  Future<bool> showAndAwaitReward() async {
    if (_ad == null) await load();
    final ad = _ad;
    if (ad == null) return false; // 로드 실패

    final completer = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      // 보상 콜백(onUserEarnedReward)은 닫히기 전에 도착 → 닫힘 시점에 결과 확정
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAd] 표시 실패: $error');
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/services/rewarded_ad_service.dart`
Expected: No issues found.

> 단위 테스트는 작성하지 않는다 — `RewardedAd.load`/`show`는 정적 SDK 호출이라 mock 불가. notifier 테스트(Task 7)에서 서비스를 통째로 Fake로 주입해 검증한다.

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add lib/services/rewarded_ad_service.dart
git commit -m "feat: 보상형 광고 생명주기 RewardedAdService 추가"
```

---

### Task 4: PromotionApi + PromotionRepository

**Files:**
- Create: `lib/services/apis/promotion_api.dart`
- Create: `lib/repositories/promotion_repository.dart`

- [ ] **Step 1: PromotionApi 작성**

`ItemApi` 싱글톤 패턴 + `ApiClient.sendHttpRequest` JSON POST 패턴을 따른다. 엔드포인트는 BE 미확정이라 가정값 + TODO 표시.

```dart
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class PromotionApi {
  static final PromotionApi _instance = PromotionApi._internal();
  factory PromotionApi() => _instance;
  PromotionApi._internal();

  /// 우선노출 활성화. 광고 보상 시청 완료 후 호출.
  /// TODO(#819 BE): 엔드포인트/요청 바디/보상 검증 토큰은 백엔드 확정 시 교체.
  Future<void> activatePromotion(String itemId) async {
    final url = '${AppUrls.baseUrl}/api/item/promote';
    await ApiClient.sendHttpRequest(
      url: url,
      method: 'POST',
      body: {'itemId': itemId},
      onSuccess: (_) {},
    );
  }
}
```

- [ ] **Step 2: PromotionRepository 작성**

`ItemRepository` 패턴(생성자 주입, UI 모름)을 따른다.

```dart
import 'package:romrom_fe/services/apis/promotion_api.dart';

/// 우선노출(롬업) 백엔드 API 래핑. UI를 모른다.
class PromotionRepository {
  final PromotionApi _api;

  PromotionRepository(this._api);

  /// 우선노출 활성화 요청.
  Future<void> activate(String itemId) => _api.activatePromotion(itemId);
}
```

- [ ] **Step 3: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/services/apis/promotion_api.dart lib/repositories/promotion_repository.dart`
Expected: No issues found.

- [ ] **Step 4: 커밋 (사용자 허락 시에만)**

```bash
git add lib/services/apis/promotion_api.dart lib/repositories/promotion_repository.dart
git commit -m "feat: 우선노출 PromotionApi/PromotionRepository 추가"
```

---

### Task 5: 주입 Provider

**Files:**
- Create: `lib/providers/promotion_repository_provider.dart`

- [ ] **Step 1: provider 작성**

`item_repository_provider.dart` 패턴(plain `Provider`, 테스트 override 가능)을 따른다. repository와 광고 서비스 둘 다 여기서 주입한다.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/apis/promotion_api.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';

/// 우선노출 repository 주입용 공유 Provider.
final promotionRepositoryProvider =
    Provider<PromotionRepository>((ref) => PromotionRepository(PromotionApi()));

/// 보상형 광고 서비스 주입용 공유 Provider.
final rewardedAdServiceProvider =
    Provider<RewardedAdService>((ref) => RewardedAdService());
```

- [ ] **Step 2: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/providers/promotion_repository_provider.dart`
Expected: No issues found.

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add lib/providers/promotion_repository_provider.dart
git commit -m "feat: 우선노출 repository/광고서비스 주입 provider 추가"
```

---

### Task 6: PromotionNotifier + promotionProvider

**Files:**
- Create: `lib/providers/promotion_provider.dart`

- [ ] **Step 1: notifier 작성**

동기 `Notifier` + `_inFlight` dedup. 광고→API→상태 오케스트레이션. UI 토스트 의존 없이 `PromoteResult` 반환.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/states/promotion_state.dart';

final promotionProvider =
    NotifierProvider<PromotionNotifier, PromotionState>(PromotionNotifier.new);

/// 우선노출(롬업) 상태를 단일 소유하는 오케스트레이터.
/// 광고 보상을 받아야만 백엔드 활성화를 호출한다.
class PromotionNotifier extends Notifier<PromotionState> {
  final Set<String> _inFlight = {}; // 중복 요청 방지

  @override
  PromotionState build() => const PromotionState();

  Future<PromoteResult> promoteItem(String itemId) async {
    if (_inFlight.contains(itemId)) return PromoteResult.alreadyInFlight;
    _inFlight.add(itemId);
    try {
      // 1. 광고 — 보상 받아야만 진행
      final earned = await ref.read(rewardedAdServiceProvider).showAndAwaitReward();
      if (!earned) return PromoteResult.adNotEarned;

      // 2. 백엔드 활성화
      await ref.read(promotionRepositoryProvider).activate(itemId);

      // 3. optimistic 반영 (아직 추가 안 했으므로 롤백 불필요)
      state = state.copyWith(promotedItemIds: {...state.promotedItemIds, itemId});
      return PromoteResult.success;
    } catch (_) {
      return PromoteResult.failed;
    } finally {
      _inFlight.remove(itemId);
    }
  }
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `source ~/.zshrc && flutter analyze lib/providers/promotion_provider.dart`
Expected: No issues found.

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add lib/providers/promotion_provider.dart
git commit -m "feat: 우선노출 오케스트레이터 PromotionNotifier 추가"
```

---

### Task 7: notifier 단위 테스트

**Files:**
- Test: `test/providers/promotion_provider_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`item_like_provider_test.dart`의 Fake 주입 + `ProviderContainer.overrides` 패턴을 따른다. 광고 서비스와 repository 둘 다 Fake로 주입.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/apis/promotion_api.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';

class FakeRewardedAdService extends RewardedAdService {
  bool reward = true;
  int showCount = 0;
  @override
  Future<void> load() async {}
  @override
  Future<bool> showAndAwaitReward() async {
    showCount++;
    return reward;
  }
}

class FakePromotionApi extends PromotionApi {
  bool shouldThrow = false;
  int activateCount = 0;
  @override
  Future<void> activatePromotion(String itemId) async {
    activateCount++;
    if (shouldThrow) throw Exception('boom');
  }
}

void main() {
  group('promotionProvider', () {
    late FakeRewardedAdService ad;
    late FakePromotionApi api;
    late ProviderContainer container;

    setUp(() {
      ad = FakeRewardedAdService();
      api = FakePromotionApi();
      container = ProviderContainer(overrides: [
        rewardedAdServiceProvider.overrideWithValue(ad),
        promotionRepositoryProvider.overrideWithValue(PromotionRepository(api)),
      ]);
    });

    tearDown(() => container.dispose());

    test('보상 O + BE 성공 → success, state에 itemId 포함', () async {
      ad.reward = true;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.success);
      expect(container.read(promotionProvider).isPromoted('A'), isTrue);
      expect(api.activateCount, 1);
    });

    test('보상 X → adNotEarned, state 변화 없음, BE 미호출', () async {
      ad.reward = false;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.adNotEarned);
      expect(container.read(promotionProvider).isPromoted('A'), isFalse);
      expect(api.activateCount, 0);
    });

    test('보상 O + BE 실패 → failed, state 변화 없음', () async {
      ad.reward = true;
      api.shouldThrow = true;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.failed);
      expect(container.read(promotionProvider).isPromoted('A'), isFalse);
    });

    test('진행 중 동일 itemId 재호출 → alreadyInFlight (광고 1회만)', () async {
      ad.reward = true;
      final f1 = container.read(promotionProvider.notifier).promoteItem('A');
      final f2 = container.read(promotionProvider.notifier).promoteItem('A');
      final results = await Future.wait([f1, f2]);
      expect(results, containsAll([PromoteResult.success, PromoteResult.alreadyInFlight]));
      expect(ad.showCount, 1);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 (구현 존재 시 통과 확인)**

Run: `source ~/.zshrc && flutter test test/providers/promotion_provider_test.dart`
Expected: All tests passed. (Task 1~6 구현이 있으므로 통과해야 함. 실패 시 notifier/state 수정)

- [ ] **Step 3: 커밋 (사용자 허락 시에만)**

```bash
git add test/providers/promotion_provider_test.dart
git commit -m "test: PromotionNotifier 단위 테스트 추가"
```

---

### Task 8: UI — my_register_item_screen 버튼/뱃지/토스트

**Files:**
- Modify: `lib/screens/my_page/my_register_item_screen.dart`

`_buildItemTile`은 현재 `Item item, int index`를 받고 `Stack > AppPressable > Row` 구조다(`my_register_item_screen.dart:154`). item tile 하단에 우선노출 버튼/뱃지를 추가하고, 등록 물건(available)에만 노출한다.

- [ ] **Step 1: import 추가**

파일 상단 import 블록에 추가:

```dart
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
```

- [ ] **Step 2: 우선노출 핸들러 메서드 추가**

`_onToggleChanged`(라인 259 부근) 아래에 추가. notifier 호출 후 결과 enum으로 토스트 분기.

```dart
  // 우선노출(롬업) 버튼 핸들러. 광고 시청 → 백엔드 활성화.
  Future<void> _onPromoteTap(Item item) async {
    final itemId = item.itemId;
    if (itemId == null) return;
    final result = await ref.read(promotionProvider.notifier).promoteItem(itemId);
    if (!mounted) return;
    switch (result) {
      case PromoteResult.success:
        CommonSnackBar.show(context: context, message: '내 물건이 우선 노출돼요 ⚡', type: SnackBarType.success);
      case PromoteResult.adNotEarned:
        CommonSnackBar.show(context: context, message: '광고를 끝까지 시청해야 적립돼요', type: SnackBarType.info);
      case PromoteResult.failed:
        CommonSnackBar.show(context: context, message: '잠시 후 다시 시도해주세요', type: SnackBarType.error);
      case PromoteResult.alreadyInFlight:
        break; // 무시
    }
  }
```

- [ ] **Step 3: 버튼/뱃지 위젯 빌더 추가**

`_onPromoteTap` 아래에 추가. iPad 규칙 준수(고정 높이 + vertical padding 동시 사용 금지 → padding만, 고정 px). `AppColors`/`CustomTextStyles` 사용.

```dart
  // 우선노출 버튼(활성 전) / 노출 중 뱃지(활성 후).
  Widget _buildPromoteControl(Item item) {
    final itemId = item.itemId;
    if (itemId == null) return const SizedBox.shrink();
    final isPromoted = ref.watch(promotionProvider).isPromoted(itemId);

    if (isPromoted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.opacity10White,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '⚡ 노출 중',
          style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w600),
        ),
      );
    }

    return AppPressable(
      onTap: () => _onPromoteTap(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryYellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '⚡ 우선 노출',
          style: CustomTextStyles.p3.copyWith(color: AppColors.primaryBlack, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
```

- [ ] **Step 4: tile에 버튼 배치**

`_buildItemTile`의 `Expanded > Column` 마지막 children(라인 239~248 tradeOptions Row) 다음에 우선노출 컨트롤을 추가한다. 단, **등록 물건만** 노출(교환완료 제외).

`tradeOptions` Row 다음(`Column` children 끝)에 삽입:

```dart
                    // 우선노출 컨트롤 — 교환완료 물건엔 표시 안 함
                    if (item.itemStatus != ItemStatus.exchanged.serverName) ...[
                      SizedBox(height: 8.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildPromoteControl(item),
                      ),
                    ],
```

> `ItemStatus`는 이미 import됨(라인 4). `AppPressable`도 import됨(라인 17).

- [ ] **Step 5: 분석 + 포맷**

Run: `source ~/.zshrc && dart format --line-length=120 lib/screens/my_page/my_register_item_screen.dart && flutter analyze lib/screens/my_page/my_register_item_screen.dart`
Expected: No issues found.

- [ ] **Step 6: 커밋 (사용자 허락 시에만)**

```bash
git add lib/screens/my_page/my_register_item_screen.dart
git commit -m "feat: 내 물건 관리 탭에 우선 노출 버튼/뱃지 추가"
```

---

### Task 9: 전체 검증

- [ ] **Step 1: 포맷 전체 적용**

Run: `source ~/.zshrc && dart format --line-length=120 .`
Expected: 포맷 변경 파일 목록 출력 (에러 없음)

- [ ] **Step 2: 린트 전체 분석**

Run: `source ~/.zshrc && flutter analyze`
Expected: No issues found. (에러 발생 시 수정 후 재실행 — CLAUDE.md 자동 처리 규칙)

- [ ] **Step 3: 테스트 전체 실행**

Run: `source ~/.zshrc && flutter test test/providers/promotion_provider_test.dart`
Expected: All tests passed.

---

## Self-Review 결과

**스펙 커버리지:**
- §2 신규 6파일 → enum(Task1)·state(Task2)·service(Task3)·api+repo(Task4)·주입provider(Task5)·notifier(Task6)·test(Task7) 전부 매핑. 단, spec은 6파일이나 plan은 PromoteResult enum과 PromotionApi를 별도 파일로 분리(8파일) — 코드 스타일(enum은 `lib/enums/` 개별 파일, API는 `services/apis/`)에 맞춰 분리. spec §4 의도와 일치.
- §3 데이터 흐름(보상→활성화 순서, `_inFlight`) → Task6 notifier에 구현.
- §4 RewardedAdService boolean 수렴 → Task3.
- §5 UI 버튼/뱃지/토스트 분기 + 등록물건만 노출 → Task8.
- §6 에러 매트릭스 → PromoteResult 분기(Task1·6·8).
- §7 테스트 4케이스 → Task7에 1:1 매핑.
- §9 fetchPromotedIds/만료표시/상태복원 → 1차 범위 제외(YAGNI), plan에서도 미포함 (spec과 일치).

**Placeholder 스캔:** 모든 code step에 실제 코드 포함. "TBD/TODO 적절히" 없음. BE 미확정 가정은 `// TODO(#819 BE)`로 명시 + 실제 동작하는 가정값 제공.

**타입 일관성:** `PromoteResult`(success/adNotEarned/failed/alreadyInFlight), `promotionProvider`, `rewardedAdServiceProvider`/`promotionRepositoryProvider`, `showAndAwaitReward()`, `activate()`/`activatePromotion()`, `isPromoted()`/`promotedItemIds` — Task 간 명칭 일치 확인 완료.

**알려진 가정:**
- `CommonSnackBar.show(context:, message:, type:)` 시그니처는 `home_feed_item_widget.dart` 실사용 기준.
- `SnackBarType.success/info/error`는 `lib/enums/snack_bar_type.dart` 기준.
- 백엔드 엔드포인트는 가정 — 실제 연동 전 BE 확정 필요(§9).
