import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/services/location_service.dart';

import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_status.dart';
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
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';
import 'package:romrom_fe/utils/location_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';
import 'package:romrom_fe/screens/trade_location_detail_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';

class ItemDetailDescriptionScreen extends StatefulWidget {
  final String itemId;
  final Size imageSize;
  final int currentImageIndex;
  final String heroTag;
  final HomeFeedItem? homeFeedItem;
  final bool isMyItem;
  final bool isRequestManagement;
  final String? tradeRequestHistoryId;
  final bool isChatAccessAllowed; // 채팅 접근 권한 여부
  final bool isTradeRequestAllowed; // 거래 요청 버튼 표시 여부

  const ItemDetailDescriptionScreen({
    super.key,
    required this.itemId,
    required this.imageSize,
    required this.currentImageIndex,
    required this.heroTag,
    required this.isMyItem, // 내 물품인지 여부
    required this.isRequestManagement, // 요청 관리 화면에서 왔는지 여부
    this.homeFeedItem,
    this.tradeRequestHistoryId, // 거래 요청 ID (채팅방 생성용)
    this.isChatAccessAllowed = false, // 채팅 접근 권한 기본값: false
    this.isTradeRequestAllowed = false, // 거래 요청 버튼 기본값: false
  });

  @override
  State<ItemDetailDescriptionScreen> createState() =>
      _ItemDetailDescriptionScreenState();
}

class _ItemDetailDescriptionScreenState
    extends State<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late final ValueNotifier<int> currentIndexVN;
  late final ValueNotifier<bool> isLikedVN;
  late final ValueNotifier<int> likeCountVN;
  bool _likeInFlight = false;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  Item? item;
  List<ItemImage>? itemImages;
  String locationName = '위치 정보 로딩 중...';
  String memberLocationName = '위치 정보 로딩 중...';

  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    isLikedVN = ValueNotifier<bool>(false);
    likeCountVN = ValueNotifier<int>(0);
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
        itemImages = item?.itemImages;
        isLikedVN.value = (response.isLiked == true);
        likeCountVN.value = item?.likeCount ?? 0;

        imageUrls =
            itemImages
                ?.map((e) => e.imageUrl) // String?로 매핑
                .whereType<String>() // null 제거
                .toList() ??
            const [];

        // 물품 좌표를 주소로 변환
        if (item?.latitude != null && item?.longitude != null) {
          _getAddressFromCoordinates(item!.latitude!, item!.longitude!);
        }

        // 회원 좌표를 주소로 변환
        if (item?.member?.latitude != null && item?.member?.longitude != null) {
          _getMemberAddressFromCoordinates(
            item!.member!.latitude!,
            item!.member!.longitude!,
          );
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
          locationName = LocationUtils.formatAddress(address);
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

  Future<void> _getMemberAddressFromCoordinates(double lat, double lng) async {
    try {
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(
        NLatLng(lat, lng),
      );

      if (address != null) {
        setState(() {
          memberLocationName = LocationUtils.formatMediumAddress(address);
        });
      } else {
        setState(() {
          memberLocationName = '위치 정보 없음';
        });
      }
    } catch (e) {
      debugPrint('회원 주소 변환 실패: $e');
      setState(() {
        memberLocationName = '위치 정보 없음';
      });
    }
  }

  String _getCategoryName(String? serverName) {
    if (serverName == null) return '카테고리 없음';
    try {
      return ItemCategories.fromServerName(serverName).label;
    } catch (e) {
      return '카테고리 없음';
    }
  }

  String _getTradeOptionName(String serverName) {
    try {
      return ItemTradeOption.fromServerName(serverName).label;
    } catch (e) {
      return serverName;
    }
  }

  /// 물품 상태 토글 (판매중 ↔ 거래완료)
  Future<void> _toggleItemStatus(Item item) async {
    if (item.itemId == null) {
      CommonSnackBar.show(
        context: context,
        message: '물품 ID가 없습니다',
        type: SnackBarType.info,
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      // 현재 상태의 반대로 전환
      final targetStatus = item.itemStatus == ItemStatus.available.serverName
          ? ItemStatus.exchanged.serverName
          : ItemStatus.available.serverName;

      final request = ItemRequest(
        itemId: item.itemId,
        itemStatus: targetStatus,
      );

      await itemApi.updateItemStatus(request);

      if (mounted) {
        final successMessage =
            item.itemStatus == ItemStatus.available.serverName
            ? '거래 완료로 변경되었습니다'
            : '판매중으로 변경되었습니다';

        CommonSnackBar.show(context: context, message: successMessage);

        // 상태 변경 후 화면 닫기 (성공 시 true 반환)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(
          context: context,
          message: '상태 변경 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// 물품 삭제
  Future<void> _deleteItem(Item item) async {
    if (item.itemId == null) {
      CommonSnackBar.show(
        context: context,
        message: '물품 ID가 없습니다',
        type: SnackBarType.info,
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      await itemApi.deleteItem(item.itemId!);

      if (mounted) {
        CommonSnackBar.show(context: context, message: '물품이 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(
          context: context,
          message: '물품 삭제 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    currentIndexVN.dispose();
    pageController.dispose();
    isLikedVN.dispose();
    likeCountVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              AppIcons.navigateBefore,
              color: AppColors.textColorWhite,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                style: CustomTextStyles.p1.copyWith(
                  color: AppColors.textColorWhite,
                ),
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
                  style: CustomTextStyles.p2.copyWith(
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(child: Text('물품 정보가 없습니다.', style: CustomTextStyles.h3)),
      );
    }

    String formattedPrice = formatPrice(item!.price ?? 0);

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
                      child: PageView.builder(
                        itemCount: imageUrls.isNotEmpty
                            ? imageUrls.length
                            : 1, // ← 최소 1페이지
                        controller: pageController,
                        onPageChanged: (i) => currentIndexVN.value = i,
                        itemBuilder: (context, i) {
                          final hasImages = imageUrls.isNotEmpty;
                          final safeIndex = hasImages ? i : 0;
                          final String heroBaseId =
                              'itemImage_${widget.homeFeedItem?.itemUuid ?? widget.itemId}_';

                          return PhotoViewerMultipleImage(
                            // 이미지가 없으면 더미 URL을 넘겨서 로딩 실패 → errorWidget 호출
                            imageUrls: hasImages
                                ? imageUrls
                                : const ['__NO_IMAGE__'],
                            index: safeIndex,
                            id: heroBaseId + safeIndex.toString(),
                            onPageChanged: (idx) {
                              currentIndexVN.value = idx;
                              if (pageController.hasClients) {
                                final now = pageController.page?.round();
                                if (now != idx) {
                                  pageController.jumpToPage(
                                    idx,
                                  ); // 닫기 전에 목적지 미리 맞추기
                                }
                              }
                            },

                            // 로딩 인디케이터
                            placeholder: (ctx, url) => const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                            ),

                            // 이미지 없음/로딩 실패 시
                            errorWidget: (ctx, url, err) => Center(
                              child: ErrorImagePlaceholder(
                                size: widget.imageSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    /// 이미지 인디케이터
                    Positioned(
                      bottom: 24.h,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder<int>(
                        valueListenable: currentIndexVN,
                        builder: (_, current, __) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (index) => Container(
                                width: 6.w,
                                height: 6.w,
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: current == index
                                      ? AppColors.primaryYellow
                                      : AppColors.opacity50White,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    IgnorePointer(
                      ignoring:
                          item?.itemStatus != ItemStatus.exchanged.serverName,
                      child: SizedBox(
                        height: widget.imageSize.height,
                        width: widget.imageSize.width,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors
                                  .itemDetailBlackGradient, // 검정색 그라데이션
                              stops: const [0.0, 0.15, 0.60, 1.0],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// 거래완료 오버레이 (검정 50%)
                    if (item?.itemStatus == ItemStatus.exchanged.serverName)
                      IgnorePointer(
                        child: Container(
                          height: widget.imageSize.height,
                          width: widget.imageSize.width,
                          color: AppColors.opacity50Black,
                        ),
                      ),

                    /// 거래완료 글라스모피즘 배지 (이미지 중앙)
                    if (item?.itemStatus == ItemStatus.exchanged.serverName)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                width: 122.w,
                                height: 47.h,
                                decoration: BoxDecoration(
                                  color: AppColors.opacity10White,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(
                                    color: AppColors.textColorWhite,
                                    width: 1.w,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '거래 완료',
                                  style: CustomTextStyles.p1.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textColorWhite,
                                  ),
                                ),
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
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 16.h),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (item?.member?.memberId != null) {
                                  context.navigateTo(
                                    screen: ProfileScreen(
                                      memberId: item!.member!.memberId!,
                                    ),
                                  );
                                }
                              },
                              child: UserProfileCircularAvatar(
                                avatarSize: const Size(40, 40),
                                profileUrl: item?.member?.profileUrl,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            GestureDetector(
                              onTap: () {
                                if (item?.member?.memberId != null) {
                                  context.navigateTo(
                                    screen: ProfileScreen(
                                      memberId: item!.member!.memberId!,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                constraints:
                                    !widget.isMyItem &&
                                        widget.isRequestManagement
                                    ? BoxConstraints(maxWidth: 120.w)
                                    : null, // 최대 너비 설정
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item?.member?.nickname ?? '알 수 없음',
                                      style: CustomTextStyles.p2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      memberLocationName,
                                      style: CustomTextStyles.p3.copyWith(
                                        color: AppColors.lightGray.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Column(
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable: isLikedVN,
                                    builder: (_, liked, __) {
                                      return SvgPicture.asset(
                                        liked
                                            ? 'assets/images/like-heart-icon.svg'
                                            : 'assets/images/dislike-heart-icon.svg',
                                        width: 30.w,
                                        height: 30.h,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 2.h),
                                  ValueListenableBuilder<int>(
                                    valueListenable: likeCountVN,
                                    builder: (_, likeCount, __) {
                                      return Text(
                                        likeCount.toString(),
                                        style: CustomTextStyles.p2,
                                      );
                                    },
                                  ),
                                ],
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
                                text:
                                    '${_getCategoryName(item?.itemCategory)} · ',
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
                                      item!.itemCondition!,
                                    ).label,
                                  ),
                                SizedBox(width: 4.w),
                                if (item?.itemTradeOptions?.isNotEmpty == true)
                                Wrap(
                                  spacing: 4.w,
                                  children: [...item!.itemTradeOptions!.map(
                                    (option) => ItemDetailTradeOptionTag(
                                      option: _getTradeOptionName(option),
                                      ),
                                    ),
                                  ],
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
                                if (item?.isAiPredictedPrice == true)
                                  const AiBadgeWidget(),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              item?.itemDescription ?? '설명이 없습니다.',
                              style: CustomTextStyles.p2.copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),

                      Divider(color: AppColors.opacity20White, height: 1.h),

                      /// 거래 희망 장소
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 16.h, bottom: 120.h),
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
                                Icon(
                                  AppIcons.location,
                                  size: 13.sp,
                                  color: AppColors.opacity80White,
                                ),
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
                                  forceGesture: true,
                                  options: NaverMapViewOptions(
                                    initialCameraPosition: NCameraPosition(
                                      target: NLatLng(
                                        item?.latitude ?? 37.5666,
                                        item?.longitude ?? 126.9784,
                                      ),
                                      zoom: 15,
                                    ),
                                    scrollGesturesEnable: false,
                                    zoomGesturesEnable: false,
                                  ),
                                  onMapReady: (controller) {
                                    if (item?.latitude != null &&
                                        item?.longitude != null) {
                                      controller.addOverlay(
                                        NMarker(
                                          id: 'item_location',
                                          position: NLatLng(
                                            item!.latitude!,
                                            item!.longitude!,
                                          ),
                                          icon: const NOverlayImage.fromAssetImage(
                                            "assets/images/location-pin-icon.png",
                                          ),
                                          size: NSize(33.w, 47.h),
                                        ),
                                      );
                                    }
                                  },
                                  // 지도 탭 시 거래 희망 장소 상세 페이지로 이동
                                  onMapTapped: (point, latLng) {
                                    if (item?.latitude != null &&
                                        item?.longitude != null) {
                                      context.navigateTo(
                                        screen: TradeLocationDetailScreen(
                                          latitude: item!.latitude!,
                                          longitude: item!.longitude!,
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
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 24.w,
            child: GestureDetector(
              onTap: () async {
                // 뒤로갈 때 좋아요가 취소된 상태면 목록에 반영되도록 정보 반환
                if (isLikedVN.value == false) {
                  Navigator.of(context).pop(widget.itemId);
                } else {
                  Navigator.of(context).pop();
                }
              },

              child: Icon(
                AppIcons.navigateBefore,
                size: 24.sp,
                color: AppColors.textColorWhite,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            right: 24.w,
            child: !widget.isMyItem
                ? ReportMenuButton(
                    onReportPressed: () async {
                      final bool? reported = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReportScreen(itemId: widget.itemId),
                        ),
                      );

                      if (reported == true && mounted) {
                        await CommonModal.success(
                          context: context,
                          message: '신고가 접수되었습니다.',
                          onConfirm: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        );
                      }
                    },
                  )
                : RomRomContextMenu(
                    items: [
                      ContextMenuItem(
                        id: 'changeTradeStatus',
                        icon: AppIcons.change,
                        title:
                            item?.itemStatus == ItemStatus.available.serverName
                            ? '거래완료로 변경'
                            : '판매중으로 변경',
                        onTap: () async {
                          await _toggleItemStatus(item!);
                        },
                        showDividerAfter: true,
                      ),
                      ContextMenuItem(
                        id: 'edit',
                        icon: AppIcons.edit,
                        title: '수정',
                        onTap: () {
                          context.navigateTo(
                            screen: ItemModificationScreen(
                              itemId: item?.itemId!,
                              onClose: () {
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                        showDividerAfter: true,
                      ),
                      ContextMenuItem(
                        id: 'delete',
                        icon: AppIcons.trash,
                        iconColor: AppColors.itemOptionsMenuRedIcon,
                        title: '삭제',
                        textColor: AppColors.itemOptionsMenuRedText,
                        onTap: () async {
                          await _deleteItem(item!);

                          if (mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ],
                  ),
          ),
          widget.isChatAccessAllowed || widget.isTradeRequestAllowed
              ? Positioned(
                  bottom: 0,
                  child: Container(
                    height: 113.h,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors
                            .itemDetailBottomBlackGradient, // 검정색 그라데이션
                        stops: const [0.0, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                )
              : Container(), // 오버레이 그레디언트
          widget.isChatAccessAllowed
              ? Positioned(
                  bottom: Platform.isAndroid ? 28.h : 49.h,
                  left: 0,
                  right: 0,
                  child: CustomFloatingButton(
                    isEnabled: true,
                    enabledOnPressed: _handleChatButtonPressed,
                    buttonText: '채팅하기',
                    buttonWidth: 346,
                    buttonHeight: 56,
                  ),
                )
              : const SizedBox(),
          widget.isTradeRequestAllowed
              ? Positioned(
                  bottom: Platform.isAndroid ? 28.h : 49.h,
                  left: 0,
                  right: 0,
                  child: CustomFloatingButton(
                    isEnabled: true,
                    enabledOnPressed: _navigateToRequestScreen,
                    buttonText: '요청하기',
                    buttonWidth: 346,
                    buttonHeight: 56,
                  ),
                )
              : const SizedBox(),
        ],
      ),
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
    if (_likeInFlight) return;

    // 내가 작성한 게시글인지 확인
    final isCurrentMember = await MemberManager.isCurrentMember(
      item?.member?.memberId,
    );
    if (isCurrentMember) {
      if (mounted) {
        CommonSnackBar.show(
          context: context,
          message: '본인 게시글에는 좋아요를 누를 수 없습니다.',
          type: SnackBarType.info,
        );
      }
      return;
    }

    _likeInFlight = true;
    final prevLiked = isLikedVN.value;
    final prevCount = likeCountVN.value;

    // 1) 빠른 UI 업데이트
    isLikedVN.value = !prevLiked;
    likeCountVN.value = prevLiked
        ? (prevCount > 0 ? prevCount - 1 : 0)
        : (prevCount + 1);

    try {
      final itemApi = ItemApi();
      final req = ItemRequest(itemId: item!.itemId);
      final res = await itemApi.postLike(req);

      // 2) 서버 결과로 보정(서버-클라 불일치 대비)
      if (!mounted) return;
      isLikedVN.value = (res.isLiked == true);
      likeCountVN.value = res.item?.likeCount ?? likeCountVN.value;
    } catch (e) {
      debugPrint('좋아요 실패: $e');
      // 3) 실패 롤백
      isLikedVN.value = prevLiked;
      likeCountVN.value = prevCount;
    } finally {
      _likeInFlight = false;
    }
  }

  /// 채팅하기 버튼 핸들러
  Future<void> _handleChatButtonPressed() async {
    if (item == null || widget.tradeRequestHistoryId == null) {
      CommonSnackBar.show(
        context: context,
        message: '채팅방을 생성할 수 없습니다',
        type: SnackBarType.error,
      );
      return;
    }

    try {
      // 1. 채팅방 생성 (이미 있으면 기존 방 반환)
      final chatApi = ChatApi();
      final chatRoom = await chatApi.createChatRoom(
        opponentMemberId: item!.member!.memberId!,
        tradeRequestHistoryId: widget.tradeRequestHistoryId!,
      );

      if (!mounted) return;

      // 2. 채팅방 화면으로 이동
      context.navigateTo(
        screen: ChatRoomScreen(chatRoomId: chatRoom.chatRoomId!),
      );
    } catch (e) {
      debugPrint('채팅방 생성 실패: $e');
      if (!mounted) return;

      CommonSnackBar.show(
        context: context,
        message: '채팅방 생성 실패: ${ErrorUtils.getErrorMessage(e)}',
        type: SnackBarType.error,
      );
    }
  }

  void _navigateToRequestScreen() {
    if (item == null) return;

    context.navigateTo(
      screen: TradeRequestScreen(
        targetItem: item!,
        targetImageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null,
      ),
    );
  }
}
