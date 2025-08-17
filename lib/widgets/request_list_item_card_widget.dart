import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/trade_option_tag_widget.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag_widget.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

/// 요청 목록 아이템 카드 위젯
class RequestListItemCardWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String address;
  final DateTime createdDate;
  final bool isNew; // 새로운 요청 여부
  final List<ItemTradeOption> tradeOptions;
  final TradeStatus tradeStatus;
  final VoidCallback? onMenuTap;

  const RequestListItemCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.address,
    required this.createdDate,
    this.isNew = false,
    required this.tradeOptions,
    required this.tradeStatus,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361.w,
      height: 84.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppColors.secondaryBlack,
      ),
      child: Row(
        children: [
          // 이미지
          Container(
            width: 84.w,
            height: 84.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
              child: _buildImage(imageUrl),
            ),
          ),
          // 정보 영역
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 영역
                  Row(
                    children: [
                      // 제목
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 주소
                      Text(
                        address,
                        style: TextStyle(
                          color: const Color(0x99FFFFFF), // rgba(255, 255, 255, 0.60)
                          fontFamily: 'Pretendard',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // 중간점
                      Container(
                        width: 2.w,
                        height: 2.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // 시간
                      Text(
                        _getTimeAgo(createdDate),
                        style: TextStyle(
                          color: const Color(0x99FFFFFF),
                          fontFamily: 'Pretendard',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      // FIXME: 백엔드에서 isNew 구현 후 연결
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
                  const Spacer(),
                  // 하단 태그 영역
                  Row(
                    children: [
                      // 거래 옵션 태그들
                      ...tradeOptions.map(
                        (option) => Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: TradeOptionTagWidget(option: option),
                        ),
                      ),
                      const Spacer(),
                      // 거래 상태 태그
                      TradeStatusTagWidget(status: tradeStatus),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 메뉴 아이콘
          Padding(
            padding: EdgeInsets.only(right: 12.w, top: 12.h),
            child: GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 24.w,
                height: 24.h,
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.more_vert,
                  color: const Color(0x99FFFFFF),
                  size: 24.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 계산 함수
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

  /// 이미지 로드 위젯
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