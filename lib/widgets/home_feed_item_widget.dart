import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/blur_wrapper.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/home_feed_item_tag_chips.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';

/// 홈 피드 아이템 위젯
/// 각 아이템의 상세 정보를 표시하는 위젯
class HomeFeedItemWidget extends StatefulWidget {
  final HomeFeedItem item;
  final bool showBlur;

  const HomeFeedItemWidget({super.key, required this.item, required this.showBlur});

  @override
  State<HomeFeedItemWidget> createState() => _HomeFeedItemWidgetState();
}

class _HomeFeedItemWidgetState extends State<HomeFeedItemWidget> {
  int _currentImageIndex = 0;
  late PageController pageController;
  late bool _useAiPrice; // AI 가격 여부
  late bool _isLiked;
  late int _likeCount;
  bool _isLiking = false; // 좋아요 API 중복 호출 방지

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _currentImageIndex);
    _useAiPrice = widget.item.aiPrice; // AI 가격 여부
    _isLiked = widget.item.isLiked;
    _likeCount = widget.item.likeCount;
    _fetchItemLikeStatus();
  }

  Future<void> _fetchItemLikeStatus() async {
    try {
      if (widget.item.itemUuid == null || widget.item.itemUuid!.isEmpty) {
        return;
      }

      final itemApi = ItemApi();
      final response = await itemApi.getItemDetail(ItemRequest(itemId: widget.item.itemUuid));

      if (mounted) {
        setState(() {
          _useAiPrice = response.item?.isAiPredictedPrice ?? false;
          _isLiked = response.isLiked == true;
          _likeCount = response.item?.likeCount ?? widget.item.likeCount;
        });
      }
    } catch (e) {
      debugPrint('좋아요 상태 조회 실패: $e');
    }
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
    final availableHeight = screenHeight - bottomPadding - navigationBarHeight; // 네비게이션바 높이(80.h)를 고려
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
                          MaterialPageRoute(
                            builder: (_) => ItemDetailDescriptionScreen(
                              itemId: widget.item.itemUuid ?? '',
                              imageSize: Size(screenWidth, screenWidth),
                              currentImageIndex: index,
                              heroTag: 'itemImage_${widget.item.itemUuid ?? widget.item.id}_$index',
                              homeFeedItem: widget.item,
                              isMyItem: false,
                              isRequestManagement: false,
                              isTradeRequestAllowed: true,
                            ),
                          ),
                        );
                        if (resultIndex != null && resultIndex is int) {
                          setState(() {
                            _currentImageIndex = resultIndex;
                          });
                          pageController.jumpToPage(_currentImageIndex);
                        }
                      },
                      child: Hero(
                        tag: 'itemImage_${widget.item.itemUuid ?? widget.item.id}_$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(4.r), topRight: Radius.circular(4.r), bottomRight: Radius.circular(20.r), bottomLeft: Radius.circular(20.r)),
                          child: _buildImage(widget.item.imageUrls[index], Size(screenWidth, availableHeight - navigationBarHeight)),
                        ),
                      ),
                    ),
                  ),

                  // 그라디언트 오버레이
                  const Positioned.fill(child: IgnorePointer(child: BlackGradientContainer())),

                  // 블러 효과
                  if (widget.showBlur)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(color: AppColors.opacity10Black),
                      ),
                    ),

                  /// 더보기 아이콘 버튼
                  if (!widget.showBlur)
                    Positioned(
                      right: 24.w,
                      top: (MediaQuery.of(context).padding.top < 59 ? 59.h : MediaQuery.of(context).padding.top),
                      child: ReportMenuButton(
                        onReportPressed: () async {
                          final bool? reported = await Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen(itemId: widget.item.itemUuid ?? '')));

                          if (reported == true && mounted) {
                            await CommonModal.success(context: context, message: '신고가 접수되었습니다.', onConfirm: () => Navigator.of(context).pop());
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),

          // 이미지 인디케이터 (하단 점)
          if (!widget.showBlur)
            Positioned(
              bottom: 220.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.item.imageUrls.length,
                  (index) => Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _currentImageIndex == index ? AppColors.primaryYellow : AppColors.opacity50White),
                  ),
                ),
              ),
            ),

          // 좋아요 버튼 및 카운트
          if (!widget.showBlur)
            Positioned(
              right: 33.w,
              bottom: 216.h,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      // 연타 방지 및 유효성 검사
                      if (_isLiking || widget.item.itemUuid == null || widget.item.itemUuid!.isEmpty) {
                        return;
                      }

                      // 내가 작성한 게시글인지 확인
                      final isCurrentMember = await MemberManager.isCurrentMember(widget.item.authorMemberId);
                      if (isCurrentMember) {
                        if (mounted) {
                          CommonSnackBar.show(context: context, message: '본인 게시글에는 좋아요를 누를 수 없습니다.', type: SnackBarType.info);
                        }
                        return;
                      }

                      setState(() => _isLiking = true);
                      try {
                        final itemApi = ItemApi();
                        final response = await itemApi.postLike(ItemRequest(itemId: widget.item.itemUuid));
                        if (!mounted) return;
                        setState(() {
                          _isLiked = response.isLiked == true;
                          if (response.item?.likeCount != null) {
                            _likeCount = response.item?.likeCount ?? _likeCount;
                          } else {
                            _likeCount = _isLiked ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
                          }
                        });
                      } catch (e) {
                        debugPrint('좋아요 실패: $e');
                      } finally {
                        if (mounted) {
                          setState(() => _isLiking = false);
                        }
                      }
                    },
                    child: SvgPicture.asset(_isLiked ? 'assets/images/like-heart-icon.svg' : 'assets/images/dislike-heart-icon.svg'),
                  ),
                  SizedBox(height: 2.h),
                  Text(_likeCount.toString(), style: CustomTextStyles.p2),
                ],
              ),
            ),

          // 하단 정보 패널
          Positioned(
            left: 0,
            right: 0,
            bottom: 92.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BlurWrapper(
                      enabled: widget.showBlur,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 물품 이름
                          Text(
                            widget.item.name.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
                          ),

                          SizedBox(height: 8.h),

                          // 위치 및 날짜 정보
                          Row(
                            children: [
                              Icon(AppIcons.location, color: AppColors.opacity80White, size: 13.sp),
                              SizedBox(width: 4.w),
                              Text('${widget.item.location} • $formattedDate', style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          Row(
                            children: [
                              // 사용감 태그 - ItemDetail과 동일한 위젯 사용
                              ItemDetailConditionTag(condition: widget.item.itemCondition.label),
                              SizedBox(width: 4.w),
                              // 거래 방식 태그들 - ItemDetail과 동일한 위젯 사용
                              ...widget.item.transactionTypes.map((type) => ItemDetailTradeOptionTag(option: type.label)),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          Row(
                            children: [
                              // 물품 가격
                              Text("$formattedPrice원", style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),

                              SizedBox(width: 8.w),

                              _useAiPrice ? const AiBadgeWidget() : const SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 프로필 이미지 및 AI 가격 태그
                  BlurWrapper(
                    enabled: widget.showBlur,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 프로필 이미지
                        GestureDetector(
                          onTap: widget.showBlur
                              ? null
                              : () {
                                  if (widget.item.authorMemberId != null) {
                                    context.navigateTo(screen: ProfileScreen(memberId: widget.item.authorMemberId!));
                                  }
                                },
                          child: ClipOval(
                            child: BlurWrapper(
                              enabled: widget.showBlur,
                              child: UserProfileCircularAvatar(avatarSize: const Size(50, 50), profileUrl: widget.item.profileUrl.isNotEmpty ? widget.item.profileUrl : null),
                            ),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        HomeFeedAiTag(isActive: _useAiPrice),
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
                          style: CustomTextStyles.h1.copyWith(color: AppColors.primaryYellow, height: 1.3),
                        ),
                        TextSpan(text: '하고\n물건을 교환해보세요!', style: CustomTextStyles.h1.copyWith(height: 1.3)),
                      ],
                    ),
                  ),
                  SizedBox(height: 56.h),
                  SvgPicture.asset('assets/images/first-item-post-box.svg', width: 133.w),
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
            value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : null,
          ),
        );
      },
    );
  }
}

/// 검정색 그라데이션 컨테이너
class BlackGradientContainer extends StatelessWidget {
  const BlackGradientContainer({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 : 그라디언트 높이 동적 조정
    return Column(
      children: [
        Expanded(
          flex: 627, // 비율 627
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.blackGradient1, // 검정색 그라데이션
                    stops: const [0.0, 0.29, 0.45],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.blackGradient2, // 검정색 그라데이션
                    stops: const [0.0, 0.24, 0.73, 0.99],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 139, // 비율 139
          child: Container(color: Colors.black),
        ),
      ],
    );
  }
}
