import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/price_tag.dart';
import 'package:romrom_fe/enums/transaction_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

/// 홈 피드 아이템 위젯
/// 각 아이템의 상세 정보를 표시하는 위젯
class HomeFeedItemWidget extends StatefulWidget {
  final HomeFeedItem item;

  const HomeFeedItemWidget({
    super.key,
    required this.item,
  });

  @override
  State<HomeFeedItemWidget> createState() => _HomeFeedItemWidgetState();
}

class _HomeFeedItemWidgetState extends State<HomeFeedItemWidget> {
  int _currentImageIndex = 0;
  final formatter = NumberFormat('#,###원');

  @override
  Widget build(BuildContext context) {
    int price = (widget.item.price);
    String formattedPrice = formatter.format(price);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: AppColors.primaryBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 (가로 스와이프 가능)
          PageView.builder(
            itemCount: widget.item.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.item.imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryYellow,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              );
            },
          ),

          // 이미지 인디케이터 (하단 점)
          Positioned(
            bottom: 206.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.item.imageUrls.length,
                (index) => Container(
                  width: 6.w,
                  height: 6.w,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : AppColors.opacity50White,
                  ),
                ),
              ),
            ),
          ),

          // 좋아요 버튼 및 카운트
          Positioned(
            right: 16.w,
            bottom: 180.h,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                  onPressed: () {
                    // FIXME: 좋아요 기능 API 연동 필요
                  },
                ),
                Text(
                  widget.item.likeCount.toString(),
                  style: CustomTextStyles.p2,
                ),
              ],
            ),
          ),

          // 하단 정보 패널
          Positioned(
            left: 0,
            right: 0,
            bottom: 91.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 가격 및 AI 분석 라벨
                  Row(
                    children: [
                      Text(
                        formattedPrice,
                        style: CustomTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 12.w),
                      if (widget.item.priceTag != null)
                        _buildPriceTag(widget.item.priceTag!),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // 위치 및 날짜 정보
                  Row(
                    children: [
                      // FIXME 위치 아이콘 교체 필요
                      Icon(Icons.location_on_outlined,
                          color: AppColors.opacity80White, size: 13.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '${widget.item.location} • ${widget.item.date}',
                        style: CustomTextStyles.p3
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // 태그 행 (상품 상태, 거래 방식, AI 분석 버튼)
                  Row(
                    children: [
                      // 사용감 태그
                      _buildConditionTag(widget.item.itemCondition),
                      SizedBox(width: 4.w),
                      // 거래 방식 태그들
                      ...widget.item.transactionTypes.map(
                        (type) => Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: _buildTransactionTag(type),
                        ),
                      ),
                      const Spacer(),
                      widget.item.hasAiAnalysis
                          ? _buildActiveAiButton()
                          : _buildInactiveAiButton(),
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

  /// 가격 태그 생성
  Widget _buildPriceTag(PriceTag tag) {
    if (tag == PriceTag.aiAnalyzed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.aiTagBackground,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: AppColors.aiTagBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8.w),
            Text(
              tag.name,
              style: CustomTextStyles.p3.copyWith(color: AppColors.aiTagBorder),
            ),
            SizedBox(width: 8.w),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8.w),
            Text(
              tag.name,
              style: CustomTextStyles.p3.copyWith(color: Colors.black),
            ),
            SizedBox(width: 8.w),
          ],
        ),
      );
    }
  }

  /// 활성화된 AI 분석 버튼
  Widget _buildActiveAiButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        'AI 분석',
        style: CustomTextStyles.p3.copyWith(color: Colors.black),
      ),
    );
  }

  /// 비활성화된 AI 분석 버튼
  Widget _buildInactiveAiButton() {
    return Container(
      width: 67.w,
      height: 23.h,
      decoration: BoxDecoration(
        color: AppColors.aiTagBackground,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(
          color: AppColors.aiTagBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
          const BoxShadow(
            color: AppColors.aiButtonGlow,
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'AI 분석',
          style: CustomTextStyles.p3.copyWith(color: AppColors.aiTagBorder),
        ),
      ),
    );
  }

  /// itemCondition 태그 생성
  Widget _buildConditionTag(ItemCondition condition) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.conditionTagBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        condition.name,
        style: CustomTextStyles.p3.copyWith(color: Colors.black),
      ),
    );
  }

  /// transactionType 태그 생성
  Widget _buildTransactionTag(TransactionType type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.transactionTagBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        type.name,
        style: CustomTextStyles.p3.copyWith(color: Colors.black),
      ),
    );
  }
}
