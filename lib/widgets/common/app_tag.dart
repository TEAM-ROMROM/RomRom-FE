import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 공통 태그: 배경 박스(색·모서리) + 라벨 한 줄
/// 크기·패딩·글자 스타일은 호출부 지정 (사용감·거래 옵션·거래 상태 태그 공용)
class AppTag extends StatelessWidget {
  final String label;
  final TextStyle textStyle;
  final Color backgroundColor;
  // 모서리 반경 (화면 배율 적용된 값)
  final double borderRadius;
  final double? width;
  final double? height;
  // 최소 크기 (라벨이 길면 늘어남)
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final TextAlign? textAlign;

  const AppTag({
    super.key,
    required this.label,
    required this.textStyle,
    required this.backgroundColor,
    required this.borderRadius,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.alignment,
    this.textAlign,
  });

  /// 거래 상태 크기 태그 (60x23, 10sp): 채팅 중·교환완료·예약중·보낸 요청 진행 공용 ([textColor] null > p3 기본색)
  factory AppTag.tradeState({Key? key, required String label, required Color backgroundColor, Color? textColor}) {
    return AppTag(
      key: key,
      label: label,
      alignment: Alignment.center,
      width: 60.w,
      height: 23.h,
      borderRadius: 4.r,
      backgroundColor: backgroundColor,
      textStyle: CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(borderRadius)),
      child: Text(label, style: textStyle, textAlign: textAlign),
    );
  }
}
