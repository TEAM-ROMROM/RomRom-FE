import 'package:flutter/material.dart';

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
