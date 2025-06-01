import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ItemDetailDescriptionScreen extends StatefulWidget {
  final List<String> imageUrls;
  final Size imageSize; // 이미지 크기
  final int currentImageIndex; // 현재 이미지 인덱스
  final String heroTag;

  const ItemDetailDescriptionScreen({
    super.key,
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
                  /// TODO : 사용자 프사, 위치, 닉네임, 좋아요 수
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    color: Colors.yellow[400],
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      '사용자 프사, 위치, 닉네임, 좋아요 수 영역',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textColorBlack,
                      ),
                    ),
                  ),

                  Divider(
                    color: AppColors.opacity20White,
                    height: 1.h,
                  ),

                  /// TODO : 물품 정보 및 설명
                  Container(
                    height: 197.h,
                    width: double.infinity,
                    color: Colors.green[400],
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      '물품 정보 및 설명 영역',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textColorBlack,
                      ),
                    ),
                  ),

                  Divider(
                    color: AppColors.opacity20White,
                    height: 1.h,
                  ),

                  /// TODO : 거래 희망 장소
                  Container(
                    height: 258.h,
                    width: double.infinity,
                    color: Colors.blue[400],
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      '거래 희망 장소 영역',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textColorBlack,
                      ),
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
