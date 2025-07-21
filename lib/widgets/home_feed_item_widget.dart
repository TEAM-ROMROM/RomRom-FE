import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/blur_wrapper.dart';
import 'package:romrom_fe/widgets/home_feed_item_tag_chips.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

/// 홈 피드 아이템 위젯
/// 각 아이템의 상세 정보를 표시하는 위젯
class HomeFeedItemWidget extends StatefulWidget {
  final HomeFeedItem item;
  final bool showBlur;

  const HomeFeedItemWidget({
    super.key,
    required this.item,
    required this.showBlur,
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
    String formattedDate = formatDate(widget.item.date);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // 네비게이션바 && 상태바 높이 : 실제 사용 가능 높이 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navigationBarHeight = 100.h; // 네비게이션바 높이 (80.h)
    final availableHeight = screenHeight -
        bottomPadding -
        navigationBarHeight; // 네비게이션바 높이(80.h)를 고려
    final registerBlurTextTopPosition = 205.h;

    return Container(
      height: screenHeight,
      width: screenWidth,
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
              return Stack(
                children: [
                  // 이미지와 그라디언트
                  Positioned.fill(
                    child: GestureDetector(
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
                                  screenWidth,
                                  screenWidth,
                                ),
                                currentImageIndex: index,
                                heroTag: 'itemImage_${widget.item.id}',
                              ),
                            ));

                        if (resultIndex != null && resultIndex is int) {
                          setState(() {
                            _currentImageIndex = resultIndex;
                          });
                          pageController.jumpToPage(_currentImageIndex);
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
                          child: _buildImage(
                            widget.item.imageUrls[index],
                            Size(screenWidth,
                                availableHeight - navigationBarHeight),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 그라디언트 오버레이
                  const Positioned.fill(
                    child: IgnorePointer(child: BlackGradientContainer()),
                  ),

                  // 블러 효과
                  if (widget.showBlur)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          color: AppColors.opacity10Black,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 이미지 인디케이터 (하단 점)
          if (!widget.showBlur)
            Positioned(
              bottom: 180.h,
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
          if (!widget.showBlur)
            Positioned(
              right: 33.w,
              bottom: 180.h,
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
            bottom: 70.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BlurWrapper(
                        enabled: widget.showBlur,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // 가격 및 AI 분석 라벨
                          children: [
                            Row(
                              children: [
                                Text(
                                  "$formattedPrice원",
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
                                Icon(AppIcons.location,
                                    color: AppColors.opacity80White,
                                    size: 13.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  '${widget.item.location} • $formattedDate',
                                  style: CustomTextStyles.p3
                                      .copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // 프로필 이미지
                      ClipOval(
                        child: BlurWrapper(
                          enabled: widget.showBlur,
                          child: const UserProfileCircularAvatar(
                            avatarSize: Size(50, 50),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  // 태그 행 (상품 상태, 거래 방식, AI 분석 버튼)
                  BlurWrapper(
                    enabled: widget.showBlur,
                    child: Row(
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
                  ),
                ],
              ),
            ),
          ),

          if (widget.showBlur)
            Positioned(
              top: registerBlurTextTopPosition,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: CustomTextStyles.h3.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '내 물건을 등록',
                          style: CustomTextStyles.h1.copyWith(
                              color: AppColors.primaryYellow, height: 1.3),
                        ),
                        TextSpan(
                          text: '하고\n물건을 교환해보세요!',
                          style: CustomTextStyles.h1.copyWith(height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56.h,
                  ),
                  SvgPicture.asset(
                    'assets/images/first-item-post-box.svg',
                    width: 133.w,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 이미지 로더: 네트워크 실패 또는 잘못된 경로 시 플레이스홀더 표시
  Widget _buildImage(String rawUrl, Size size) {
    final String url = rawUrl.trim();

    final placeholder = ErrorImagePlaceholder(size: size);

    if (url.isEmpty || !url.startsWith('http')) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('HomeFeed 이미지 로드 실패: $url, error: $error');
        return placeholder;
      },
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
  }
}

/// 검정색 그라데이션 컨테이너
class BlackGradientContainer extends StatelessWidget {
  const BlackGradientContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 크기 : 그라디언트 높이 동적 조정
    return Container(
      height: double.infinity,
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
