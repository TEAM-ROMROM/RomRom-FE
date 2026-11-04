// 회원 탈퇴 사유 영역: 사유 단일 선택 목록, 상세 사유 입력(선택, 글자 수 표시)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/member_withdrawal_reason.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 탈퇴 사유 선택·상세 입력 (선택 상태는 화면이 소유)
class MemberWithdrawalReasonSection extends StatelessWidget {
  // 상세 사유 최대 글자 수 (서버 TOO_LONG_WITHDRAWAL_REASON_DETAIL 기준 500자)
  static const int maximumReasonDetailLength = 500;
  static const String title = '탈퇴하는 이유를 알려주세요';
  static const String reasonDetailHintText = '더 자세한 이유가 있다면 적어주세요 (선택)';

  final MemberWithdrawalReason? selectedReason;
  final ValueChanged<MemberWithdrawalReason> onReasonSelected;
  final TextEditingController reasonDetailController;
  final bool isEnabled;

  const MemberWithdrawalReasonSection({
    super.key,
    required this.selectedReason,
    required this.onReasonSelected,
    required this.reasonDetailController,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        for (final reason in MemberWithdrawalReason.values) _buildReasonRow(reason),
        SizedBox(height: 12.h),
        _buildReasonDetailField(),
      ],
    );
  }

  /// 사유 한 줄 (행 전체 탭, 화면낭독기 선택 상태)
  Widget _buildReasonRow(MemberWithdrawalReason reason) {
    final isSelected = reason == selectedReason;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? () => onReasonSelected(reason) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? AppColors.primaryYellow : AppColors.opacity40White,
                semanticLabel: isSelected ? '선택됨' : '선택 안 됨',
              ),
              SizedBox(width: 12.w),
              Expanded(child: Text(reason.label, style: CustomTextStyles.p2)),
            ],
          ),
        ),
      ),
    );
  }

  /// 상세 사유 입력 (선택, 글자 수 표시)
  Widget _buildReasonDetailField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: reasonDetailController,
            enabled: isEnabled,
            minLines: 3,
            maxLines: 5,
            maxLength: maximumReasonDetailLength,
            style: CustomTextStyles.p2,
            cursorColor: AppColors.textColorWhite,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: '',
              hintText: reasonDetailHintText,
              hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: reasonDetailController,
            builder: (context, reasonDetailValue, _) => Text(
              '${reasonDetailValue.text.length}/$maximumReasonDetailLength',
              textAlign: TextAlign.right,
              style: CustomTextStyles.p3.copyWith(color: AppColors.opacity50White),
            ),
          ),
        ],
      ),
    );
  }
}
