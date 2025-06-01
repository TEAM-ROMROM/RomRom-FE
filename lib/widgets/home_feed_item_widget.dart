import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/home_feed_item_tag_chips.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

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
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _currentImageIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedPrice = formatPrice(widget.item.price);

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
            controller: pageController,
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
                      GestureDetector(
                        onTap: () async {
                          final resultIndex = await Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 1000),
                                pageBuilder: (_, __, ___) =>
                                    ItemDetailDescriptionScreen(
                                  item: widget.item,
                                  imageUrls: widget.item.imageUrls,
                                  imageSize: Size(
                                    MediaQuery.of(context).size.width,
                                    MediaQuery.of(context).size.width,
                                  ),
                                  currentImageIndex: index,
                                  heroTag: 'itemImage_${widget.item.id}',
                                ),
                              ));

                          if (resultIndex != null && resultIndex is int) {
                            setState(() {
                              _currentImageIndex = resultIndex;
                            });
                            pageController.jumpToPage(
                                _currentImageIndex); // 또는 animateToPage()
                          }
                        },
                        child: Hero(
                          tag: 'itemImage_${widget.item.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.r),
                                topRight: Radius.circular(4.r),
                                bottomRight: Radius.circular(20.r),
                                bottomLeft: Radius.circular(20.r)),
                            child: Image.network(
                              widget.item.imageUrls[index],
                              fit: BoxFit.cover,
                              height: 615.h,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryYellow,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const IgnorePointer(child: BlackGradientContainer()),
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
                  child: SvgPicture.asset(
                    widget.item.hasAiAnalysis
                        ? 'assets/images/dislike-heart-icon.svg'
                        : 'assets/images/like-heart-icon.svg',
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
                                HomeFeedAiAnalysisTag(
                                    tag: widget.item.priceTag!)
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // 위치 및 날짜 정보
                          Row(
                            children: [
                              // FIXME 위치 아이콘 교체 필요
                              Icon(AppIcons.location,
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
                      const UserProfileCircularAvatar(
                        avatarSize: Size(50, 50),
                      ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  // 태그 행 (상품 상태, 거래 방식, AI 분석 버튼)
                  Row(
                    children: [
                      // 사용감 태그
                      /// itemCondition 태그 생성
                      HomeFeedConditionTag(
                          condition: widget.item.itemCondition),
                      SizedBox(width: 4.w),
                      // 거래 방식 태그들
                      ...widget.item.transactionTypes.map(
                        (type) => Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: HomeFeedTransactionTypeTag(type: type),
                        ),
                      ),
                      const Spacer(),
                      HomeFeedAiTag(
                        isActive: widget.item.hasAiAnalysis,
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
