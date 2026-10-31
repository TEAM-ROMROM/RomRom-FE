// 물품 상세 우측 상단 액션 (Stack 상단 고정): 공유 버튼 + (타인 물품) 신고 메뉴 / (내 물품) 상태 변경·수정·삭제 메뉴
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_circle_icon_button.dart';

class ItemDetailTopActions extends StatelessWidget {
  final bool isMyItem;
  // 공유 시트 위치 기준 key (화면이 소유)
  final Key shareButtonKey;
  // 현재 교환 가능 상태 여부 (상태 변경 메뉴 문구 분기)
  final bool isAvailableStatus;
  final VoidCallback onSharePressed;
  final VoidCallback onReportPressed;
  final VoidCallback onChangeStatusPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const ItemDetailTopActions({
    super.key,
    required this.isMyItem,
    required this.shareButtonKey,
    required this.isAvailableStatus,
    required this.onSharePressed,
    required this.onReportPressed,
    required this.onChangeStatusPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 신고 버튼(타인 물품)은 터치 영역 확대분만큼 위치 보정 (아이콘 시각 위치 유지)
      top: MediaQuery.of(context).padding.top + 8.h - (isMyItem ? 0 : ReportMenuButton.rowTopCompensation(32.w)),
      right: 16.w - (isMyItem ? 0 : ReportMenuButton.tapTargetExtraInset),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemDetailCircleIconButton(
            anchorKey: shareButtonKey,
            icon: AppIcons.share,
            iconSize: 30,
            semanticLabel: '공유',
            onTap: onSharePressed,
          ),
          // 신고 버튼 터치 여백만큼 간격 축소 (작은 화면 음수 폭 방지)
          SizedBox(width: max(0.0, 12.w - (isMyItem ? 0 : ReportMenuButton.tapTargetExtraInset))),
          !isMyItem ? ReportMenuButton(onReportPressed: onReportPressed) : _buildMyItemMenu(),
        ],
      ),
    );
  }

  /// 내 물품 메뉴 3개: 상태 변경, 수정, 삭제
  Widget _buildMyItemMenu() {
    return RomRomContextMenu(
      items: [
        ContextMenuItem(
          id: 'changeTradeStatus',
          icon: AppIcons.change,
          title: isAvailableStatus ? '교환완료로 변경' : '교환 가능으로 변경',
          onTap: onChangeStatusPressed,
          showDividerAfter: true,
        ),
        ContextMenuItem(id: 'edit', icon: AppIcons.edit, title: '수정', onTap: onEditPressed, showDividerAfter: true),
        ContextMenuItem(
          id: 'delete',
          icon: AppIcons.trash,
          iconColor: AppColors.itemOptionsMenuRedIcon,
          title: '삭제',
          textColor: AppColors.itemOptionsMenuRedText,
          onTap: onDeletePressed,
        ),
      ],
    );
  }
}
