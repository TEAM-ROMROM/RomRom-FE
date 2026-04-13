import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ItemColumn(item: opponentItem)),
                  const SizedBox(width: 40),
                  Expanded(child: _ItemColumn(item: myItem)),
                ],
              ),
              // 중앙 교환 아이콘
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
                child: const Icon(AppIcons.change, color: AppColors.primaryBlack, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ItemColumn extends StatelessWidget {
  final Item item;

  const _ItemColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    final nickname = item.member?.nickname ?? '알 수 없음';
    final profileUrl = item.member?.profileUrl;
    final isDeletedAccount = item.member?.accountStatus == 'DELETE_ACCOUNT';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ItemCard(item: item),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UserProfileCircularAvatar(
              avatarSize: const Size(24, 24),
              profileUrl: profileUrl,
              hasBorder: false,
              isDeleteAccount: isDeletedAccount,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                nickname,
                style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
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

class _ItemCard extends StatelessWidget {
  final Item item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.primaryImageUrl ?? '';
    final category = item.itemCategory ?? '';
    final title = item.itemName ?? '제목 없음';
    final price = item.price ?? 0;
    final likeCount = item.likeCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: const [BoxShadow(color: AppColors.itemCardShadow, offset: Offset(4, 4), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl.isEmpty
                  ? const ErrorImagePlaceholder()
                  : CachedImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: const ErrorImagePlaceholder()),
            ),
          ),

          // 정보 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리
                Text(
                  category,
                  style: CustomTextStyles.p4.copyWith(color: AppColors.itemCardCategoryText, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // 제목
                Text(
                  title,
                  style: CustomTextStyles.p3.copyWith(
                    color: AppColors.itemCardNameText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // 가격 + 좋아요
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '${formatPrice(price)}원',
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.itemCardPriceText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(AppIcons.itemRegisterHeart, size: 12, color: AppColors.itemCardLikeText),
                    const SizedBox(width: 3),
                    Text(
                      '$likeCount',
                      style: CustomTextStyles.p4.copyWith(
                        color: AppColors.itemCardLikeText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
