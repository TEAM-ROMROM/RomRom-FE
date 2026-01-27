import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 요청 목록 아이템 카드 위젯
class RequestListItemCardWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String address;
  final DateTime createdDate;
  final bool isNew; // 새로운 요청 여부
  final List<ItemTradeOption> tradeOptions;
  final TradeStatus tradeStatus;
  final VoidCallback onMenuTap;

  const RequestListItemCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.address,
    required this.createdDate,
    this.isNew = false,
    required this.tradeOptions,
    required this.tradeStatus,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 345.w,
      height: 70.h,
      child: Row(
        children: [
          // 이미지 (왼쪽, 위, 아래 12px 마진)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: _buildImage(imageUrl),
              ),
            ),
          ),
          // 정보 영역
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽 영역 (제목 + 주소 + 시간 + 거래 옵션 태그)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 제목 (7자 제한)
                          Text(
                            title.length > 8
                                ? '${title.substring(0, 8)}...'
                                : title,
                            style: CustomTextStyles.p1.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isNew) ...[
                            SizedBox(width: 8.w),
                            SvgPicture.asset(
                              'assets/images/redNew.svg',
                              width: 16.w,
                              height: 16.h,
                            ),
                          ],
                        ],
                      ),

                      SizedBox(
                        height: 8.h,
                      ),

                      Row(
                        children: [
                          // 주소
                          Text(
                            address,
                            style: CustomTextStyles.p3.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.opacity60White,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // 중간점
                          Container(
                            width: 2.w,
                            height: 2.h,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.opacity60White,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // 시간
                          Text(
                            getTimeAgo(createdDate),
                            style: CustomTextStyles.p3.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.opacity60White,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 11.h,
                      ),

                      // 거래 옵션 태그들 (줄바꿈 방지)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: tradeOptions
                                .map(
                                  (option) => Padding(
                                    padding: EdgeInsets.only(right: 4.w),
                                    child: RequestManagementTradeOptionTag(
                                        option: option),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 오른쪽 메뉴 버튼
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 메뉴 아이콘
                      RomRomContextMenu(
                        items: [
                          ContextMenuItem(
                            id: 'delete',
                            svgAssetPath: 'assets/images/trashRed.svg',
                            title: '삭제',
                            textColor: AppColors.itemOptionsMenuDeleteText,
                            onTap: onMenuTap,
                          ),
                        ],
                      ),

                      // 거래 상태 태그
                      TradeStatusTagWidget(status: tradeStatus),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 로드 위젯
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
}
