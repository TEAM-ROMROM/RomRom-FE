# 대형 파일 5개 동작 불변 분해 Implementation Plan (이슈 #937)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 900줄 이상 5개 파일에서 순수 UI 블록·순수 계산을 별도 파일로 추출한다. 동작·외관 완전 불변.

**Architecture:** 파일당 1개 Task. 각 Task는 정찰 분석으로 확정된 추출 단위 목록을 따라 위젯/헬퍼를 새 파일로 이동하고, 원본은 상태·비즈니스 로직 + 조립(glue)만 남긴다. 상태 로직(setState·provider·컨트롤러·구독)은 절대 이동하지 않는다.

**Tech Stack:** Flutter, flutter_screenutil, Riverpod

## Global Constraints

- **⛔ 절대 커밋 금지**: 어떤 Task도 `git add`/`git commit`을 실행하지 않는다. 전체 완료 후 사용자 승인으로 일괄 처리한다. (CLAUDE.md 최우선 규칙)
- **동작 불변 > 줄수 목표**: 추출로 동작이 바뀔 위험이 있으면 보류한다. chat_room(~975줄)·card_hand(~790줄)는 상태 로직 비중 때문에 500줄 목표 미달이 **의도된 결과**다 (로직 계층 분리는 C 이후 후속 이슈).
- **컨트롤러·GlobalKey·ValueNotifier 소유권**: 원본 State가 생성·dispose를 유지하고 추출 위젯에는 **참조만** 전달한다. 위젯 내부에서 재생성 금지.
- **로직 무변경 이동**: 애니메이션 보간·hit-test·키(ValueKey/Hero tag) 로직은 토씨 하나 바꾸지 않고 옮긴다. "개선하고 싶은" 코드가 보여도 이번 스코프에서 건드리지 않는다.
- **새 파일 위치**: 도메인별 기존 관례를 따른다 — 채팅 위젯은 flat(`lib/widgets/chat_room_xxx.dart`, 기존 chat_ 접두사 관례), 나머지는 서브폴더(`lib/widgets/item_detail/`, `lib/widgets/request_management/`, `lib/widgets/register/`, `lib/widgets/home_card_hand/` — 기존 common/·coach_mark/·trade/ 관례).
- 스타일은 `CustomTextStyles`/`AppColors`만 사용 (이슈 #936에서 정리 완료된 상태 유지).
- 각 Task 종료 시: `source ~/.zshrc && dart format --line-length=120 <대상> && flutter analyze && flutter test` 전부 통과.
- 주석은 실무 수준 한국어, WHY 중심. 추출 위젯 파일 상단에 역할 1줄 주석.

## 공통 구현 절차 (모든 Task 동일)

1. 원본 파일 정독 → 추출 단위의 실제 라인 확인 (아래 표의 라인은 정찰 시점 근사치)
2. 추출 단위마다: 새 파일 생성 → 위젯/헬퍼 정의(파라미터·콜백은 표 기준, 실제 코드에 맞게 조정 가능하되 **상태 이동 금지 원칙 준수**) → 원본에서 해당 블록을 위젯 호출로 교체
3. 원본의 미사용 import 정리 (flutter analyze 기준)
4. 검증: format + analyze + `flutter test` + `wc -l` (목표 줄수 ±10% 허용)
5. 보고서에 추출 전/후 위젯 트리 대응표 작성 (리뷰어의 동작 불변 검증용)

---

### Task 1: request_management_tab_screen.dart 분해 (889줄 → ~505줄)

**Files:**
- Modify: `lib/screens/request_management_tab_screen.dart`
- Create: `lib/widgets/request_management/request_item_cards_carousel.dart`, `request_page_indicator.dart`, `request_sort_chip.dart`, `request_list_header.dart`, `request_sent_list.dart`, `request_received_list.dart`

**추출 단위** (정찰 확정):

| 위젯 | 원본 라인 | 파라미터 | 콜백 | 주의점 |
|------|----------|---------|------|--------|
| RequestSortChip | 728-750 | currentSort | onChanged | **가장 먼저 추출** (다른 위젯이 소비). RequestSortBottomSheet.show는 위젯 내부 유지 |
| RequestPageIndicator | 651-672 | itemCount, currentIndex | — | 완전 순수 |
| RequestItemCardsCarousel | 599-648 | itemCards, currentCardIndex, cardController, isLoading | onPageChanged(int), onCardTap(card) | PageController 참조만 주입. ItemDetailDescriptionScreen 이동은 onCardTap 콜백 바디로 화면에 유지 |
| RequestListHeader | 675-725 | isRightSelected, currentSort, showCompletedRequests | onSortChanged, onToggleCompleted | 내부 `if (isRightSelected) return SizedBox.shrink()` 가드 **유지** (동작 불변·diff 최소화) |
| RequestSentList | 293-444 | sentRequests, isLoading, currentSort | onSortChanged, onCardTap, onEditTap, onCancelTap | 취소-vs-이동 분기·다이얼로그·스낵바는 전부 화면 콜백 바디에 유지 |
| RequestReceivedList | 759-887 | filteredRequests, isLoading | onCardTap, onMenuTap | 완료 포함 필터링은 **화면에서 계산 후 결과만 전달**. getDetailedTradeRequest·isNew 갱신은 화면 콜백에 유지 |

- `_buildFullRequestItemsList`의 탭 라우팅(`if (_isRightSelected) ...`)은 화면 내 소형 메서드로 잔류.

- [ ] **Step 1**: RequestSortChip부터 순서대로 6개 위젯 추출 + 원본 교체
- [ ] **Step 2**: 검증 4종 + `wc -l lib/screens/request_management_tab_screen.dart` ≈ 505
- [ ] **Step 3**: 보고서에 위젯 트리 대응표 작성

---

### Task 2: item_detail_description_screen.dart 분해 (1,131줄 → ~540줄)

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`
- Create: `lib/widgets/item_detail/item_detail_status_scaffold.dart`, `item_detail_image_carousel.dart`, `item_detail_profile_like_row.dart`, `item_detail_info_section.dart`, `item_detail_location_map.dart`, `item_detail_top_action_bar.dart`, `item_detail_bottom_action_bar.dart`

**추출 단위** (정찰 확정):

| 위젯 | 원본 라인 | 파라미터 | 콜백 | 주의점 |
|------|----------|---------|------|--------|
| ItemDetailStatusScaffold | 379-456 | message, showRetryButton (+AppBar 유무 variant) | onBack, onRetry | 3분기(탈퇴회원/에러/물품없음) 파라미터화. 451-456 분기는 AppBar 없음 variant |
| ItemDetailImageCarousel | 475-607 | imageSize, imageUrls, pageController, currentIndexVN, stretchScaleVN, heroBaseId, itemStatus | onPageChanged | 컨트롤러·VN 참조만 전달. heroBaseId 생성 로직(`homeFeedItem?.itemUuid ?? itemId`) 그대로 이동. 미사용 `widget.heroTag`는 파라미터로 끌고 가지 않음 |
| ItemDetailProfileLikeRow | 615-728 | itemId, memberId, profileUrl, isDeleteAccount, nickname, memberLocationName, constrainNameWidth | onProfileTap, onLikeTap | **ConsumerWidget으로 추출** — `ref.watch(itemLikeProvider.select(...))` 읽기는 위젯에 두고 mutate(toggle)는 onLikeTap 콜백으로 화면에 유지 (읽기 구독은 규칙 5의 Consumer 패턴에 부합) |
| ItemDetailInfoSection | 733-798 | categoryLabel, dateLabel, itemName, conditionLabel, tradeOptionLabels, formattedPrice, isAiPredictedPrice, description | — | 완전 데이터 표시형, 가장 안전 |
| ItemDetailLocationMap | 803-868 | locationName, itemId, latitude, longitude | onMapTapped | `ValueKey('detail_map_$itemId')` 유지. onMapReady 마커 세팅은 위젯 내부 유지 |
| ItemDetailTopActionBar | 877-1013 | isMyItem, itemStatus, shareButtonKey, itemId | onBack, onShare, onReportSuccess, onToggleStatus, onEditResult, onDeleteConfirmed | shareButtonKey는 State 소유 GlobalKey 전달 (findRenderObject 의존). 비동기 콜백 시그니처 `Future<void> Function()` 필요한 곳 확인 |
| ItemDetailBottomActionBar | 1014-1058 | isChatAccessAllowed, isTradeRequestAllowed | onChatPressed, onRequestPressed | Platform.isAndroid 오프셋(28.h/49.h) 그대로 이전 |

- 잔류: lifecycle(108-370)·비즈니스 메서드(124-370, 1065-1131)·PopScope+ScrollView 골격 (\_scrollController stretch 효과 구동).

- [ ] **Step 1**: 안전한 것부터 — InfoSection → StatusScaffold → LocationMap → BottomActionBar → ImageCarousel → ProfileLikeRow → TopActionBar 순 추출
- [ ] **Step 2**: 검증 4종 + `wc -l` ≈ 540 (±10%)
- [ ] **Step 3**: 보고서에 위젯 트리 대응표 + Hero/스크롤 stretch 동작 확인 방법 기술

---

### Task 3: register_input_form.dart 분해 (948줄 → ~570줄)

**Files:**
- Modify: `lib/widgets/register_input_form.dart`
- Create: `lib/widgets/register/register_image_section.dart`, `register_category_field.dart`, `register_condition_field.dart`, `register_trade_option_field.dart`, `register_price_field.dart`, `register_location_field.dart`

**추출 단위** (정찰 확정):

| 위젯 | 원본 라인 | 파라미터 | 콜백 | 주의점 |
|------|----------|---------|------|--------|
| RegisterImageSection | 330-456 | totalImageCount, existingImageUrls, newImageFiles, hasImageBeenTouched | onPickImage, onDeleteImage(int) | 리스트 참조 그대로 전달(ImageFullscreenViewer 이동 로직은 위젯 내부 유지), XFile 타입 유지 |
| RegisterCategoryField | 479-601 | selectedCategory, hasCategoryBeenTouched, forceValidateAll | onCategoryTouched, onCategorySelected | 바텀시트+tempSelected 지역 상태는 위젯 내부 캡슐화, 최종 선택만 콜백 |
| RegisterConditionField | 619-661 | selectedItemConditionTypes, hasConditionBeenTouched, forceValidateAll | onConditionTap(option) | 단일선택 토글 규칙은 부모 콜백에서 처리 |
| RegisterTradeOptionField | 664-703 | selectedTradeOptions, hasTradeOptionBeenTouched, forceValidateAll | onTradeOptionTap(option) | 다중선택 토글 규칙은 부모 콜백에서 처리 |
| RegisterPriceField | 706-777 | priceController, titleController, descriptionController, forceValidateAll, useAiPrice, canUseAiPrice, selectedItemConditionTypes | onPriceSelected(price, aiUsed) | 컨트롤러 3개 **참조** 전달 (탭 시점 최신 텍스트 조회용). priceController 재설정은 부모에서 |
| RegisterLocationField | 780-806 | locationController, forceValidateAll, latitude, longitude, selectedAddress | onLocationSelected(address) | controller mutate는 부모에서만 (단방향) |

- 잔류: 제목/설명 얇은 필드(각 13~14줄, ROI 없음), 등록 완료 버튼 블록(809-939, 비즈니스 로직 결합 — 추출 제외), 상태·컨트롤러 로직 전부.

- [ ] **Step 1**: 6개 섹션 위젯 추출 + 원본 교체
- [ ] **Step 2**: 검증 4종 + `wc -l` ≈ 570 (±10%)
- [ ] **Step 3**: 보고서에 폼 검증(에러 문구 노출 조건) 전후 동일함을 명시

---

### Task 4: chat_room_screen.dart 분해 (1,065줄 → ~975줄, 소폭)

**Files:**
- Modify: `lib/screens/chat_room_screen.dart`
- Create: `lib/widgets/chat_room_loading_view.dart`, `chat_room_error_view.dart`, `chat_room_message_list.dart` (flat, 기존 chat_ 관례)

**추출 단위** (정찰 확정 — 이 파일은 build 구간만 추출 가능, 나머지 ~895줄이 상태 로직):

| 위젯 | 원본 라인 | 파라미터 | 콜백 | 주의점 |
|------|----------|---------|------|--------|
| ChatRoomLoadingView | 897-902 | — | — | const 생성자 |
| ChatRoomErrorView | 904-953 | errorMessage | onBackPressed, onRetry | 커스텀 뒤로가기 마크업 **그대로 이식** (CommonAppBar 통합 금지 — 동작 불변) |
| ChatRoomMessageList | 1010-1064 | messages, myMemberId, scrollController, uploadingLocalIds, opponentNickname, lastReadMyMessageId | isActiveTradeRequest(int index)→bool, onCancelTradeRequest, onRejectTradeRequest, onConfirmTradeRequest | 빈 상태 분기 포함(별도 파일로 나누지 않고 내부 처리). `reverse: true`·ValueKey 로직 무변경. scrollController 참조만 |

- 잔류: PopScope+Scaffold 조립부(955-1008, pass-through 비용 > 이득), mergeServerMessages(테스트 있는 순수 함수 — 이동 금지), 상태 로직 전부. **500줄 미달은 의도된 결과** — 로직 계층 분리는 후속 이슈로.

- [ ] **Step 1**: 3개 위젯 추출 + 원본 교체
- [ ] **Step 2**: 검증 4종 (특히 `flutter test`의 chat_message_merge_test 통과) + `wc -l` ≈ 975
- [ ] **Step 3**: 보고서 작성

---

### Task 5: home_tab_card_hand.dart 분해 (1,039줄 → ~790줄, 보수적)

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`
- Create: `lib/widgets/home_card_hand/card_hand_geometry.dart` (순수 계산 헬퍼 모음), `card_visual.dart`, `card_hand_drop_zone_indicator.dart`

**추출 단위** (정찰 확정 — 애니메이션·제스처 오케스트레이션은 전부 잔류):

`card_hand_geometry.dart` (순수 함수, context 의존 제거 — 호출부에서 `MediaQuery.of(context).size` 미리 획득해 전달):

| 헬퍼 | 원본 라인 | 주의점 |
|------|----------|--------|
| calculateCardTransform | 460-489 | 호출부 4곳(347,434,497,809) 수정. 로직 무변경 |
| getMinOrbitAngle/getMaxOrbitAngle | 380-395 | 완전 순수 |
| getHighlightOrbitAngle | 397-410 | context 제거, 8.w는 내부 유지 가능 |
| findCardIndexAtPosition | 425-458 | calculateCardTransform과 같은 파일 필수. 주석(429-431) 이관 |
| buildCardBoxShadow | 594-631 | 완전 순수 |
| computeCardVisualTransform | 513-563 | **분기 조건(t<=0.4, t<=0.5, length>1) 토씨 하나 무변경** — 애니메이션 시퀀스 깨짐 최고 위험 지점 |
| generateInitialCards/loadCardsLeft/loadCardsRight | 255-301 | 필드 mutate → 결과 record 반환으로 순수화, 호출부 3곳에서 필드 대입 |

위젯:

| 위젯 | 원본 라인 | 파라미터 | 주의점 |
|------|----------|---------|--------|
| CardVisual | 633-675 | left, top, angle, scale, cardWidth/Height, isPulled, isHovered, isAiHighlighted, pulseValue, cardBoxShadow, cardData, cardId | AnimatedContainer duration(isPulled? 100:200ms) 정확 전달. 부모 AnimatedBuilder가 rebuild 트리거 — Stateless 분리로 동작 동일 |
| CardHandDropZoneIndicator | 961-1024 | dropZoneKey(GlobalKey), dropShadowT, iconAnimation | dropZoneKey는 부모 hit-test(_globalRectOf) 의존 — 반드시 참조 전달 |

- 잔류: _reorderForAiHighlight(3-컨트롤러 오케스트레이션+generation 가드), 팬 제스처 4종(681-931), _buildCard 골격·상태 분기, lifecycle 전부, dim 오버레이(9줄, ROI 없음). **500줄 미달은 의도된 결과.**

- [ ] **Step 1**: card_hand_geometry.dart 헬퍼 추출 (호출부 수정 포함) → analyze/test 통과 확인 후
- [ ] **Step 2**: CardVisual, CardHandDropZoneIndicator 위젯 추출
- [ ] **Step 3**: 검증 4종 + `wc -l` ≈ 790. 보고서에 "홈탭 카드 스와이프·카드뽑기·AI 하이라이트 재정렬" 수동 확인 필요 항목 명시

---

### Task 6: 전체 최종 검증

**Files:** 없음 (검증 전용)

- [ ] **Step 1**: `source ~/.zshrc && dart format --line-length=120 . && flutter analyze && flutter test` 전부 통과
- [ ] **Step 2**: 줄수 최종 확인 — `wc -l` 5개 원본 + 신규 파일 전체 (신규 파일 중 300줄 초과가 있으면 보고만, 재분해는 하지 않음)
- [ ] **Step 3**: 스타일 규칙 재스캔 (신규 파일이 #936 규칙 준수하는지): `grep -rn "Color(0x" lib/widgets/item_detail lib/widgets/request_management lib/widgets/register lib/widgets/home_card_hand lib/widgets/chat_room_*.dart | grep -v app_colors` → 출력 없음
- [ ] **Step 4**: 사용자에게 diff 요약 + 수동 QA 필요 항목(카드핸드 제스처, 채팅방, 물건 상세 Hero) 보고 후 커밋 승인 대기
