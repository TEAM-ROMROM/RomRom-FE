import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';

/// 채팅방 상단 거래 아이템 정보 카드
class ChatTradeInfoCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final String myMemberId;

  const ChatTradeInfoCard({super.key, required this.chatRoom, required this.myMemberId});

  @override
  Widget build(BuildContext context) {
    final isMyTakeItem = chatRoom.tradeRequestHistory?.takeItem.member?.memberId == myMemberId;
    final targetItem = isMyTakeItem ? chatRoom.tradeRequestHistory?.giveItem : chatRoom.tradeRequestHistory?.takeItem;
    final myItem = isMyTakeItem ? chatRoom.tradeRequestHistory?.takeItem : chatRoom.tradeRequestHistory?.giveItem;
    final tradeOptions = chatRoom.tradeRequestHistory?.itemTradeOptions ?? [];

    return Container(
      padding: EdgeInsets.only(top: 0.h, bottom: 16.h, left: 16.w, right: 16.w),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        border: Border(bottom: BorderSide(color: AppColors.opacity10White, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToItem(
              context,
              itemId: targetItem?.itemId,
              isMyItem: false,
              heroTag: 'first_item_${targetItem?.itemId}',
              imageUrl: targetItem?.primaryImageUrl,
            ),
            child: CachedImage(
              imageUrl: targetItem?.primaryImageUrl ?? '',
              width: 48.w,
              height: 48.w,
              borderRadius: BorderRadius.circular(8.r),
              errorWidget: const SizedBox.shrink(),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 3.h),
                Text(
                  targetItem?.itemName ?? '제목 없음',
                  style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  '${formatPrice(targetItem?.price ?? 0)}원',
                  style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tradeOptions.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: tradeOptions.map((serverName) {
                      try {
                        return Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: RequestManagementTradeOptionTag(option: ItemTradeOption.fromServerName(serverName)),
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _navigateToItem(
              context,
              itemId: myItem?.itemId,
              isMyItem: true,
              heroTag: 'first_item_${myItem?.itemId}',
              imageUrl: myItem?.itemImages?.first.imageUrl,
            ),
            child: CachedImage(
              imageUrl: myItem?.itemImages?.first.imageUrl ?? '',
              width: 48.w,
              height: 48.w,
              borderRadius: BorderRadius.circular(8.r),
              errorWidget: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToItem(
    BuildContext context, {
    required String? itemId,
    required bool isMyItem,
    required String heroTag,
    String? imageUrl,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: itemId ?? '',
        imageSize: Size(screenWidth, screenWidth),
        currentImageIndex: 0,
        heroTag: heroTag,
        isMyItem: isMyItem,
        isRequestManagement: false,
      ),
    );
  }
}
