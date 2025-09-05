import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 신고하기 메뉴 버튼 (우측 상단 점 3개 아이콘)
class ReportMenuButton extends StatelessWidget {
  final VoidCallback? onReportPressed;

  const ReportMenuButton({super.key, this.onReportPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.h,
      width: 30.w,
      child: RomRomContextMenu(
        items: [
          ContextMenuItem(
            id: 'report',
            title: '신고하기',
            onTap: () {
              if (onReportPressed != null) onReportPressed!();
            },
          ),
        ],
      ),
    );
  }
}
