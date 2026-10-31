// 등록 탭 내 물품 한 줄: 썸네일(Hero), 이름·등록 시각·가격·좋아요 수, 거래 상태 태그, 더보기 메뉴(상태 변경·수정·삭제)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';

/// 등록 탭 물품 행: 물품 요약 표시, 탭·메뉴 동작은 화면 콜백으로 전달
class RegisterTabItemTile extends StatelessWidget {
  final Item item;
  // 교환 가능 탭이면 메뉴 문구 '교환 완료로 변경', 교환 완료 탭이면 '교환 가능으로 변경'
  final bool isSellingTab;
  final VoidCallback onTap;
  final VoidCallback onChangeStatusTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const RegisterTabItemTile({
    super.key,
    required this.item,
    required this.isSellingTab,
    required this.onTap,
    required this.onChangeStatusTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.primaryImageUrl ?? '';
    final uploadTime = item.createdDate != null ? getTimeAgo(item.createdDate!) : '';

    return Stack(
      children: [
        AppPressable(
          onTap: onTap,
          scaleDown: AppPressable.scaleCard,
          enableRipple: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: SizedBox(
                  width: 90.w,
                  height: 90.w,
                  child: item.itemId != null
                      ? Hero(tag: 'itemImage_${item.itemId}_0', child: _buildImage(imageUrl))
                      : _buildImage(imageUrl),
                ),
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.itemName ?? '물품명 없음',
                      style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    if (uploadTime.isNotEmpty)
                      Text(uploadTime, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
                    SizedBox(height: 12.h),
                    Text('${formatPrice(item.price ?? 0)}원', style: CustomTextStyles.p1),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(AppIcons.itemRegisterHeart, size: 14.sp, color: AppColors.opacity60White),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.likeCount ?? 0}',
                          style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: TradeStatusTagWidget(
            status: item.itemStatus == ItemStatus.exchanged.serverName ? TradeStatus.traded : TradeStatus.pending,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SizedBox(
            width: 30.w,
            height: 30.h,
            child: RomRomContextMenu(
              items: [
                ContextMenuItem(
                  id: 'changeTradeStatus',
                  contextIcon: AppIcons.dotsVerticalSmall,
                  icon: AppIcons.change,
                  title: isSellingTab ? '교환 완료로 변경' : '교환 가능으로 변경',
                  onTap: onChangeStatusTap,
                  showDividerAfter: true,
                ),
                ContextMenuItem(
                  id: 'edit',
                  contextIcon: AppIcons.dotsVerticalSmall,
                  icon: AppIcons.edit,
                  title: '수정',
                  onTap: onEditTap,
                  showDividerAfter: true,
                ),
                ContextMenuItem(
                  id: 'delete',
                  contextIcon: AppIcons.dotsVerticalSmall,
                  icon: AppIcons.trash,
                  iconColor: AppColors.itemOptionsMenuRedIcon,
                  title: '삭제',
                  textColor: AppColors.itemOptionsMenuRedText,
                  onTap: onDeleteTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 썸네일: 주소 없으면 플레이스홀더, 로드 실패도 플레이스홀더
  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const ErrorImagePlaceholder();
    }
    return CachedImage(imageUrl: imageUrl.trim(), fit: BoxFit.cover, errorWidget: const ErrorImagePlaceholder());
  }
}
