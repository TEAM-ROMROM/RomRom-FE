import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_viewer/photo_viewer.dart';
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
import 'package:romrom_fe/widgets/common/chatting_button.dart';
import 'package:romrom_fe/widgets/common/common_success_modal.dart';
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

class ItemDetailDescriptionScreen extends StatefulWidget {
  final String itemId;
  final Size imageSize;
  final int currentImageIndex;
  final String heroTag;
  final HomeFeedItem? homeFeedItem;
  final bool isMyItem;
  final bool isRequestManagement;

  const ItemDetailDescriptionScreen({
    super.key,
    required this.itemId,
    required this.imageSize,
    required this.currentImageIndex,
    required this.heroTag,
    required this.isMyItem, // 내 물품인지 여부
    required this.isRequestManagement, // 요청 관리 화면에서 왔는지 여부
    this.homeFeedItem,
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

  /// 물품을 거래 완료로 변경
  Future<void> _markItemAsCompleted(Item item) async {
    if (item.itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('물품 ID가 없습니다'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(
        itemId: item.itemId,
        itemStatus: ItemStatus.exchanged.serverName,
      );

      await itemApi.updateItemStatus(request);

      if (mounted) {
        CommonSnackBar.show(context: context, message: '거래 완료로 변경되었습니다');

        // 상태 변경 후 화면 닫기
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 변경 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  /// 물품 삭제
  Future<void> _deleteItem(Item item) async {
    if (item.itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('물품 ID가 없습니다'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      await itemApi.deleteItem(item.itemId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('물품이 삭제되었습니다'),
            backgroundColor: AppColors.primaryYellow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('물품 삭제 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
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
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: Text('물품 정보가 없습니다.', style: TextStyle(color: Colors.white)),
        ),
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
                      child: imageUrls.isNotEmpty
                          ? PageView.builder(
                              itemCount: imageUrls.length,
                              controller: pageController,
                              onPageChanged: (i) => currentIndexVN.value = i,
                              itemBuilder: (context, i) {
                                // Hero 태그를 HomeFeed와 동일한 규칙으로 통일: 'itemImage_<uuidOrId>_<index>'
                                final String heroBaseId =
                                    'itemImage_${widget.homeFeedItem?.itemUuid ?? widget.itemId}_';
                                return PhotoViewerMultipleImage(
                                  imageUrls: imageUrls,
                                  index: i,
                                  id: heroBaseId + i.toString(),
                                );
                              },
                            )
                          : ErrorImagePlaceholder(
                              size: Size(
                                widget.imageSize.width,
                                widget.imageSize.height,
                              ),
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
                            Container(
                              constraints:
                                  !widget.isMyItem && widget.isRequestManagement
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
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Container(
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
                                    ValueListenableBuilder<bool>(
                                      valueListenable: isLikedVN,
                                      builder: (_, liked, __) {
                                        return SvgPicture.asset(
                                          liked
                                              ? 'assets/images/like-heart-icon.svg'
                                              : 'assets/images/dislike-heart-icon.svg',
                                          width: 16.w,
                                          height: 16.h,
                                        );
                                      },
                                    ),
                                    SizedBox(width: 4.w),
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
                            ),
                            !widget.isMyItem && widget.isRequestManagement
                                ? Padding(
                                    padding: EdgeInsets.only(left: 16.0.w),
                                    child: const ChattingButton(
                                      isEnabled: true,
                                      buttonText: '채팅하기',
                                      buttonWidth: 96,
                                      buttonHeight: 32,
                                    ),
                                  )
                                : const SizedBox(),
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
                        margin: EdgeInsets.only(top: 16.h, bottom: 61.h),
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
                                    scrollGesturesEnable: true, // 지도 이동
                                    zoomGesturesEnable: true, // 확대/축소
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
            top: (MediaQuery.of(context).padding.top < 59
                ? 59.h
                : MediaQuery.of(context).padding.top),
            left: 24.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, currentIndexVN.value),
              child: Icon(
                AppIcons.navigateBefore,
                size: 24.sp,
                color: AppColors.textColorWhite,
              ),
            ),
          ),
          Positioned(
            top: (MediaQuery.of(context).padding.top < 59
                ? 59.h
                : MediaQuery.of(context).padding.top),
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
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => CommonSuccessModal(
                            message: '신고가 접수되었습니다.',
                            onConfirm: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      }
                    },
                  )
                : RomRomContextMenu(
                    items: [
                      ContextMenuItem(
                        id: 'changeTradeStatus',
                        title: '거래 완료로 변경',
                        onTap: () async {
                          await _markItemAsCompleted(item!);
                        },
                      ),
                      ContextMenuItem(
                        id: 'edit',
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
                      ),
                      ContextMenuItem(
                        id: 'delete',
                        title: '삭제',
                        textColor: AppColors.itemOptionsMenuDeleteText,
                        onTap: () async {
                          await _deleteItem(item!);

                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
          ),
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
}
