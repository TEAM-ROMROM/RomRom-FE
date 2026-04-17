import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 교환 완료 후 리뷰 작성 화면
class TradeReviewScreen extends StatefulWidget {
  final String tradeRequestHistoryId;
  final String opponentNickname;

  const TradeReviewScreen({super.key, required this.tradeRequestHistoryId, required this.opponentNickname});

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
          reviewComment: skipDetails
              ? null
              : _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
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

                  /// 닫기 버튼
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(AppIcons.cancel, color: Colors.white, size: 24.sp),
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
    final isSelected = _rating == rating;
    return GestureDetector(
      onTap: () => setState(() => _rating = rating),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 010.w),
        child: Column(
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? rating.selectedBackgroundColor : AppColors.reviewRatingUnselectedBackground,
              ),
              child: Center(
                child: ClipOval(
                  child: SvgPicture.asset(isSelected ? rating.selectedImgAsset : rating.unselectedImgAsset),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              rating.label,
              style: CustomTextStyles.h3.copyWith(
                color: isSelected ? rating.selectedColor : AppColors.reviewRatingUnselected,
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
                      SizedBox(height: 16.h),
                      Text('한마디를 남겨주세요', style: CustomTextStyles.h3),
                      SizedBox(height: 16.h),
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
                      isEnabled: _selectedTags.isNotEmpty,
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
