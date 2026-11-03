import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/trade_request_text_action_button.dart';

/// 교환 요청 존재 안내: 문구 + 이동·재시도 버튼 (거래 방식 선택 탭과 같은 최소 높이)
class TradeRequestExistenceNotice extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onActionTap;

  const TradeRequestExistenceNotice({
    super.key,
    required this.message,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 90.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TradeRequestTextActionButton(text: actionText, onTap: onActionTap),
        ],
      ),
    );
  }
}
