import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
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
      color: Colors.black,
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
              return Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4.r),
                            topRight: Radius.circular(4.r),
                            bottomRight: Radius.circular(20.r),
                            bottomLeft: Radius.circular(20.r)),
                        child: Image.network(
                          widget.item.imageUrls[index],
                          fit: BoxFit.cover,
                          height: 615.h,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryYellow,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const BlackGradientContainer(),
                    ],
                  ),
                  SizedBox(
                    height: 125.h,
                    // child: const FanCardDial(),
                  ),
                ],
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
            right: 33.w,
            bottom: 202.h,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // FIXME: 좋아요 기능 API 연동 필요
                  },
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                ),
                SizedBox(height: 2.h),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // 가격 및 AI 분석 라벨
                        children: [
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
                        ],
                      ),
                      const Spacer(),
                      // 프로필 이미지
                      //FIXME: 프로필 이미지 API 연동 필요
                      Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
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
                      _buildAiAnalysisButton(widget.item.hasAiAnalysis)
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

  /// AI 분석 적정가 태그 생성
  Widget _buildPriceTag(PriceTag tag) {
    // border
    final gradientBorder = GradientBoxBorder(
      gradient: LinearGradient(
        colors: [
          AppColors.aiTagGradientBorder1.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder2.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder3.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder4.withValues(alpha: 1.0),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ),
      width: 1.w,
    );

    return tag == PriceTag.aiAnalyzed
        ? Container(
            width: 64.w,
            height: 17.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(100.r),
              border: gradientBorder,
            ),
            child: Text(
              tag.name,
              style: CustomTextStyles.p3.copyWith(fontSize: 9.sp),
            ),
          )
        : Container(
            width: 46.w,
            height: 17.h,
            decoration: BoxDecoration(
              color: AppColors.opacity80White,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tag.name,
                  style: CustomTextStyles.p3
                      .copyWith(fontSize: 9.sp, color: AppColors.primaryBlack),
                ),
              ],
            ),
          );
  }

  /// 활성화된 AI 분석 버튼
  Widget _buildAiAnalysisButton(bool isActive) {
    // border
    final gradientBorder = GradientBoxBorder(
      gradient: LinearGradient(
        colors: [
          AppColors.aiTagGradientBorder1
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder2
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder3
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder4
              .withValues(alpha: isActive ? 1.0 : 0.4),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ),
      width: 1.w,
    );

    // 그림자
    final boxShadows = [
      BoxShadow(
        color: AppColors.aiButtonGlow
            .withValues(alpha: isActive ? 0.7 : 0.3), // 첫 번째 그림자 투명도 조절
        offset: const Offset(0, 0),
        blurRadius: 10.r,
        spreadRadius: 0.r,
      ),
      BoxShadow(
        color: Colors.white
            .withValues(alpha: isActive ? 1.0 : 0.3), // 두 번째 그림자 투명도 조절
        offset: const Offset(0, -1),
        blurRadius: 4.r,
        spreadRadius: 0.r,
      ),
    ];

    return Container(
      width: 67.w,
      height: 24.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(100.r),
        border: gradientBorder,
        boxShadow: boxShadows,
      ),
      child: Text(
        'AI 분석',
        style: CustomTextStyles.p3.copyWith(fontSize: 10.sp),
      ),
    );
  }

  /// itemCondition 태그 생성
  Widget _buildConditionTag(ItemCondition condition) {
    return Container(
      height: 24.h,
      constraints: BoxConstraints(
        minWidth: 62.w, // 최소 가로 길이
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.conditionTagBackground,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        condition.name,
        style:
            CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }

  /// transactionType 태그 생성
  Widget _buildTransactionTag(TransactionType type) {
    return Container(
      width: 62.w,
      height: 24.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.transactionTagBackground,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        type.name,
        style:
            CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }
}

/// 검정색 그라데이션 컨테이너
class BlackGradientContainer extends StatelessWidget {
  const BlackGradientContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 627.h,
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          Colors.black,
          Colors.black.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.24, 0.38],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      )),
    );
  }
}
