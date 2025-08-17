import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

/// 요청 관리 아이템 카드 위젯
class RequestManagementItemCardWidget extends StatelessWidget {
  final RequestManagementItemCard card;
  final bool isActive;
  
  const RequestManagementItemCardWidget({
    super.key,
    required this.card,
    this.isActive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // 카드 스케일 조정 (활성화 시 1.0, 비활성화 시 0.85)
    final scale = isActive ? 1.0 : 0.85;
    
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: SizedBox(                // 전체 카드 크기는 여기서만 고정
          width: 240.w,
          height: 358.h,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역 - Expanded로 남은 공간 차지
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: _buildImage(card.imageUrl),
                  ),
                ),
                
                // 정보 영역
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 정보영역은 필요한 만큼만
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리
                      Text(
                        card.category,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black.withAlpha(153),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      
                      // 제목
                      Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      
                      // 가격과 좋아요 영역
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 가격
                          Text(
                            '${formatPrice(card.price)}원',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          
                          // AI 분석 적정가 태그
                          if (card.isAiAnalyzed) ...[                              
                            SizedBox(width: 8.w),
                            _buildAiPriceTag(),
                          ],
                          
                          const Spacer(),
                          
                          // 좋아요 아이콘 및 수
                          _buildLikeCount(card.likeCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// AI 분석 적정가 태그 위젯
  Widget _buildAiPriceTag() {
    return Container(
      width: 48.w,
      height: 12.h,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(153),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: const Color(0xFF5889F2), // 파란 테두리
          width: 0.5.w,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'AI 분석 적정가',
        style: TextStyle(
          fontSize: 8.sp,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// 좋아요 아이콘과 개수 위젯
  Widget _buildLikeCount(int count) {
    return Row(
      children: [
        SizedBox(
          width: 12.w,
          height: 12.h,
          child: SvgPicture.asset(
            'assets/images/like-heart-icon.svg',
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              const Color(0xFF1D1E27).withAlpha(153),
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF1D1E27).withAlpha(153),
          ),
        ),
      ],
    );
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