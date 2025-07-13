import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/enums/item_report_reason.dart';
import 'package:romrom_fe/services/apis/report_api.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_fail_modal.dart';

/// 신고하기 페이지
class ReportScreen extends StatefulWidget {
  final String itemId; // 신고 대상 아이템 ID

  const ReportScreen({super.key, required this.itemId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // 선택된 신고 사유 집합
  final Set<ItemReportReason> _selectedReasons = {};
  late final TextEditingController _extraCommentController;

  @override
  void initState() {
    super.initState();
    _extraCommentController = TextEditingController();
    _extraCommentController.addListener(() {
      setState(() {}); // 글자 수 반영용
    });
  }

  @override
  void dispose() {
    _extraCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태바 색상을 primaryBlack 로 설정 (iOS 기준 44px 영역)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: AppColors.primaryBlack),
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: AppBar(
          backgroundColor: AppColors.primaryBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textColorWhite, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            '신고하기',
            style: CustomTextStyles.h1, // 24px, 600, 흰색
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Text(
                  '신고 사유',
                  style: CustomTextStyles.h3, // 18px, 500, 흰색
                ),
                SizedBox(height: 24.h),
                // 신고 사유 리스트
                ...ItemReportReason.values.map((reason) => _buildReasonRow(reason)),
                if (_selectedReasons.contains(ItemReportReason.etc)) ...[
                  SizedBox(height: 24.h),
                  Container(
                    width: 345.w,
                    height: 140.h,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlack,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.textColorWhite.withValues(alpha: 0.3),
                        width: 1.5.w,
                      ),
                    ),
                    child: TextField(
                      controller: _extraCommentController,
                      maxLines: null,
                      maxLength: 300,
                      style: CustomTextStyles.p2.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                      cursorColor: AppColors.textColorWhite,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        counterText: '', // 기본 counter 숨김
                        hintText: '신고 사유를 상세하게 적어주세요',
                        hintStyle: CustomTextStyles.p2.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColorWhite.withValues(alpha: 0.4),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_extraCommentController.text.length}/300',
                      style: CustomTextStyles.p3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColorWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 하단 고정 신고하기 버튼 (bottom 기준 76px)
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: 76.h,
            child: CompletionButton(
              isEnabled: _selectedReasons.isNotEmpty,
              buttonText: '신고 하기',
              buttonType: 2,
              enabledOnPressed: () async {
                try {
                  final api = ReportApi();
                  await api.reportItem(
                    itemId: widget.itemId,
                    itemReportReasons:
                        _selectedReasons.map((e) => e.id).toSet(),
                    extraComment: _extraCommentController.text.trim(),
                  );
                } catch (e) {
                  debugPrint('신고 요청 중 오류: $e');
                  // 에러 코드 파싱
                  final messageForUser = ErrorUtils.getErrorMessage(e);

                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => CommonFailModal(
                      message: messageForUser,
                      onConfirm: () => Navigator.of(context).pop(),
                    ),
                  );
                  return;
                }

                if (!mounted) return;

                Navigator.of(context).pop(true); // 성공 결과 반환
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 신고 사유 행
  Widget _buildReasonRow(ItemReportReason reason) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: Checkbox(
              value: _selectedReasons.contains(reason),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedReasons.add(reason);
                  } else {
                    _selectedReasons.remove(reason);
                  }
                });
              },
              activeColor: AppColors.primaryYellow,
              checkColor: AppColors.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              side: BorderSide(
                color: AppColors.primaryYellow,
                width: 1.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              reason.name,
              style: CustomTextStyles.p1.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 