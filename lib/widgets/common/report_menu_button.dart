import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 신고하기 메뉴 버튼 (우측 상단 점 3개 아이콘)
class ReportMenuButton extends StatelessWidget {
  final VoidCallback? onReportPressed;

  const ReportMenuButton({super.key, this.onReportPressed});

  // 최소 터치 영역 (iOS HIG / Android 접근성 기준 44)
  static const double minimumTapTargetSize = 44;

  // 아이콘 시각 박스 (기존 레이아웃 기준)
  static double get _iconBoxSize => 30.w;

  /// 터치 영역 한 변 (iPad처럼 30.w가 더 크면 30.w)
  static double get tapTargetSize => math.max(minimumTapTargetSize, _iconBoxSize);

  /// 아이콘 박스 대비 한쪽으로 늘어난 길이 (호출부 위치 보정용)
  static double get tapTargetExtraInset => (tapTargetSize - _iconBoxSize) / 2;

  /// 같은 Row의 형제 높이 기준, 버튼 때문에 늘어난 행 높이의 절반 (top 보정용)
  static double rowTopCompensation(double siblingHeight) =>
      (math.max(siblingHeight, tapTargetSize) - siblingHeight) / 2;

  @override
  Widget build(BuildContext context) {
    return RomRomContextMenu(
      semanticLabel: '신고',
      tapTargetSize: tapTargetSize,
      items: [
        ContextMenuItem(
          id: 'report',
          icon: AppIcons.report,
          title: '신고하기',
          onTap: () {
            if (onReportPressed != null) onReportPressed!();
          },
        ),
      ],
    );
  }
}
