import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';

/// 접힌 줄 수를 넘는 본문만 펼치기·접기 (화살표 회전 표시), 안 넘치면 탭을 부모에 전달
/// 사용처: 프로필 후기 코멘트(본문 전체 탭), 알림함 공지 본문(화살표만 탭 > 본문 탭은 항목 탭)
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int collapsedMaxLines;
  // true면 화살표 영역(44px)만 펼치기, 본문 탭은 부모(항목 탭)로 전달
  final bool isToggleOnArrowOnly;

  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.collapsedMaxLines = 2,
    this.isToggleOnArrowOnly = false,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 접힌 줄 수 초과 여부 (글자 크기 배율 반영)
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.collapsedMaxLines,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = textPainter.didExceedMaxLines;
        textPainter.dispose();

        final body = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedSize(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                alignment: Alignment.topLeft,
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isOverflowing) _buildToggleArrow(),
          ],
        );
        if (!isOverflowing || widget.isToggleOnArrowOnly) return body;

        return Semantics(
          button: true,
          hint: _isExpanded ? '접기' : '펼치기',
          child: GestureDetector(onTap: _toggleExpanded, behavior: HitTestBehavior.opaque, child: body),
        );
      },
    );
  }

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

  /// 펼침 화살표 (화살표만 탭 모드 > 44px 터치 영역 + 화면낭독기 버튼)
  Widget _buildToggleArrow() {
    final arrow = AnimatedRotation(
      turns: _isExpanded ? -0.5 : 0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.opacity60White),
    );
    if (!widget.isToggleOnArrowOnly) {
      return Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: arrow,
      );
    }
    return Semantics(
      button: true,
      label: _isExpanded ? '접기' : '펼치기',
      child: GestureDetector(
        onTap: _toggleExpanded,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Align(alignment: Alignment.bottomRight, child: arrow),
        ),
      ),
    );
  }
}
