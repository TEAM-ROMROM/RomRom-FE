import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/trade_review_rules.dart';
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/app_review_popup.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/trade/rating_option_button.dart';
import 'package:romrom_fe/widgets/trade/trade_review_comment_field.dart';

/// 교환 완료 후 리뷰 작성 화면: 1단계 만족도 > 2단계 태그(평가별)·한마디 > 제출 후 원래 화면 복귀 (pop(true))
class TradeReviewScreen extends ConsumerStatefulWidget {
  final String tradeRequestHistoryId;
  final String opponentNickname;

  const TradeReviewScreen({super.key, required this.tradeRequestHistoryId, required this.opponentNickname});

  @override
  ConsumerState<TradeReviewScreen> createState() => _TradeReviewScreenState();
}

class _TradeReviewScreenState extends ConsumerState<TradeReviewScreen> {
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

  /// 상세(평가에 맞는 태그·한마디) 작성 여부
  bool get _hasReviewDetails =>
      hasReviewDetails(rating: _rating!, selectedTags: _selectedTags, comment: _commentController.text);

  /// 후기 제출: 제출 값 정리 > API > 앱 리뷰 팝업 조건 > 원래 화면 복귀 (실패·중복 작성은 서버 문구 모달)
  Future<void> _submit({bool skipDetails = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final submission = buildTradeReviewSubmission(
        rating: _rating!,
        selectedTags: _selectedTags,
        comment: _commentController.text,
        isSkippingDetails: skipDetails,
      );
      await ref
          .read(tradeRepositoryProvider)
          .postTradeReview(
            tradeRequestHistoryId: widget.tradeRequestHistoryId,
            tradeReviewRating: _rating!.serverName,
            tradeReviewTags: submission.tagServerNames,
            reviewComment: submission.comment,
          );
      if (!mounted) return;

      // 거래 완료 횟수 기록 및 리뷰 팝업 조건 체크
      final reviewService = AppReviewService();
      await reviewService.onTradeComplete();

      if (!mounted) return;

      if (await reviewService.shouldShow(tradeTriggered: true)) {
        if (mounted) await AppReviewPopup.show(context, reviewService);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  /// 건너뛰기: 쓴 내용이 있으면 버려도 되는지 확인 > 평가만 제출
  Future<void> _onSkipPressed() async {
    if (_isSubmitting) return;
    if (_hasReviewDetails) {
      final bool? isDiscardConfirmed = await CommonModal.confirm(
        context: context,
        message: '작성한 내용은 저장되지 않아요.\n건너뛸까요?',
        confirmText: '건너뛰기',
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      );
      if (isDiscardConfirmed != true || !mounted) return;
    }
    await _submit(skipDetails: true);
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

                  /// 닫기 버튼
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(AppIcons.cancel, color: AppColors.textColorWhite, size: 24.sp, semanticLabel: '닫기'),
                  ),
                  SizedBox(height: 40.h),

                  /// 제목
                  RichText(
                    text: TextSpan(
                      style: CustomTextStyles.h1.copyWith(height: 1.2),
                      children: [
                        TextSpan(
                          text: widget.opponentNickname,
                          style: CustomTextStyles.h1.copyWith(color: AppColors.primaryYellow, height: 1.2),
                        ),
                        const TextSpan(text: '님과의\n교환은 어떠셨나요?'),
                      ],
                    ),
                  ),
                  SizedBox(height: 72.h),

                  /// 만족도 선택 옵션
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

  /// 만족도 옵션 위젯
  Widget _buildRatingOption(TradeReviewRating rating) {
    return RatingOptionButton(
      rating: rating,
      isSelected: _rating == rating,
      onTap: () => setState(() => _rating = rating),
    );
  }

  // ── 2단계: 칭찬 태그(별로예요는 없음) + 한마디 ─────────────────────────

  Widget _buildStep2() {
    final rating = _rating!;
    final isBadRating = rating == TradeReviewRating.bad;
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
                        child: const Icon(Icons.arrow_back_ios, color: AppColors.textColorWhite),
                      ),
                      SizedBox(height: 40.h),
                      Text(
                        isBadRating ? '어떤 점이 아쉬웠나요?' : '어떤 점이 좋았나요?',
                        style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 24.h),
                      ...availableReviewTags(rating).map((tag) => _buildTagRow(tag)),
                      SizedBox(height: 16.h),
                      Text('한마디를 남겨주세요', style: CustomTextStyles.h3),
                      SizedBox(height: 16.h),
                      TradeReviewCommentField(
                        controller: _commentController,
                        hintText: isBadRating ? '아쉬웠던 점을 남겨주세요' : '매너 있는 교환 파트너를 칭찬해주세요',
                        // 완료 버튼 활성·글자 수 표시 갱신
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 172.h),
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
                      enabledOnPressed: _onSkipPressed,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CompletionButton(
                      isEnabled: _hasReviewDetails,
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
