import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/price_comma_format_utils.dart';
import 'package:romrom_fe/utils/trade_request_input_rules.dart';

// 추가금 입력 최대 자릿수 (10,000,000원 = 8자리, 초과 금액은 전송 전 검증)
const int _extraChargeAmountMaxDigitCount = 8;

/// 요청하기 부가 입력: 추가금 금액 (추가금 방식 선택 시만) + 한 줄 메시지 (#1005)
class TradeRequestExtraInputs extends StatelessWidget {
  // 추가금 방식 선택 여부 (금액 칸 노출)
  final bool isExtraChargeSelected;
  final TextEditingController extraChargeAmountController;
  final TextEditingController requestMessageController;

  const TradeRequestExtraInputs({
    super.key,
    required this.isExtraChargeSelected,
    required this.extraChargeAmountController,
    required this.requestMessageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.primaryBlack, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExtraChargeSelected) ...[
            _buildLabel('추가금 (선택)'),
            _buildInputBox(
              child: TextField(
                controller: extraChargeAmountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_extraChargeAmountMaxDigitCount),
                  const PriceCommaFormatter(),
                ],
                style: CustomTextStyles.p2,
                cursorColor: AppColors.textColorWhite,
                decoration: _buildDecoration(hintText: '금액 입력', suffixText: '원'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildLabel('한 줄 메시지 (선택)'),
          _buildInputBox(
            child: TextField(
              controller: requestMessageController,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                // 한 줄 유지: 줄바꿈 입력 차단
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                LengthLimitingTextInputFormatter(tradeRequestMessageMaxLength),
              ],
              style: CustomTextStyles.p2,
              cursorColor: AppColors.textColorWhite,
              decoration: _buildDecoration(hintText: '상대에게 남길 말을 적어주세요'),
            ),
          ),
          const SizedBox(height: 4),
          _buildMessageCounter(),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity50White),
      ),
    );
  }

  // 입력 상자: 고정 px 여백 (iPad 비율 확대 시 높이 넘침 방지)
  Widget _buildInputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(8.r)),
      child: child,
    );
  }

  InputDecoration _buildDecoration({required String hintText, String? suffixText}) {
    return InputDecoration(
      isCollapsed: true,
      border: InputBorder.none,
      hintText: hintText,
      hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
      suffixText: suffixText,
      suffixStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
    );
  }

  // 글자 수 표시 (입력마다 갱신)
  Widget _buildMessageCounter() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: requestMessageController,
      builder: (context, messageValue, _) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${messageValue.text.characters.length}/$tradeRequestMessageMaxLength',
          style: CustomTextStyles.p3.copyWith(color: AppColors.opacity40White),
        ),
      ),
    );
  }
}
