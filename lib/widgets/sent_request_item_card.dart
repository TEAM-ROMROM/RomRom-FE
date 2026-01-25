import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class SentRequestItemCard extends StatelessWidget {
  final String myItemImageUrl;
  final String otherItemImageUrl;
  final String otherUserProfileUrl;
  final String title;
  final String location;
  final DateTime createdDate;
  final List<ItemTradeOption> tradeOptions;
  final TradeStatus? tradeStatus;
  final VoidCallback? onEditTap;
  final VoidCallback? onCancelTap;

  const SentRequestItemCard({
    super.key,
    required this.myItemImageUrl,
    required this.otherItemImageUrl,
    required this.otherUserProfileUrl,
    required this.title,
    required this.location,
    required this.createdDate,
    required this.tradeOptions,
    this.tradeStatus,
    this.onEditTap,
    this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361.w,
      height: 191.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppColors.secondaryBlack1,
      ),
      child: Column(
        children: [
          _buildTopImageSection(), // 상단 이미지 영역
          _buildBottomInfoSection(context), // 하단 정보 영역
        ],
      ),
    );
  }

  /// 상단 이미지 영역
  Widget _buildTopImageSection() {
    return SizedBox(
      height: 88.h,
      child: Stack(
        children: [
          Row(
            children: [
              _buildItemImage(myItemImageUrl, isLeft: true),
              _buildItemImage(otherItemImageUrl, isLeft: false),
            ],
          ),
          _buildCenterExchangeIcon(), // 중앙 교환 아이콘
        ],
      ),
    );
  }

  /// 하단 정보 영역
  Widget _buildBottomInfoSection(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                SizedBox(height: 8.h),
                _buildLocationAndTime(),
                const Spacer(),
                _buildTagsAndStatus(),
              ],
            ),
          ),
          _buildMenuIcon(),
        ],
      ),
    );
  }

  /// 개별 아이템 이미지 빌더
  Widget _buildItemImage(String imageUrl, {required bool isLeft}) {
    return Expanded(
      child: Container(
        height: 88.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? Radius.circular(10.r) : Radius.zero,
            topRight: isLeft ? Radius.zero : Radius.circular(10.r),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: isLeft ? Radius.circular(10.r) : Radius.zero,
                  topRight: isLeft ? Radius.zero : Radius.circular(10.r),
                ),
                child: imageUrl.isEmpty
                    ? const ErrorImagePlaceholder()
                    : CachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: const ErrorImagePlaceholder(),
                      ),
              ),
            ),
            if (!isLeft) _buildProfileImage(),
          ],
        ),
      ),
    );
  }


  /// 중앙 교환 아이콘
  Widget _buildCenterExchangeIcon() {
    return Center(
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondaryBlack1,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/exchangeYellowCircle.svg',
            width: 20.w,
            height: 20.h,
          ),
        ),
      ),
    );
  }

  /// 제목 빌더
  Widget _buildTitle() {
    return Text(
      title,
      style: CustomTextStyles.p2.copyWith(
        color: AppColors.textColorWhite,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 위치와 시간 빌더
  Widget _buildLocationAndTime() {
    return Row(
      children: [
        Text(
          location,
          style: _buildSubTextStyle(),
        ),
        SizedBox(width: 2.w),
        Container(
          width: 2.w,
          height: 2.h,
          decoration: const BoxDecoration(
            color: AppColors.opacity60White,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          getTimeAgo(createdDate),
          style: _buildSubTextStyle(),
        ),
      ],
    );
  }

  /// 거래 옵션 태그와 상태 태그 빌더
  Widget _buildTagsAndStatus() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tradeOptions
                  .map(
                    (option) => Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: RequestManagementTradeOptionTag(option: option),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (tradeStatus == TradeStatus.chatting) ...[
          TradeStatusTagWidget(status: tradeStatus!),
        ],
      ],
    );
  }

  /// 우측 상단 메뉴 아이콘
  Widget _buildMenuIcon() {
    return Positioned(
      top: 16.h,
      right: 9.w,
      child: RomRomContextMenu(
        items: [
          ContextMenuItem(
            id: 'edit',
            svgAssetPath: 'assets/images/editGray.svg',
            title: '수정',
            onTap: () {
              // 수정 액션
              onEditTap?.call();
            },
            showDividerAfter: true,
          ),
          ContextMenuItem(
            id: 'cancel',
            svgAssetPath: 'assets/images/trashRed.svg',
            title: '요청 취소',
            onTap: () {
              // 요청 취소 액션
              onCancelTap?.call();
            },
            textColor: AppColors.warningRed,
          ),
        ],
        customTrigger: Icon(
          Icons.more_vert,
          size: 24.w,
          color: AppColors.textColorWhite,
        ),
      ),
    );
  }

  /// 프로필 이미지 빌더
  Widget _buildProfileImage() {
    return Positioned(
      bottom: 8.h,
      right: 8.w,
      child: Container(
        width: 24.w,
        height: 24.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textColorWhite,
          ),
        ),
        child: ClipOval(
          child: _buildImage(otherUserProfileUrl),
        ),
      ),
    );
  }

  /// 공통 이미지 빌더
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const ErrorImagePlaceholder();
    }

    return CachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: const ErrorImagePlaceholder(),
    );
  }

  /// 공통 서브 텍스트 스타일
  TextStyle _buildSubTextStyle() {
    return CustomTextStyles.p3.copyWith(
      color: AppColors.opacity60White,
      fontWeight: FontWeight.w500,
    );
  }
}
