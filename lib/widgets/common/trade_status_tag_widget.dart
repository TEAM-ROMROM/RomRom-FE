import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 거래 상태 태그 위젯
enum TradeStatus {
  chatting, // 채팅중
  completed, // 거래완료
}

class TradeStatusTagWidget extends StatelessWidget {
  final TradeStatus status;

  const TradeStatusTagWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isChatting = status == TradeStatus.chatting;
    
    return Container(
      width: 60.w,
      height: 23.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: isChatting 
            ? const Color(0x80FFC300) // rgba(255, 195, 0, 0.50)
            : const Color(0xFF1D1E27), // 거래완료 배경색
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isChatting ? 15.5.w : 11.5.w,
        vertical: 6.5.h,
      ),
      alignment: Alignment.center,
      child: Text(
        isChatting ? '채팅중' : '거래 완료',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Pretendard',
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}