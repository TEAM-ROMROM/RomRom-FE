import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  State<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: null,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.primaryBlack,
              expandedHeight: 120.h,
              toolbarHeight: 58.h,
              titleSpacing: 0,
              elevation: innerBoxIsScrolled || _isScrolled ? 0.5 : 0,
              automaticallyImplyLeading: false,
              title: Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: innerBoxIsScrolled || _isScrolled ? 1.0 : 0.0,
                  child: Text(
                    '나의 등록된 물건',
                    style: CustomTextStyles.h3,
                  ),
                ),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 56.h, 24.w, 40.h),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: innerBoxIsScrolled || _isScrolled ? 0.0 : 1.0,
                      child: Text(
                        '나의 등록된 물건',
                        style: CustomTextStyles.h1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: _buildItemsList(),
        ),
      ),
      floatingActionButton: _buildRegisterFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildItemsList() {
    // 임시 데이터 (실제 구현 시 API 연동 필요)
    final items = List.generate(
      10,
      (index) => {
        'title': '물건 제목 ${index + 1}',
        'uploadTime': '${index + 1}시간 전',
        'price': '${(index + 1) * 10000}원',
        'likes': index + 5,
      },
    );

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemTile(items[index]),
      separatorBuilder: (context, index) => Divider(
        thickness: 1,
        color: AppColors.opacity10Black,
        height: 24.h,
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return SizedBox(
      height: 90.h,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이미지 썸네일
              Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  color: AppColors.opacity20White,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                // 실제 이미지 구현 시 Image.network() 사용
              ),
              SizedBox(width: 16.w),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['title'] as String,
                      style: CustomTextStyles.h3.copyWith(
                        color: AppColors.textColorWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      item['uploadTime'] as String,
                      style: CustomTextStyles.p2.copyWith(
                        color: AppColors.opacity50White,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      item['price'] as String,
                      style: CustomTextStyles.p1.copyWith(
                        color: AppColors.textColorWhite,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/itemRegisterHeart.svg',
                          width: 14.w,
                          height: 14.h,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${item['likes']}',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.opacity50White,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 30px 패딩 공간 확보
              SizedBox(width: 30.w),
            ],
          ),
          // 우측 상단에 더보기 버튼 배치
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 30.w,
              height: 30.h,
              child: IconButton(
                onPressed: () {
                  // 더보기 메뉴 구현
                },
                icon: Icon(
                  AppIcons.dotsVertical,
                  size: 24.sp,
                  color: AppColors.opacity50White,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterFab() {
    return Container(
      margin: EdgeInsets.only(bottom: 32.h),
      width: 144.w,
      height: 56.h,
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        onPressed: () {
          // 등록하기 화면으로 이동
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.addItemPlus,
              size: 16.sp,
              color: AppColors.textColorBlack,
            ),
            SizedBox(width: 8.w),
            Text(
              '등록하기',
              style: CustomTextStyles.h3.copyWith(
                color: AppColors.textColorBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}