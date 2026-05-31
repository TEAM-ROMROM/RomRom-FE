# 거래 후기 작성 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 거래 완료 후 상대방에 대한 2단계 후기 작성 화면 신규 추가 및 채팅방·물품 등록 탭 진입 플로우 연결

**Architecture:** 단일 `TradeReviewScreen`에서 `_step` 변수로 1단계(만족도 선택)↔2단계(칭찬 태그 + 한마디) 내부 전환. 건너뛰기/완료 후 스택 클리어하여 홈으로 이동. 후기 제출은 `TradeApi.postTradeReview()`로 기존 `trade_api.dart`에 추가.

**Tech Stack:** Flutter, flutter_screenutil, json_annotation/build_runner, HTTP multipart

---

## 파일 구성

| 파일 | 구분 | 역할 |
|------|------|------|
| `lib/enums/trade_review_rating.dart` | 신규 | BAD/GOOD/GREAT 만족도 enum |
| `lib/enums/trade_review_tag.dart` | 신규 | 칭찬 태그 5개 enum |
| `lib/screens/trade_review_screen.dart` | 신규 | 2단계 후기 작성 화면 |
| `lib/models/apis/requests/trade_request.dart` | 수정 | tradeReviewRating/tradeReviewTags/reviewComment 필드 추가 |
| `lib/models/apis/requests/trade_request.g.dart` | 재생성 | build_runner |
| `lib/services/apis/trade_api.dart` | 수정 | postTradeReview() 추가 |
| `lib/screens/chat_room_screen.dart` | 수정 | _onConfirmTradeRequest 후 리뷰 화면 진입 |
| `lib/screens/register_tab_screen.dart` | 수정 | _toggleItemStatus 교환 완료 후 리뷰 화면 진입 |

---

## Task 1: TradeReviewRating enum 생성

**Files:**
- Create: `lib/enums/trade_review_rating.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/enums/trade_review_rating.dart
enum TradeReviewRating {
  bad(label: '별로예요', serverName: 'BAD'),
  good(label: '좋아요', serverName: 'GOOD'),
  great(label: '최고에요', serverName: 'GREAT');

  final String label;
  final String serverName;

  const TradeReviewRating({required this.label, required this.serverName});
}
```

- [ ] **Step 2: 포맷**

```bash
source ~/.zshrc && dart format --line-length=120 lib/enums/trade_review_rating.dart
```

---

## Task 2: TradeReviewTag enum 생성

**Files:**
- Create: `lib/enums/trade_review_tag.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/enums/trade_review_tag.dart
enum TradeReviewTag {
  fastResponse(label: '답장이 빨라요', serverName: 'FAST_RESPONSE'),
  goodItemCondition(label: '물건 상태가 좋아요', serverName: 'GOOD_ITEM_CONDITION'),
  matchesPhoto(label: '사진과 같아요', serverName: 'MATCHES_PHOTO'),
  punctual(label: '약속을 잘 지켜요', serverName: 'PUNCTUAL'),
  kind(label: '친절해요', serverName: 'KIND');

  final String label;
  final String serverName;

  const TradeReviewTag({required this.label, required this.serverName});
}
```

- [ ] **Step 2: 포맷**

```bash
source ~/.zshrc && dart format --line-length=120 lib/enums/trade_review_tag.dart
```

---

## Task 3: TradeRequest 모델에 후기 필드 추가 + g.dart 재생성

**Files:**
- Modify: `lib/models/apis/requests/trade_request.dart`
- Regenerate: `lib/models/apis/requests/trade_request.g.dart`

- [ ] **Step 1: TradeRequest에 3개 필드 추가**

`trade_request.dart`의 기존 필드 목록 아래에 추가:

```dart
// 기존 필드들 유지
String? takeItemId;
String? giveItemId;
String? tradeRequestHistoryId;
List<String>? itemTradeOptions;
int pageNumber;
int pageSize;

// 아래 3개 추가
String? tradeReviewRating;
List<String>? tradeReviewTags;
String? reviewComment;
```

생성자에도 추가:

```dart
TradeRequest({
  this.member,
  this.takeItemId,
  this.giveItemId,
  this.tradeRequestHistoryId,
  this.itemTradeOptions,
  this.pageNumber = 0,
  this.pageSize = 10,
  this.tradeReviewRating,   // 추가
  this.tradeReviewTags,     // 추가
  this.reviewComment,       // 추가
});
```

- [ ] **Step 2: build_runner로 g.dart 재생성**

```bash
source ~/.zshrc && dart run build_runner build --delete-conflicting-outputs
```

Expected: `trade_request.g.dart` 갱신 완료

- [ ] **Step 3: 포맷 + 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/models/apis/requests/trade_request.dart && flutter analyze lib/models/apis/requests/
```

Expected: No issues found

---

## Task 4: TradeApi에 postTradeReview 추가

**Files:**
- Modify: `lib/services/apis/trade_api.dart`

- [ ] **Step 1: postTradeReview 메서드 추가**

`trade_api.dart`의 마지막 메서드(getAiRecommendItemList) 뒤, 클래스 닫는 `}` 전에 추가:

```dart
/// 거래 후기 작성 API
/// `POST /api/trade/review/post`
Future<void> postTradeReview(TradeRequest request) async {
  const String url = '${AppUrls.baseUrl}/api/trade/review/post';

  final id = request.tradeRequestHistoryId;
  if (id == null || id.isEmpty) {
    throw ArgumentError('tradeRequestHistoryId is required');
  }

  final Map<String, dynamic> fields = {
    'tradeRequestHistoryId': id,
    if (request.tradeReviewRating != null) 'tradeReviewRating': request.tradeReviewRating!,
    if (request.tradeReviewTags != null && request.tradeReviewTags!.isNotEmpty)
      'tradeReviewTags': request.tradeReviewTags!.join(','),
    if (request.reviewComment != null && request.reviewComment!.isNotEmpty) 'reviewComment': request.reviewComment!,
  };

  final response = await ApiClient.sendMultipartRequest(
    url: url,
    fields: fields,
    isAuthRequired: true,
    onSuccess: (_) {},
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    debugPrint('거래 후기 작성 성공');
  } else {
    throw Exception('거래 후기 작성 실패: ${response.statusCode}');
  }
}
```

- [ ] **Step 2: 포맷 + 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/services/apis/trade_api.dart && flutter analyze lib/services/apis/trade_api.dart
```

Expected: No issues found

---

## Task 5: TradeReviewScreen 생성

**Files:**
- Create: `lib/screens/trade_review_screen.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

class TradeReviewScreen extends StatefulWidget {
  final String tradeRequestHistoryId;
  final String opponentNickname;

  const TradeReviewScreen({
    super.key,
    required this.tradeRequestHistoryId,
    required this.opponentNickname,
  });

  @override
  State<TradeReviewScreen> createState() => _TradeReviewScreenState();
}

class _TradeReviewScreenState extends State<TradeReviewScreen> {
  int _step = 1;
  TradeReviewRating? _rating;
  final Set<TradeReviewTag> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool skipDetails = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await TradeApi().postTradeReview(
        TradeRequest(
          tradeRequestHistoryId: widget.tradeRequestHistoryId,
          tradeReviewRating: _rating!.serverName,
          tradeReviewTags: skipDetails ? null : _selectedTags.map((t) => t.serverName).toList(),
          reviewComment: skipDetails ? null : _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        ),
      );
      if (!mounted) return;
      context.navigateTo(
        screen: const MainScreen(),
        type: NavigationTypes.pushAndRemoveUntil,
        predicate: (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await CommonModal.error(
        context: context,
        message: ErrorUtils.getErrorMessage(e),
        onConfirm: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _step == 1 ? _buildStep1() : _buildStep2();
  }

  // ── 1단계: 만족도 선택 ──────────────────────────────────────────────────

  Widget _buildStep1() {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  SizedBox(height: 40.h),
                  RichText(
                    text: TextSpan(
                      style: CustomTextStyles.h1,
                      children: [
                        TextSpan(
                          text: widget.opponentNickname,
                          style: CustomTextStyles.h1.copyWith(color: AppColors.primaryYellow),
                        ),
                        const TextSpan(text: '님과의\n교환은 어떠셨나요?'),
                      ],
                    ),
                  ),
                  SizedBox(height: 60.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: TradeReviewRating.values.map((rating) => _buildRatingOption(rating)).toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24.w,
              right: 24.w,
              bottom: 48.h,
              child: CompletionButton(
                isEnabled: _rating != null,
                buttonText: '다음',
                enabledOnPressed: () => setState(() => _step = 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(TradeReviewRating rating) {
    final isSelected = _rating == rating;
    return GestureDetector(
      onTap: () => setState(() => _rating = rating),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.opacity30White : AppColors.opacity10White,
                border: isSelected ? Border.all(color: AppColors.primaryYellow, width: 2) : null,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              rating.label,
              style: CustomTextStyles.p2.copyWith(
                color: isSelected ? AppColors.textColorWhite : AppColors.opacity60White,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2단계: 칭찬 태그 + 한마디 ───────────────────────────────────────────

  Widget _buildStep2() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      GestureDetector(
                        onTap: () => setState(() => _step = 1),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      SizedBox(height: 40.h),
                      Text('어떤 점이 좋았나요?', style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(height: 24.h),
                      ...TradeReviewTag.values.map((tag) => _buildTagRow(tag)),
                      SizedBox(height: 32.h),
                      Text('한마디를 남겨주세요', style: CustomTextStyles.h3),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        height: 140.h,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBlack1,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.opacity30White, width: 1.5.w),
                        ),
                        child: TextField(
                          controller: _commentController,
                          maxLines: null,
                          style: CustomTextStyles.p2,
                          cursorColor: AppColors.textColorWhite,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: '매너 있는 교환 파트너를 칭찬해주세요',
                            hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
                          ),
                        ),
                      ),
                      SizedBox(height: 180.h),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24.w,
              right: 24.w,
              bottom: 48.h,
              child: Row(
                children: [
                  Expanded(
                    child: CompletionButton(
                      isEnabled: true,
                      buttonText: '건너뛰기',
                      enabledBackgroundColor: AppColors.secondaryBlack2,
                      enabledTextColor: AppColors.textColorWhite,
                      enabledOnPressed: () => _submit(skipDetails: true),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CompletionButton(
                      isEnabled: true,
                      isLoading: _isSubmitting,
                      buttonText: '완료',
                      enabledOnPressed: () => _submit(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(TradeReviewTag tag) {
    final isSelected = _selectedTags.contains(tag);
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
        }),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => setState(() {
                  isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                }),
                activeColor: AppColors.primaryYellow,
                checkColor: AppColors.primaryBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                side: BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(tag.label, style: CustomTextStyles.h3)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 + 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/trade_review_screen.dart && flutter analyze lib/screens/trade_review_screen.dart
```

Expected: No issues found

---

## Task 6: 채팅방 진입 플로우 연결

**Files:**
- Modify: `lib/screens/chat_room_screen.dart`

`_onConfirmTradeRequest()` (line 625)를 찾아 성공 후 리뷰 화면으로 이동하도록 수정.

- [ ] **Step 1: import 추가**

`chat_room_screen.dart` 상단 imports에 추가:

```dart
import 'package:romrom_fe/screens/trade_review_screen.dart';
```

- [ ] **Step 2: _onConfirmTradeRequest 수정**

기존:
```dart
Future<void> _onConfirmTradeRequest() async {
  if (_isPendingTradeAction) return;
  setState(() => _isPendingTradeAction = true);
  try {
    await ChatApi().confirmTradeCompletion(chatRoomId: widget.chatRoomId);
  } catch (e) {
    if (mounted) {
      CommonSnackBar.show(context: context, message: '교환 완료 확인에 실패했습니다: $e', type: SnackBarType.error);
    }
  } finally {
    if (mounted) setState(() => _isPendingTradeAction = false);
  }
}
```

변경 후:
```dart
Future<void> _onConfirmTradeRequest() async {
  if (_isPendingTradeAction) return;
  setState(() => _isPendingTradeAction = true);
  try {
    await ChatApi().confirmTradeCompletion(chatRoomId: widget.chatRoomId);
    if (!mounted) return;
    final tradeRequestHistoryId = chatRoom.tradeRequestHistory?.tradeRequestHistoryId;
    if (tradeRequestHistoryId != null) {
      context.navigateTo(
        screen: TradeReviewScreen(
          tradeRequestHistoryId: tradeRequestHistoryId,
          opponentNickname: _opponentNickname,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      CommonSnackBar.show(context: context, message: '교환 완료 확인에 실패했습니다: $e', type: SnackBarType.error);
    }
  } finally {
    if (mounted) setState(() => _isPendingTradeAction = false);
  }
}
```

- [ ] **Step 3: 포맷 + 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/chat_room_screen.dart && flutter analyze lib/screens/chat_room_screen.dart
```

Expected: No issues found

---

## Task 7: 물품 등록 탭 진입 플로우 연결

**Files:**
- Modify: `lib/screens/register_tab_screen.dart`

`_toggleItemStatus()` (line 703)에서 교환 완료로 변경 성공 후 리뷰 화면으로 이동하도록 수정.

- [ ] **Step 1: import 추가**

`register_tab_screen.dart` 상단 imports에 추가:

```dart
import 'package:romrom_fe/screens/trade_review_screen.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
```

(이미 trade_api, trade_request를 import하고 있다면 skip)

- [ ] **Step 2: _toggleItemStatus 수정**

기존 `updateItemStatus` 성공 후 부분:
```dart
await itemApi.updateItemStatus(request);

// 성공 시 목록 새로고침
_loadMyItems(isRefresh: true);

if (mounted) {
  final successMessage = _currentTabStatus == MyItemToggleStatus.selling ? '교환 완료로 변경되었습니다' : '판매중으로 변경되었습니다';
  CommonSnackBar.show(context: context, message: successMessage);
}
```

변경 후:
```dart
await itemApi.updateItemStatus(request);

// 성공 시 목록 새로고침
_loadMyItems(isRefresh: true);

if (!mounted) return;

// 교환 완료로 변경할 때만 후기 화면으로 이동
if (_currentTabStatus == MyItemToggleStatus.selling && item.itemId != null) {
  try {
    final paged = await TradeApi().getReceivedTradeRequests(TradeRequest(takeItemId: item.itemId));
    if (!mounted) return;
    if (paged.content.isNotEmpty) {
      final tradeRequest = paged.content.first;
      final tradeRequestHistoryId = tradeRequest.tradeRequestHistoryId;
      final opponentNickname = tradeRequest.giveItem.member?.nickname ?? '상대방';
      if (tradeRequestHistoryId != null) {
        context.navigateTo(
          screen: TradeReviewScreen(
            tradeRequestHistoryId: tradeRequestHistoryId,
            opponentNickname: opponentNickname,
          ),
        );
        return;
      }
    }
  } catch (e) {
    debugPrint('후기 화면 진입용 거래 요청 조회 실패: $e');
  }
}

if (mounted) {
  final successMessage = _currentTabStatus == MyItemToggleStatus.selling ? '교환 완료로 변경되었습니다' : '판매중으로 변경되었습니다';
  CommonSnackBar.show(context: context, message: successMessage);
}
```

- [ ] **Step 3: 포맷 + 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/register_tab_screen.dart && flutter analyze lib/screens/register_tab_screen.dart
```

Expected: No issues found

---

## Task 8: 전체 빌드 검증

- [ ] **Step 1: 전체 포맷 + 린트**

```bash
source ~/.zshrc && dart format --line-length=120 . && flutter analyze
```

Expected: No issues found

- [ ] **Step 2: 수동 테스트 체크리스트**

1. 채팅방에서 거래 완료 요청 수락 → 1단계 화면 진입 확인
2. 1단계 감정 미선택 → 다음 버튼 비활성 확인
3. 1단계 감정 선택 → 다음 버튼 활성, 2단계 진입 확인
4. 2단계 < 버튼 → 1단계로 내부 전환 확인 (pop 아님)
5. 2단계 건너뛰기 → API 호출 (tags/comment 없음) → 홈 이동 확인
6. 2단계 완료 → API 호출 (모든 데이터) → 홈 이동 확인
7. X 버튼 → 후기 작성 취소, 이전 화면으로 pop 확인
8. 물품 등록 탭 교환 완료 처리 → 후기 화면 진입 확인
9. API 실패 시 에러 모달 표시, 화면 유지 확인
