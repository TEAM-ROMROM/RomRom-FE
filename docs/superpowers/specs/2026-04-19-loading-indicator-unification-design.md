# 로딩 인디케이터 통일 설계 (#761)

## 배경

현재 `CircularProgressIndicator`가 33개 파일에 직접 박혀 있고, 스켈레톤은 채팅 목록·물품 목록·등록 폼 3곳에만 적용되어 있다. 통일감이 없고 화면마다 로딩 경험이 다르다.

목표: 토스 앱 스타일로 통일. 초기 로딩은 shimmer 스켈레톤, 인라인/페이징 로딩은 공통 스피너.

---

## 핵심 규칙

| 상황 | 사용 위젯 |
|------|----------|
| 화면 초기 진입 (`_isLoading && items.isEmpty`) | 스켈레톤 |
| 페이징 (스크롤 하단 추가 로딩) | `CommonLoadingIndicator` (스피너) |
| 버튼 내 로딩 | `CommonLoadingIndicator` (스피너, 흰색) |
| 이미지 업로드/인라인 액션 | `CommonLoadingIndicator` (스피너) |

---

## 아키텍처

### 공통 스피너 위젯 (신규)

**`lib/widgets/common/loading_indicator.dart`**

- `CircularProgressIndicator`를 래핑하는 `CommonLoadingIndicator` 위젯
- 기본 색상: `AppColors.primaryYellow`
- 버튼 내부용 흰색 variant: `CommonLoadingIndicator.white()` (색상: `AppColors.textColorWhite`, 어두운 배경 버튼에서 사용)
- strokeWidth: 2.0 고정
- 33개 파일의 직접 사용을 이 위젯으로 교체

### 스켈레톤 위젯 (신규 5개)

기존 3개(`RegisterTabSkeletonSliver`, `ChatRoomListSkeletonSliver`, `RegisterInputFormSkeleton`)는 유지.

신규 추가:

| 파일 | 사용 화면 |
|------|----------|
| `lib/widgets/skeletons/home_feed_skeleton.dart` | 홈 피드 (`home_tab_screen.dart`) |
| `lib/widgets/skeletons/item_detail_skeleton.dart` | 물품 상세 (`item_detail_description_screen.dart`) |
| `lib/widgets/skeletons/my_like_list_skeleton.dart` | 찜 목록 (`my_like_list_screen.dart`) |
| `lib/widgets/skeletons/notification_settings_skeleton.dart` | 알림 설정 (`notification_settings_screen.dart`) |
| `lib/widgets/skeletons/trade_partner_select_skeleton.dart` | 거래 파트너 선택 (`trade_complete_partner_select_screen.dart`) |

---

## 스켈레톤 설계 원칙

토스 스타일 심플 스켈레톤. 아래 3가지만 지킨다.

1. **라인 2~3개만** — 실제 텍스트 줄 수와 동일하게. 더 많으면 촌스러워짐
2. **너비 변화** — 첫 줄 50~65%, 둘째 줄 35~75% 식으로 다르게. 전부 100%는 금지
3. **실제 UI 비율** — 이미지 높이, 원형 크기를 실제 위젯과 맞춤. 로딩 완료 후 레이아웃 점프 방지

**shimmer 설정 (전 스켈레톤 공통):**
```dart
effect: const ShimmerEffect(
  baseColor: AppColors.opacity10White,
  highlightColor: AppColors.opacity30White,
)
```
패키지: `skeletonizer ^2.1.0+1` (추가 패키지 없음)

---

## 화면별 스켈레톤 상세

### ① 홈 피드 (`HomeFeedSkeletonSliver`)
- SliverGrid 2열 구조
- 각 카드: 이미지 영역(130h) + 제목 라인(65% 너비) + 가격 라인(45% 너비)
- 태그(상태, 거래방식)는 스켈레톤에서 생략

### ② 물품 상세 (`ItemDetailSkeleton`)
- 이미지 전체 너비 (300h)
- 프로필 원형(40×40) + 닉네임/위치 2줄
- 제목(70%) + 가격(40%)
- 설명 텍스트 3줄 (100% / 85% / 60%)

### ③ 찜 목록 (`MyLikeListSkeletonSliver`)
- SliverList 구조
- 각 아이템: 썸네일 정사각형(64×64, radius 10) + 텍스트 3줄

### ④ 알림 설정 (`NotificationSettingsSkeleton`)
- 일반 ListView 구조
- 각 아이템: 원형 프로필(44×44) + 텍스트 2줄 + 토글 자리

### ⑤ 거래 파트너 선택 (`TradePartnerSelectSkeletonSliver`)
- SliverList 구조
- 각 아이템: 원형 프로필(44×44) + 이름/위치 2줄 + 버튼 자리(60×30, radius 8)

---

## 교체 범위

### CircularProgressIndicator → CommonLoadingIndicator
전체 33개 파일. 주요 대상:

- `lib/screens/home_tab_screen.dart` (페이징 로딩)
- `lib/screens/register_tab_screen.dart`
- `lib/screens/item_modification_screen.dart`
- `lib/screens/notification_settings_screen.dart`
- `lib/screens/chat_room_screen.dart`
- `lib/widgets/login_button.dart`
- `lib/widgets/common/cached_image.dart`
- `lib/widgets/common/completion_button.dart`
- `lib/widgets/chat_message_item.dart`
- `lib/widgets/chat_image_bubble.dart`
- 그 외 24개 파일

### 초기 로딩 교체 (스피너 → 스켈레톤)
- `home_tab_screen.dart`: `_isLoading && _feedItems.isEmpty` 분기에서 스켈레톤으로 교체
- `item_detail_description_screen.dart`: 초기 로딩 스피너 → 스켈레톤
- `my_like_list_screen.dart`: 초기 로딩 스피너 → 스켈레톤
- `notification_settings_screen.dart`: 초기 로딩 스피너 → 스켈레톤
- `trade_complete_partner_select_screen.dart`: 초기 로딩 스피너 → 스켈레톤

---

## 변경하지 않는 것

- 기존 3개 스켈레톤 (`RegisterTabSkeletonSliver`, `ChatRoomListSkeletonSliver`, `RegisterInputFormSkeleton`) — 이미 잘 동작 중
- 페이징 로딩 (`_isLoadingMore`) — 스피너 유지. 스크롤 하단 로딩에는 스켈레톤 불필요
- `skeletonizer` 패키지 버전 — 유지
