import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 디버그 메뉴 항목 정의
class DebugMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const DebugMenuItem({required this.label, required this.icon, this.onTap, this.enabled = true});
}

/// 디버그 메뉴 팝업 패널
/// 플로팅 버튼 탭 시 표시되는 메뉴 목록
class DebugMenuPanel extends StatelessWidget {
  final List<DebugMenuItem> items;
  final VoidCallback onClose;
  final double x;
  final double y;

  const DebugMenuPanel({super.key, required this.items, required this.onClose, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const menuWidth = 180.0;
    final menuHeight = items.length * 48.0 + 16;
    final menuX = (x - menuWidth - 8).clamp(8.0, screenSize.width - menuWidth - 8);
    final menuY = (y - menuHeight / 2).clamp(8.0, screenSize.height - menuHeight - 8);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(onTap: onClose, behavior: HitTestBehavior.opaque, child: const SizedBox.expand()),
        ),
        Positioned(
          left: menuX,
          top: menuY,
          child: Container(
            width: menuWidth,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondaryBlack2, width: 1),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: items.map((item) => _buildMenuItem(item)).toList()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(DebugMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () {
                onClose();
                item.onTap?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.enabled ? AppColors.primaryYellow : AppColors.secondaryBlack2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(color: item.enabled ? Colors.white : AppColors.secondaryBlack2, fontSize: 14),
                ),
              ),
              if (!item.enabled) const Text('추후', style: TextStyle(color: AppColors.secondaryBlack2, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
