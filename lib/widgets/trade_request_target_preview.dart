import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';

import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

/// 요청하기 화면 상단에 표시되는 교환 대상 물품 미리보기 카드
class TradeRequestTargetPreview extends StatelessWidget {
  /// 물품 이미지 URL
  final String? imageUrl;

  /// 물품 이름
  final String itemName;

  /// 태그 목록 (사용감, 거래방식 등)
  final List<String> tags;

  const TradeRequestTargetPreview({
    super.key,
    this.imageUrl,
    required this.itemName,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // 물품 이미지 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 60.w,
              height: 60.w,
              child: _buildImage(),
            ),
          ),
          SizedBox(width: 12.w),

          // 물품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 물품 이름
                Text(
                  itemName,
                  style: CustomTextStyles.p2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // 태그들
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 로드 위젯
  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const ErrorImagePlaceholder();
    }

    return Image.network(
      imageUrl!,
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

  /// 태그 위젯 빌드
  Widget _buildTag(String tag) {
  // 거래방식 태그인지 확인 (ItemTradeOption enum에 존재하는 값만)
  final isTradeOption = ItemTradeOption.values.any((option) => option.label == tag);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isTradeOption
            ? AppColors.transactionTagBackground
            : AppColors.conditionTagBackground,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        tag,
        style: CustomTextStyles.p3.copyWith(
          color: AppColors.textColorBlack,
          fontWeight: FontWeight.w500,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
