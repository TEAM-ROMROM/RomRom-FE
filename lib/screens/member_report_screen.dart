import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/enums/member_report_reason.dart';
import 'package:romrom_fe/services/apis/report_api.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 회원 신고하기 페이지
class MemberReportScreen extends StatefulWidget {
  final String memberId; // 신고 대상 회원 ID

  const MemberReportScreen({super.key, required this.memberId});

  @override
  State<MemberReportScreen> createState() => _MemberReportScreenState();
}

class _MemberReportScreenState extends State<MemberReportScreen> {
  // 선택된 신고 사유 집합
  final Set<MemberReportReason> _selectedReasons = {};
  late final TextEditingController _extraCommentController;
  bool _isSubmitting = false;

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
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 바닥 고정 (버튼 위치 유지)
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '신고하기',
        onBackPressed: () {
          Navigator.of(context).pop();
        },
        showBottomBorder: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.h),
                    Text(
                      '신고 사유',
                      style: CustomTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // 신고 사유 리스트
                    ...MemberReportReason.values.map(
                      (reason) => _buildReasonRow(reason),
                    ),
                    if (_selectedReasons.contains(MemberReportReason.etc)) ...[
                      Container(
                        width: 345.w,
                        height: 140.h,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBlack1,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.textColorWhite.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.5.w,
                          ),
                        ),
                        child: TextField(
                          controller: _extraCommentController,
                          maxLines: null,
                          maxLength: 300,
                          style: CustomTextStyles.p2,
                          cursorColor: AppColors.textColorWhite,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            counterText: '', // 기본 counter 숨김
                            hintText: '신고 사유를 상세하게 적어주세요',
                            hintStyle: CustomTextStyles.p2.copyWith(
                              color: AppColors.textColorWhite.withValues(
                                alpha: 0.4,
                              ),
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
                            color: AppColors.textColorWhite.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // 하단 버튼과 겹치지 않도록 여백 추가
                    SizedBox(height: 180.h),
                  ],
                ),
              ),
            ),
          ),

          // 하단 고정 신고하기 버튼 (bottom 기준 97.h)
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: 97.h,
            child: CompletionButton(
              isEnabled: _selectedReasons.isNotEmpty,
              isLoading: _isSubmitting,
              buttonText: '신고 하기',
              enabledOnPressed: () async {
                if (_isSubmitting) return;
                setState(() => _isSubmitting = true);
                try {
                  final api = ReportApi();
                  await api.reportMember(
                    targetMemberId: widget.memberId,
                    memberReportReasons: _selectedReasons
                        .map((e) => e.id)
                        .toSet(),
                    extraComment: _extraCommentController.text.trim(),
                  );
                } catch (e) {
                  debugPrint('회원 신고 요청 중 오류: $e');
                  // 에러 코드 파싱
                  final messageForUser = ErrorUtils.getErrorMessage(e);

                  if (!mounted) return;
                  await CommonModal.error(
                    context: context,
                    message: messageForUser,
                    onConfirm: () => Navigator.of(context).pop(),
                  );
                  return;
                } finally {
                  if (mounted) {
                    setState(() => _isSubmitting = false);
                  }
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

  /// 신고 사유 선택/해제 토글
  void _toggleReason(MemberReportReason reason) {
    setState(() {
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else {
        _selectedReasons.add(reason);
      }
    });
  }

  /// 신고 사유 행
  Widget _buildReasonRow(MemberReportReason reason) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleReason(reason),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Checkbox(
                value: _selectedReasons.contains(reason),
                onChanged: (_) => _toggleReason(reason),
                activeColor: AppColors.primaryYellow,
                checkColor: AppColors.primaryBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                side: BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(reason.label, style: CustomTextStyles.h3)),
          ],
        ),
      ),
    );
  }
}
