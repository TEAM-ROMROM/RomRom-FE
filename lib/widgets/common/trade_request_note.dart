import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 요청 카드 부가 정보: 추가금 금액 + 한 줄 메시지 (둘 다 없으면 표시 없음, #1005)
class TradeRequestNote extends StatelessWidget {
  final int? extraChargeAmount;
  final String? requestMessage;

  const TradeRequestNote({super.key, required this.extraChargeAmount, required this.requestMessage});

  bool get _hasRequestMessage => requestMessage?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    if (extraChargeAmount == null && !_hasRequestMessage) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (extraChargeAmount != null)
          Text(
            '추가금 ${formatPrice(extraChargeAmount!)}원',
            style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryYellow),
          ),
        if (extraChargeAmount != null && _hasRequestMessage) const SizedBox(height: 4),
        if (_hasRequestMessage)
          Text(
            '"${requestMessage!.trim()}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity80White),
          ),
      ],
    );
  }
}
