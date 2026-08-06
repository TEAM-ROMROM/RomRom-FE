# 보상형 광고 기반 '내 물건 우선 노출' 설계 (이슈 #819)

## 1. 배경 & 목표

당근마켓의 '끌올'을 롬롬의 쇼츠형 스와이프 피드에 맞게 변형한 기능. 가칭 **롬업**.

유저가 **AdMob 보상형 영상 광고**를 끝까지 시청하면, 그 보상으로 **내 물건이 타겟 유저들의 스와이프 피드에 우선 교차 노출**된다.

- **트리거**: 내 물건 관리 탭(`나의 등록된 물건` 화면)에서 물건별 `[우선 노출]` 버튼 클릭
- **보상**: 광고 시청 완료 → 백엔드에 우선노출 활성화 요청 → 해당 물건이 추천 피드에 우선 노출

### 범위 경계 (중요)

이슈 #819의 핵심 로직 중 **백엔드 담당 영역**과 **프론트엔드 담당 영역**을 명확히 분리한다. 본 spec은 **프론트엔드 전체 플로우**만 다룬다.

**백엔드 담당 (본 spec 범위 밖)**:
- 타겟 유저 매칭 (관심 카테고리 + 거리 범위 필터)
- 피드 노출 비율 믹싱 알고리즘 (우선노출 카드 vs 기존 추천 카드, 예: 50:50 / 30:70)
- 우선노출 대기열 관리 (최대 100개 순번 등)
- 광고 보상 검증 (서버사이드 verification)

**프론트엔드 담당 (본 spec)**:
- `[우선 노출]` 버튼 UI + 활성 상태 뱃지
- AdMob 보상형 광고 로드/표시/보상 콜백 처리
- 광고 보상 성공 시 백엔드 활성화 API 호출
- 우선노출 상태를 Riverpod provider로 중앙 관리, 화면 구독

> 백엔드 API 스펙(엔드포인트·요청 바디·보상 검증 토큰)은 미확정이다(이슈 #819 백엔드 담당 미정). FE는 repository 인터페이스만 고정하고, BE 확정 시 repository 내부 구현만 교체한다.

## 2. 아키텍처

```
[my_register_item_screen]  ← 화면(ConsumerStatefulWidget)
        │ [우선 노출] 버튼 탭
        ▼
[promotionProvider.notifier.promoteItem(itemId)]  ← 행위(오케스트레이터)
        │
        ├─ 1. RewardedAdService.showAndAwaitReward() ──► AdMob SDK
        │         보상 받음(true) / 미적립(false)
        │
        ├─ 2. PromotionRepository.activate(itemId) ──► 백엔드 API
        │
        └─ 3. PromotionState 갱신 (해당 itemId 우선노출 활성)
        │
        ▼ 결과 enum 반환
[화면이 결과로 토스트 분기]
```

### 신규 파일 (6개)

| 파일 | 책임 | 종류 |
|---|---|---|
| `lib/services/rewarded_ad_service.dart` | 보상형 광고 로드·표시·보상 콜백 캡슐화. UI/비즈니스 로직 모름 | Service |
| `lib/repositories/promotion_repository.dart` | 백엔드 우선노출 API 래핑. UI 모름 | Repository |
| `lib/states/promotion_state.dart` | `@immutable` 상태 모델 (우선노출 활성 itemId 집합) | State |
| `lib/providers/promotion_provider.dart` | 동기 `Notifier` + `_inFlight` dedup. 광고→API→상태 오케스트레이션 | Provider |
| `lib/providers/promotion_repository_provider.dart` | repository plain Provider 주입 (테스트 override용) | Provider |
| `test/promotion_notifier_test.dart` | notifier 단위 테스트 | Test |

### 수정 파일 (1개)

- `lib/screens/my_page/my_register_item_screen.dart` — item tile에 `[우선 노출]` 버튼 + 활성 뱃지 추가, `promotionProvider` 구독

### 손대지 않는 파일

- `lib/services/ad_mob_service.dart` — 보상형 광고 unit ID(`rewardedAdUnitId`)는 이미 존재. 그대로 유지. 광고 생명주기 로직은 신규 `RewardedAdService`가 담당

### 책임 경계

- `RewardedAdService` = AdMob SDK 생명주기만. 결과는 **boolean 하나**(보상 받았나). 우선노출이 뭔지 모름
- `PromotionRepository` = 백엔드 API만. 광고 모름
- `PromotionNotifier` = 둘을 엮는 오케스트레이터. **"광고 보상 받아야만 API 호출"** 순서 보장. UI 토스트 의존 안 함 (결과 enum 반환)

본 구조는 CLAUDE.md 규칙 1(repository→state→provider 4-레이어), 규칙 2(optimistic 토글 → 동기 Notifier + `_inFlight`), 규칙 3(mutation은 notifier 메서드로만)을 따른다.

## 3. 데이터 흐름

```
유저: [우선 노출] 버튼 탭
  │
  ▼
promotionProvider.notifier.promoteItem(itemId) → Future<PromoteResult>
  │
  ├─ _inFlight.contains(itemId)? → return alreadyInFlight (중복 방지)
  ├─ _inFlight.add(itemId)
  │
  ├─ 1. final earned = await rewardedAdService.showAndAwaitReward()
  │       earned == false → return adNotEarned (BE 호출 안 함)
  │
  ├─ 2. await promotionRepository.activate(itemId)
  │       성공 → state에 itemId 추가 (optimistic 활성화) → return success
  │       실패 → return failed (state 미반영)
  │
  └─ finally: _inFlight.remove(itemId)
```

### 보상 확정 시점 (AdMob 표준)

`onUserEarnedReward` 콜백에서 보상 플래그를 set하고, 광고가 닫힐 때(`onAdDismissedFullScreenContent`) Completer를 완료해 최종 결과를 확정한다. 보상 콜백은 광고가 닫히기 전에 도착하므로 이 순서가 안전하다.

## 4. 컴포넌트 상세

### RewardedAdService

```dart
class RewardedAdService {
  RewardedAd? _ad;

  Future<void> load();  // 광고 미리 로드 (prefetch)

  /// 광고 표시 후 보상 여부 반환.
  /// true = 보상 적립 / false = 미적립(이탈·실패·미로드)
  Future<bool> showAndAwaitReward();
}
```

- 단일 진입점 `showAndAwaitReward()`. 결과는 boolean.
- 로드 실패·중도 이탈·표시 실패 전부 `false`로 수렴 → 호출측 분기 단순화.
- `AdMobService.rewardedAdUnitId` 사용 (테스트 빌드면 테스트 ID, 아니면 .env 실제 ID).

### PromotionState

```dart
@immutable
class PromotionState {
  final Set<String> promotedItemIds;  // 우선노출 활성 itemId 집합
  const PromotionState({this.promotedItemIds = const {}});
  bool isPromoted(String itemId) => promotedItemIds.contains(itemId);
  PromotionState copyWith({Set<String>? promotedItemIds});
  // == / hashCode (Set 비교)
}
```

### PromotionRepository

```dart
class PromotionRepository {
  /// 우선노출 활성화 요청. (보상 검증 토큰 등은 BE 스펙 확정 시 파라미터 추가)
  Future<void> activate(String itemId);

  /// (선택) 현재 우선노출 중인 내 물건 ID 목록 조회 — 앱 재시작 후 상태 복원용
  Future<Set<String>> fetchPromotedIds();
}
```

`fetchPromotedIds()`는 앱 재시작 시 우선노출 상태 복원을 위한 것. BE에 조회 API가 없으면 1차 구현에서 생략 가능(YAGNI). 본 spec에서는 인터페이스만 정의하고 1차 구현은 `activate`만 연결한다.

### PromotionNotifier + 결과 enum

```dart
enum PromoteResult { success, adNotEarned, failed, alreadyInFlight }

class PromotionNotifier extends Notifier<PromotionState> {
  final Set<String> _inFlight = {};

  @override
  PromotionState build() => const PromotionState();

  Future<PromoteResult> promoteItem(String itemId) async {
    if (_inFlight.contains(itemId)) return PromoteResult.alreadyInFlight;
    _inFlight.add(itemId);
    try {
      final earned = await ref.read(rewardedAdServiceProvider).showAndAwaitReward();
      if (!earned) return PromoteResult.adNotEarned;

      await ref.read(promotionRepositoryProvider).activate(itemId);
      state = state.copyWith(promotedItemIds: {...state.promotedItemIds, itemId});
      return PromoteResult.success;
    } catch (e) {
      return PromoteResult.failed;
    } finally {
      _inFlight.remove(itemId);
    }
  }
}

final promotionProvider =
    NotifierProvider<PromotionNotifier, PromotionState>(PromotionNotifier.new);
```

**결과 전달 방식 = enum 반환(채택)**. notifier가 UI 토스트에 의존하지 않아 테스트가 쉽고 레이어 경계가 깨끗하다. 토스트는 화면이 결과 enum을 보고 분기한다.

## 5. UI 변경 (my_register_item_screen.dart)

`_buildItemTile`의 item tile에 우선노출 버튼/뱃지를 추가한다.

```
┌─────────────────────────────────────┐
│ [이미지]  물건명                       │
│           위치 · 3시간 전              │
│           12,000원                    │
│           [직거래][택배]               │
│                          [⚡우선노출] │ ← 신규
└─────────────────────────────────────┘
```

- **활성 전**: `[⚡ 우선 노출]` 버튼 (등록 물건 = `available`만 노출, 교환완료 `exchanged` 제외)
- **활성 후**: `[⚡ 노출 중]` 뱃지 (비활성)
- 화면은 `ref.watch(promotionProvider)`로 `isPromoted(item.itemId)` 구독 → 버튼/뱃지 자동 전환
- 탭 → `ref.read(promotionProvider.notifier).promoteItem(itemId)` 호출, 반환 enum으로 토스트 분기

### 토스트 분기 (결과별)

| PromoteResult | 토스트 |
|---|---|
| `success` | "내 물건이 우선 노출돼요 ⚡" |
| `adNotEarned` | "광고를 끝까지 시청해야 적립돼요" |
| `failed` | "잠시 후 다시 시도해주세요" (보상은 받았으나 서버 적립 실패 — BE 멱등/재시도로 보완) |
| `alreadyInFlight` | (무시, 토스트 없음) |

토스트는 프로젝트 공통 토스트 패턴 사용(`CommonModal`/공통 토스트 위젯 — 코드 확인 후 기존 것 재사용).

### 절대 규칙 준수

- 색상 `AppColors`, 텍스트 `CustomTextStyles` 사용
- iPad 대응: 버튼은 고정 높이 + vertical height/padding 동시 사용 금지 (CLAUDE.md iPad 규칙)
- API 중복 요청 방지: `_inFlight` Set 패턴 (notifier 내부)

## 6. 에러 처리 매트릭스

| 상황 | 처리 |
|---|---|
| 광고 로드 실패 | `earned=false` → `adNotEarned` → 토스트, BE 호출 안 함 |
| 광고 중도 이탈 | `earned=false` → `adNotEarned` → 토스트, BE 호출 안 함 |
| 보상 받음 + BE 성공 | state 활성화, `success` 토스트 |
| 보상 받음 + BE 실패 | `failed` 토스트, state 미반영. (보상 손실은 BE 멱등 처리/재시도 영역) |
| 중복 탭 | `_inFlight`로 무시, `alreadyInFlight` |

## 7. 테스트 (promotion_notifier_test.dart)

`rewardedAdServiceProvider`·`promotionRepositoryProvider`를 mock으로 override하여:

1. 보상 O + BE 성공 → `success`, state에 itemId 포함
2. 보상 X → `adNotEarned`, state 변화 없음, BE 미호출
3. 보상 O + BE 실패(throw) → `failed`, state 변화 없음
4. 진행 중 동일 itemId 재호출 → `alreadyInFlight`

## 8. 작업 분해 (구현 단계 미리보기)

1. `RewardedAdService` 작성 (+ 광고 표시/보상 콜백)
2. `PromotionState` + `PromotionRepository` + repository provider
3. `PromotionNotifier` + `promotionProvider` + `PromoteResult` enum
4. `promotion_notifier_test.dart` (4케이스)
5. `my_register_item_screen.dart` 버튼/뱃지 + 구독 + 토스트 분기
6. `dart format` + `flutter analyze` 통과

## 9. 미확정 / 후속 논의 필요

- **백엔드 API 스펙**: 엔드포인트 경로, 요청 바디, 보상 검증 토큰 필요 여부 → BE 담당자와 확정. FE는 repository 인터페이스만 고정.
- **우선노출 만료/기간 표시**: "노출 중" 뱃지에 남은 시간/순번 표시 여부는 BE가 데이터를 주는지에 따라. 1차에서는 단순 활성/비활성만.
- **상태 복원**: 앱 재시작 후 우선노출 상태 복원(`fetchPromotedIds`)은 BE 조회 API 유무에 따라 후속.
- 이슈가 `보류` 라벨 상태 — 우선순위는 팀 결정.
