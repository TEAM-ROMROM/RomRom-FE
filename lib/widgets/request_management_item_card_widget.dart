import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge_widget.dart';
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
        child: SizedBox(
          width: 219.w,
          height: 326.h,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.opacity60White,
                width: 4.w,
              ),
              color: AppColors.opacity80White,
              boxShadow: [
                BoxShadow(
                  color: AppColors.opacity15Black,
                  blurRadius: 10.r,
                  spreadRadius: 0,
                  offset: Offset(4.w, 4.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                SizedBox(
                  width: 219.w,
                  height: 247.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: _buildImage(card.imageUrl),
                  ),
                ),
                
                // 정보 영역
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w).copyWith(top: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리
                        Text(
                          card.category,
                          style: TextStyle(
                            color: const Color(0x80131419), // rgba(19, 20, 25, 0.50)
                            fontFamily: 'Pretendard',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        
                        // 제목
                        Text(
                          card.title,
                          style: TextStyle(
                            color: AppColors.primaryBlack,
                            fontFamily: 'NEXON Lv2 Gothic',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        
                        // 가격과 좋아요 영역
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // AI 배지 (있는 경우)
                            if (card.isAiAnalyzed) ...[
                              const AiBadgeWidget(),
                              SizedBox(width: 4.w),
                            ],
                            // 가격
                            Text(
                              '${formatPrice(card.price)}원',
                              style: TextStyle(
                                color: AppColors.primaryBlack,
                                fontFamily: 'Pretendard',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // 좋아요 아이콘 및 수
                            _buildLikeCount(card.likeCount),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            colorFilter: const ColorFilter.mode(
              Color(0x991D1E27), // rgba(29, 30, 39, 0.60)
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '$count',
          style: TextStyle(
            color: const Color(0x991D1E27), // rgba(29, 30, 39, 0.60)
            fontFamily: 'Pretendard',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
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