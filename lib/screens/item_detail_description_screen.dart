import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/home_feed_item_tag_chips.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class ItemDetailDescriptionScreen extends StatefulWidget {
  final HomeFeedItem item;

  final List<String> imageUrls;
  final Size imageSize; // 이미지 크기
  final int currentImageIndex; // 현재 이미지 인덱스
  final String heroTag;

  const ItemDetailDescriptionScreen({
    super.key,
    required this.item,
    required this.imageUrls,
    required this.imageSize,
    required this.currentImageIndex,
    required this.heroTag,
  });

  @override
  State<ItemDetailDescriptionScreen> createState() =>
      _ItemDetailDescriptionScreenState();
}

class _ItemDetailDescriptionScreenState
    extends State<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late int currentImageIndex;

  @override
  void initState() {
    super.initState();
    currentImageIndex = widget.currentImageIndex;
    pageController = PageController(initialPage: currentImageIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedPrice = formatPrice(widget.item.price);

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            /// 배경 이미지 (가로 스와이프 가능)
            Stack(
              children: [
                SizedBox(
                  height: widget.imageSize.height,
                  width: widget.imageSize.width,
                  child: PageView.builder(
                      itemCount: widget.imageUrls.length,
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: widget.heroTag,
                          child: Image.network(
                            widget.imageUrls[index],
                            fit: BoxFit.cover,
                            width: widget.imageSize.width,
                            height: widget.imageSize.height,
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
                        );
                      }),
                ),

                /// 이전 아이콘 버튼
                Positioned(
                  left: 24.w,
                  top: MediaQuery.of(context).padding.top +
                      8, // SafeArea 기준으로 margin 줌
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context,
                              currentImageIndex); // 현재 이미지 인덱스를 이전 페이지로 전달
                          (value) {
                            // 페이지가 닫힌 후 이전 페이지로 돌아감
                            if (value != null && value is int) {
                              pageController.jumpToPage(value);
                            }
                          };
                        },
                        child: Icon(AppIcons.navigateBefore,
                            size: 24.sp, color: AppColors.textColorWhite),
                      ),
                    ],
                  ),
                ),

                /// 더보기 아이콘 버튼
                Positioned(
                  right: 24.w,
                  top: MediaQuery.of(context).padding.top +
                      8, // SafeArea 기준으로 margin 줌
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: 더보기 기능 구현
                          debugPrint('더보기 버튼 클릭 - 기능 구현 예정');
                        },
                        child: Icon(AppIcons.dotsVertical,
                            size: 30.sp, color: AppColors.textColorWhite),
                      ),
                    ],
                  ),
                ),
                // 이미지 인디케이터 (하단 점)
                Positioned(
                  bottom: 24.h,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => Container(
                        width: 6.w,
                        height: 6.w,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentImageIndex == index
                              ? Colors.white
                              : AppColors.opacity50White,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// 아이템 설명 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  /// 사용자 프사, 위치, 닉네임, 좋아요 수
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      children: [
                        const UserProfileCircularAvatar(
                          avatarSize: Size(40, 40),
                        ),
                        SizedBox(width: 10.w),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// FIXME : 닉네임, 위치 사용자 정보에서 불러오기
                            Text(
                              '닉네임',
                              style: CustomTextStyles.p2,
                            ),
                            Text(
                              '화양동',
                              style: CustomTextStyles.p3.copyWith(
                                  color: const Color(0xFFEEEEEE)
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 11.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100.r),
                            border: Border.all(
                              color: AppColors.opacity30White,
                              width: 1.w,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/dislike-heart-icon.svg',
                                width: 16.w,
                                height: 16.h,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '4',
                                style: CustomTextStyles.p2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: AppColors.opacity20White,
                    height: 1.h,
                  ),

                  /// 물품 정보 및 설명
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '스포츠/레저 · ',
                            style: CustomTextStyles.p3.copyWith(
                                color: AppColors.opacity50White,
                                fontWeight: FontWeight.w400),
                            children: [
                              TextSpan(
                                text: widget.item.date,
                                style: CustomTextStyles.p3.copyWith(
                                    color: AppColors.opacity50White,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),

                        /// FIXME : 물품 설명 사용자 정보에서 불러오기
                        Text(
                          '요넥스 이존 260g',
                          style: CustomTextStyles.h3.copyWith(),
                        ),
                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            HomeFeedConditionTag(
                                condition: widget.item.itemCondition),
                            SizedBox(width: 4.w),
                            HomeFeedTransactionTypeTag(
                              type: widget.item.transactionTypes[0],
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            Text(
                              formattedPrice,
                              style: CustomTextStyles.h3.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            HomeFeedAiAnalysisTag(tag: widget.item.priceTag!),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          widget.item.description,
                          // '누구나 이런 밤의 세계에 익숙하지 못한 사람은\n좀 무서워질 것입니다만. 어머나, 저렇게 많아.\n참 기막히게 아름답구나. 저렇게 많은 별은 생전 처음이야.',
                          style: CustomTextStyles.p2.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: AppColors.opacity20White,
                    height: 1.h,
                  ),

                  /// 거래 희망 장소
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '거래희망장소',
                          style: CustomTextStyles.p2.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(AppIcons.location,
                                size: 13.sp, color: AppColors.opacity80White),
                            SizedBox(width: 4.w),
                            Text(
                              widget.item.location,
                              style: CustomTextStyles.p2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          width: double.infinity,
                          height: 200.h,
                          decoration: BoxDecoration(
                            color: AppColors.opacity30White,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
