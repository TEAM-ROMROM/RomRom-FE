import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/services/location_service.dart';

import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';

class ItemDetailDescriptionScreen extends StatefulWidget {
  final String itemId;
  final Size imageSize;
  final int currentImageIndex;
  final String heroTag;
  final HomeFeedItem? homeFeedItem;

  const ItemDetailDescriptionScreen({
    super.key,
    required this.itemId,
    required this.imageSize,
    required this.currentImageIndex,
    required this.heroTag,
    this.homeFeedItem,
  });

  @override
  State<ItemDetailDescriptionScreen> createState() =>
      _ItemDetailDescriptionScreenState();
}

class _ItemDetailDescriptionScreenState
    extends State<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late int currentImageIndex;
  
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  
  Item? item;
  List<ItemImage>? itemImages;
  List<String>? itemCustomTags;
  String? likeStatus;
  int? likeCount;
  String locationName = '위치 정보 로딩 중...';
  
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    currentImageIndex = widget.currentImageIndex;
    pageController = PageController(initialPage: currentImageIndex);
    _loadItemDetail();
  }
  
  Future<void> _loadItemDetail() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      final ItemApi itemApi = ItemApi();
      final ItemRequest request = ItemRequest(itemId: widget.itemId);
      final ItemResponse response = await itemApi.getItemDetail(request);
      
      if (!mounted) return;
      
      setState(() {
        item = response.item;
        itemImages = response.itemImages;
        itemCustomTags = response.itemCustomTags;
        likeStatus = response.likeStatus;
        likeCount = response.likeCount;
        
        imageUrls = itemImages?.map((img) => img.imageUrl ?? '').where((url) => url.isNotEmpty).toList() ?? [];
        
        // 좌표를 주소로 변환
        if (item?.latitude != null && item?.longitude != null) {
          _getAddressFromCoordinates(item!.latitude!, item!.longitude!);
        }
        
        isLoading = false;
      });
    } catch (e) {
      debugPrint('물품 상세 정보 로드 실패: $e');
      if (!mounted) return;
      
      setState(() {
        hasError = true;
        errorMessage = '물품 정보를 불러오는데 실패했습니다.';
        isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(
        NLatLng(lat, lng),
      );
      
      if (address != null) {
        setState(() {
          locationName = address.currentAddress;
        });
      } else {
        setState(() {
          locationName = '위치 정보 없음';
        });
      }
    } catch (e) {
      debugPrint('주소 변환 실패: $e');
      setState(() {
        locationName = '위치 정보 없음';
      });
    }
  }

  String _getCategoryName(String? serverName) {
    if (serverName == null) return '카테고리 없음';
    try {
      return ItemCategories.fromServerName(serverName).name;
    } catch (e) {
      return '카테고리 없음';
    }
  }

  String _getTradeOptionName(String serverName) {
    try {
      return ItemTradeOption.fromServerName(serverName).name;
    } catch (e) {
      return serverName;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryYellow,
          ),
        ),
      );
    }
    
    if (hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadItemDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                ),
                child: Text(
                  '다시 시도',
                  style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (item == null) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: Text(
            '물품 정보가 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    String formattedPrice = formatPrice(item!.price ?? 0);
    bool isLiked = likeStatus == 'LIKE';

    return Scaffold(
      body: Stack(
        children: [
          // 전체 화면 콘텐츠
          SingleChildScrollView(
            child: Column(
              children: [
                /// 배경 이미지 (가로 스와이프 가능)
                Stack(
                  children: [
                    SizedBox(
                      height: widget.imageSize.height,
                      width: widget.imageSize.width,
                      child: imageUrls.isNotEmpty
                          ? PageView.builder(
                              itemCount: imageUrls.length,
                              controller: pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Hero(
                                  tag: widget.heroTag,
                                  child: _buildImage(
                                    imageUrls[index],
                                    Size(widget.imageSize.width,
                                        widget.imageSize.height),
                                  ),
                                );
                              },
                            )
                          : ErrorImagePlaceholder(
                              size: Size(widget.imageSize.width, widget.imageSize.height),
                            ),
                    ),

                    /// 이미지 인디케이터
                    Positioned(
                      bottom: 24.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length,
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
                            UserProfileCircularAvatar(
                              avatarSize: const Size(40, 40),
                              profileUrl: item?.member?.profileUrl,
                            ),
                            SizedBox(width: 10.w),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item?.member?.nickname ?? '알 수 없음',
                                  style: CustomTextStyles.p2,
                                ),
                                Text(
                                  '위치 정보', //FIXME: 회원 위치 정보 표시 필요
                                  style: CustomTextStyles.p3.copyWith(
                                    color: AppColors.lightGray.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 11.w, vertical: 4.h),
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
                                      isLiked
                                          ? 'assets/images/like-heart-icon.svg'
                                          : 'assets/images/dislike-heart-icon.svg',
                                      width: 16.w,
                                      height: 16.h,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      (likeCount ?? 0).toString(),
                                      style: CustomTextStyles.p2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(color: AppColors.opacity20White, height: 1.h),

                      /// 물품 정보 및 설명
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: '${_getCategoryName(item?.itemCategory)} · ',
                                style: CustomTextStyles.p3.copyWith(
                                  color: AppColors.opacity50White,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: _formatDateTime(item?.createdDate),
                                    style: CustomTextStyles.p3.copyWith(
                                      color: AppColors.opacity50White,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),

                            Text(
                              item?.itemName ?? '제목 없음',
                              style: CustomTextStyles.h3,
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                if (item?.itemCondition != null)
                                  ItemDetailConditionTag(
                                    condition: ItemCondition.fromServerName(
                                            item!.itemCondition!)
                                        .name,
                                  ),
                                SizedBox(width: 8.w),
                                if (item?.itemTradeOptions?.isNotEmpty == true)
                                  ...item!.itemTradeOptions!.map(
                                    (option) => ItemDetailTradeOptionTag(
                                      option: _getTradeOptionName(option),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Text(
                                  '$formattedPrice원',
                                  style: CustomTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (item?.aiPrice == true)
                                  const AiBadgeWidget(),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              item?.itemDescription ?? '설명이 없습니다.',
                              style: CustomTextStyles.p2.copyWith(height: 1.4),
                            ),
                            
                            if (itemCustomTags?.isNotEmpty == true) ...[
                              SizedBox(height: 16.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: itemCustomTags!.map(
                                  (tag) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.opacity20White,
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: CustomTextStyles.p3.copyWith(
                                        color: AppColors.textColorWhite,
                                      ),
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      Divider(color: AppColors.opacity20White, height: 1.h),

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
                                    size: 13.sp,
                                    color: AppColors.opacity80White),
                                SizedBox(width: 4.w),
                                Text(
                                  locationName,
                                  style: CustomTextStyles.p2.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              height: 200.h,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: NaverMap(
                                  key: ValueKey('detail_map_${widget.itemId}'),
                                  options: NaverMapViewOptions(
                                    initialCameraPosition: NCameraPosition(
                                      target: NLatLng(
                                        item?.latitude ?? 37.5666,
                                        item?.longitude ?? 126.9784,
                                      ),
                                      zoom: 15,
                                    ),
                                  ),
                                  onMapReady: (controller) {
                                    if (item?.latitude != null && item?.longitude != null) {
                                      controller.addOverlay(
                                        NMarker(
                                          id: 'item_location',
                                          position: NLatLng(
                                            item!.latitude!,
                                            item!.longitude!,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
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

          /// 상단 고정 버튼들
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 24.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, currentImageIndex),
              child: Icon(AppIcons.navigateBefore,
                  size: 24.sp, color: AppColors.textColorWhite),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 24.w,
            child: GestureDetector(
              /// TODO: 더보기 기능 구현
              onTap: () => debugPrint('더보기 버튼 클릭'),
              child: Icon(AppIcons.dotsVertical,
                  size: 30.sp, color: AppColors.textColorWhite),
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 로더: 오류 시 플레이스홀더
  Widget _buildImage(String url, Size size) {
    final placeholder = ErrorImagePlaceholder(size: size);

    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return placeholder;

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Detail 이미지 로드 실패: $trimmed, error: $error');
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
  
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '날짜 정보 없음';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
  
  Future<void> _toggleLike() async {
    if (item?.itemId == null) return;
    
    try {
      final ItemApi itemApi = ItemApi();
      final ItemRequest request = ItemRequest(itemId: item!.itemId);
      final ItemResponse response = await itemApi.postLike(request);
      
      if (!mounted) return;
      
      setState(() {
        likeStatus = response.likeStatus;
        likeCount = response.likeCount;
      });
    } catch (e) {
      debugPrint('좋아요 상태 변경 실패: $e');
    }
  }
}
