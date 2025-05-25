import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/transaction_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

/// 홈 피드의 개별 아이템을 표시하는 위젯
///
/// 전체 화면을 차지하는 피드 아이템으로, 사용자는 수직으로 스와이프하여 다음 아이템으로 이동 가능
/// 각 아이템은 이미지 슬라이더, 가격 정보, 위치 및 날짜 정보, 그리고 상품 상태와 거래 방식 관련 태그 포함
class HomeFeedItemWidget extends StatefulWidget {
  /// 표시할 피드 아이템 데이터
  final HomeFeedItem item;

  const HomeFeedItemWidget({
    super.key,
    required this.item,
  });

  @override
  State<HomeFeedItemWidget> createState() => _HomeFeedItemWidgetState();
}

class _HomeFeedItemWidgetState extends State<HomeFeedItemWidget> {
  /// 현재 표시 중인 이미지의 인덱스
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
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
            bottom: 220.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.item.imageUrls.length,
                (index) => Container(
                  width: 8.w,
                  height: 8.w,
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
                    size: 32.sp,
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
            bottom: 80.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 가격 및 AI 분석 라벨
                  Row(
                    children: [
                      Text(
                        '${widget.item.price.toStringAsFixed(0)}원',
                        style: CustomTextStyles.h1,
                      ),
                      SizedBox(width: 12.w),
                      // AI 분석 적정가
                      if (widget.item.hasAiAnalysis)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.opacity70Black,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            'AI 분석 적정가',
                            style: CustomTextStyles.p3
                                .copyWith(color: AppColors.primaryYellow),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // 위치 및 날짜 정보
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '${widget.item.location} • ${widget.item.date}',
                        style: CustomTextStyles.p2,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 태그 행 (상품 상태, 거래 방식, AI 분석 버튼)
                  Row(
                    children: [
                      // 사용감 태그
                      _buildConditionTag(widget.item.itemCondition),
                      SizedBox(width: 8.w),
                      // 거래 방식 태그들
                      ...widget.item.transactionTypes.map(
                        (type) => Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildTransactionTag(type),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'AI 분석',
                          style:
                              CustomTextStyles.p3.copyWith(color: Colors.black),
                        ),
                      ),
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
