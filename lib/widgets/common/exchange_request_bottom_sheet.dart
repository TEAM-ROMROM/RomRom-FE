import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 교환 완료 요청 바텀시트
class ExchangeRequestBottomSheet {
  const ExchangeRequestBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required ChatRoom chatRoom,
    required String myMemberId,
    required VoidCallback onConfirm,
  }) {
    final history = chatRoom.tradeRequestHistory;
    if (history == null) return Future.value();

    // 내 물건 vs 상대방 물건 결정
    final isMyTakeItem = history.takeItem.member?.memberId == myMemberId;
    final opponentItem = isMyTakeItem ? history.giveItem : history.takeItem;
    final myItem = isMyTakeItem ? history.takeItem : history.giveItem;

    return NotificationBottomSheet.show(
      context: context,
      title: Text('교환을 완료할까요?', style: NotificationBottomSheet.titleStyle),
      description: Text(
        '교환한 물건이 맞는지 확인 후 요청해주세요!\n승인 요청 후에는 물건 상태 변경이 불가능해요.',
        style: NotificationBottomSheet.descriptionStyle,
      ),
      body: _ExchangeRequestBody(opponentItem: opponentItem, myItem: myItem),
      buttonText1: '취소',
      buttonText2: '확인',
      onButton1: () {},
      onButton2: onConfirm,
    );
  }
}

class _ExchangeRequestBody extends StatelessWidget {
  final Item opponentItem;
  final Item myItem;

  const _ExchangeRequestBody({required this.opponentItem, required this.myItem});

  String _categoryLabel(String? serverName) {
    if (serverName == null) return '';
    try {
      return ItemCategories.fromServerName(serverName).label;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 55.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ItemColumn(item: opponentItem, categoryLabel: _categoryLabel(opponentItem.itemCategory)),
              ),
              // 카드 높이(165) 기준으로 아이콘 세로 중앙 정렬
              SizedBox(
                height: 165,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: AppColors.secondaryBlack1, shape: BoxShape.circle),
                      child: const Icon(AppIcons.change, color: AppColors.primaryYellow, size: 20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ItemColumn(item: myItem, categoryLabel: _categoryLabel(myItem.itemCategory)),
              ),
            ],
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _ItemColumn extends StatelessWidget {
  final Item item;
  final String categoryLabel;

  const _ItemColumn({required this.item, required this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final nickname = item.member?.nickname ?? '알 수 없음';
    final profileUrl = item.member?.profileUrl;
    final isDeletedAccount = item.member?.accountStatus == 'DELETE_ACCOUNT';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestManagementItemCardWidget(
          card: RequestManagementItemCard(
            itemId: item.itemId ?? '',
            imageUrl: item.primaryImageUrl ?? '',
            category: categoryLabel,
            title: item.itemName ?? '아이템',
            price: item.price ?? 0,
            likeCount: item.likeCount ?? 0,
            aiPrice: item.isAiPredictedPrice ?? false,
          ),
          width: 110,
          height: 165,
          isActive: true,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            UserProfileCircularAvatar(
              avatarSize: const Size(20, 20),
              profileUrl: profileUrl,
              hasBorder: false,
              isDeleteAccount: isDeletedAccount,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                nickname,
                style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
