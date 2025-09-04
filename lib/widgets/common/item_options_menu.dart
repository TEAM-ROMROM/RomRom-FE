import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

// 아이템 옵션 메뉴 아이콘 버튼
class ItemOptionsMenuButton extends StatelessWidget {
  final VoidCallback? onStatusChangePressed; // 거래완료로 변경
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const ItemOptionsMenuButton({
    super.key,
    this.onStatusChangePressed,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return RomRomContextMenu(
      items: [
        ContextMenuItem(
          id: 'status_change',
          title: '거래완료로 변경',
          onTap: () {
            if (onStatusChangePressed != null) onStatusChangePressed!();
          },
          showDividerAfter: true,
        ),
        ContextMenuItem(
          id: 'edit',
          title: '수정',
          onTap: () {
            if (onEditPressed != null) onEditPressed!();
          },
          showDividerAfter: true,
        ),
        ContextMenuItem(
          id: 'delete',
          title: '삭제',
          textColor: AppColors.itemOptionsMenuDeleteText,
          onTap: () {
            if (onDeletePressed != null) onDeletePressed!();
          },
        ),
      ],
    );
  }
}
