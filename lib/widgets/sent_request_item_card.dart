import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

class SentRequestItemCard extends StatelessWidget {
  final String myItemImageUrl;
  final String otherItemImageUrl;
  final String otherUserProfileUrl;
  final String title;
  final String location;
  final DateTime createdDate;
  final List<ItemTradeOption> tradeOptions;
  final TradeStatus? tradeStatus;
  final VoidCallback? onMenuTap;

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
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 191.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppColors.secondaryBlack,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 상단 이미지 영역
              SizedBox(
                height: 88.h,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        // 내 물건 이미지 (왼쪽)
                        Expanded(
                          child: Container(
                            height: 88.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.r),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.r),
                              ),
                              child: _buildImage(myItemImageUrl),
                            ),
                          ),
                        ),
                        // 상대방 물건 이미지 (오른쪽)
                        Expanded(
                          child: Container(
                            height: 88.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10.r),
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10.r),
                                  ),
                                  child: _buildImage(otherItemImageUrl),
                                ),
                                // 상대방 프로필 이미지
                                Positioned(
                                  bottom: 8.h,
                                  right: 8.w,
                                  child: Container(
                                    width: 24.w,
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.secondaryBlack,
                                        width: 1.5.w,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _buildImage(otherUserProfileUrl),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 중앙 교환 아이콘
                    Center(
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryBlack,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
                              <path d="M2 11.5998C2 11.5998 2.09706 12.2792 4.90883 15.091C7.72061 17.9027 12.2794 17.9027 15.0912 15.091C16.0874 14.0948 16.7306 12.8792 17.0209 11.5998M2 11.5998V16.3998M2 11.5998H6.8M18 8.3998C18 8.3998 17.9029 7.72041 15.0912 4.90864C12.2794 2.09686 7.72061 2.09686 4.90883 4.90864C3.91261 5.90486 3.26936 7.12038 2.97906 8.3998M18 8.3998V3.5998M18 8.3998H13.2" stroke="#FFC300" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>''',
                            width: 20.w,
                            height: 20.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 하단 정보 영역
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        title,
                        style: CustomTextStyles.p2.copyWith(
                          color: AppColors.textColorWhite,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      // 위치 · 시간
                      Row(
                        children: [
                          Text(
                            location,
                            style: CustomTextStyles.p3.copyWith(
                              color: AppColors.opacity60White,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            ' · ',
                            style: CustomTextStyles.p3.copyWith(
                              color: AppColors.opacity60White,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _getTimeAgo(createdDate),
                            style: CustomTextStyles.p3.copyWith(
                              color: AppColors.opacity60White,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // 태그 영역
                      Row(
                        children: [
                          // 거래 옵션 태그들
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: tradeOptions.map(
                                  (option) => Padding(
                                    padding: EdgeInsets.only(right: 4.w),
                                    child: RequestManagementTradeOptionTag(option: option),
                                  ),
                                ).toList(),
                              ),
                            ),
                          ),
                          // 채팅중 버튼 (조건부)
                          if (tradeStatus == TradeStatus.chatting) ...[
                            SizedBox(width: 8.w),
                            TradeStatusTagWidget(status: tradeStatus!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 우측 상단 메뉴 아이콘
          Positioned(
            top: 16.h,
            right: 12.w,
            child: RomRomContextMenu(
              items: [
                ContextMenuItem(
                  id: 'edit',
                  title: '수정',
                  onTap: () {
                    // 수정 액션
                  },
                ),
                ContextMenuItem(
                  id: 'cancel',
                  title: '요청 취소',
                  onTap: () {
                    // 요청 취소 액션
                  },
                  textColor: AppColors.warningRed,
                ),
              ],
              customTrigger: Icon(
                Icons.more_vert,
                size: 24.w,
                color: AppColors.opacity60White,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime createdDate) {
    final now = DateTime.now();
    final difference = now.difference(createdDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const ErrorImagePlaceholder();
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const ErrorImagePlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.opacity20White,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryYellow,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}