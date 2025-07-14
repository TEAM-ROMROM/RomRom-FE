import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/widgets/common/item_options_menu.dart';
import 'dart:async';
import '../utils/common_utils.dart';

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  State<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isScrolling = false;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    // 스크롤 중임을 표시
    setState(() {
      _isScrolling = true;
    });

    // 기존 타이머 취소
    _scrollTimer?.cancel();

    // 스크롤이 멈춘 후 0.3초 후에 스크롤이 끝났다고 판단
    _scrollTimer = Timer(const Duration(milliseconds: 700), () {
      setState(() {
        _isScrolling = false;
      });
    });

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
      body: Stack(
        children: [
          SafeArea(
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
                        style: CustomTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: Container(
                    color: AppColors.primaryBlack,
                    child: FlexibleSpaceBar(
                      background: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 56.h, 24.w, 40.h),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity:
                                innerBoxIsScrolled || _isScrolled ? 0.0 : 1.0,
                            child: Text(
                              '나의 등록된 물건',
                              style: CustomTextStyles.h1,
                            ),
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
          _buildRegisterFabStacked(context),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // TODO : 임시 데이터 (실제 구현 시 API 연동 필요)
    final items = List.generate(
      10,
      (index) => {
        'title': '물건 제목 ${index + 1}',
        'uploadTime': '${index + 1}시간 전',
        'price': (index + 1) * 10000,
        'likes': index + 5,
      },
    );

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemTile(items[index], index),
      separatorBuilder: (context, index) => Divider(
        thickness: 1.5,
        color: AppColors.opacity10White,
        height: 32.h,
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
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
                      style: CustomTextStyles.p1
                          .copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      item['uploadTime'] as String,
                      style: CustomTextStyles.p2.copyWith(
                        color: AppColors.opacity60White,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '${formatPrice(item['price'])}원',
                      style: CustomTextStyles.p1.copyWith(),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(AppIcons.itemRegisterHeart,
                            size: 14.sp, color: AppColors.opacity60White),
                        SizedBox(width: 4.w),
                        Text(
                          '${item['likes']}',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.opacity60White,
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
              child: ItemOptionsMenuButton(
                onEditPressed: () {
                  // 수정 기능 구현
                  debugPrint('${item['title']} 수정 버튼 클릭');
                },
                onDeletePressed: () async {
                  // 삭제 기능 구현
                  final result = await context.showWarningDialog(
                    title: '물건을 삭제하시겠습니까?',
                    description: '삭제된 물건은 복구할 수 없습니다.',
                  );

                  if (result == true) {
                    // 확인 버튼이 눌렸을 때 삭제 로직
                    debugPrint('${item['title']} 삭제 확인');
                    // 여기에 실제 삭제 API 호출 로직 추가
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 등록하기 fab 버튼
  Widget _buildRegisterFabStacked(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32.h,
      child: IgnorePointer(
        ignoring: _isScrolling,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isScrolling ? 0.0 : 1.0,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isScrolling ? 0.0 : 1.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.opacity20Black,
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100.r),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemRegisterScreen(
                            onClose: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                      // 등록 화면에서 돌아온 뒤 필요한 상태 갱신
                      setState(() {});
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 15.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.addItemPlus,
                            size: 16.sp,
                            color: AppColors.primaryBlack,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '등록하기',
                            style: CustomTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColorBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
