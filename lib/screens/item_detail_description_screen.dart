import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/utils/location_utils.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/profile/member_profile_screen.dart';
import 'package:romrom_fe/screens/trade_location_detail_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_bottom_action_button.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_bottom_gradient.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_circle_icon_button.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_error_view.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_image_header.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_info_section.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_seller_section.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_stretch_scroll_view.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_top_actions.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_trade_location_section.dart';
import 'package:romrom_fe/widgets/skeletons/item_detail_skeleton.dart';

class ItemDetailDescriptionScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ItemDetailDescriptionScreen> createState() => _ItemDetailDescriptionScreenState();
}

class _ItemDetailDescriptionScreenState extends ConsumerState<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late final ValueNotifier<int> currentIndexVN;
  final GlobalKey _shareButtonKey = GlobalKey();

  bool deleteModalShown = false; // 삭제/존재하지 않는 사용자 모달 중복 방지 플래그
  bool _isChatCreationInProgress = false; // 채팅방 생성 요청 진행 여부 (채팅하기 중복 탭 방지)
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  Item? item;
  String locationName = '위치 정보 로딩 중...';
  String memberLocationName = '위치 정보 로딩 중...';

  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    _loadItemDetail();
  }

  Future<void> _loadItemDetail() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final ItemResponse response = await ref.read(itemRepositoryProvider).getItemDetail(widget.itemId);

      if (!mounted) return;

      setState(() {
        item = response.item;
        imageUrls = item?.imageUrlList ?? const []; // imageUrl null 제거

        // 물품 좌표를 주소로 변환
        if (item?.latitude != null && item?.longitude != null) {
          _resolveAddressName(
            latitude: item!.latitude!,
            longitude: item!.longitude!,
            formatAddress: LocationUtils.formatAddress,
            onResolved: (addressName) => locationName = addressName,
            failureLogLabel: '주소 변환 실패',
          );
        }

        // 회원 좌표를 주소로 변환
        if (item?.member?.latitude != null && item?.member?.longitude != null) {
          _resolveAddressName(
            latitude: item!.member!.latitude!,
            longitude: item!.member!.longitude!,
            formatAddress: LocationUtils.formatMediumAddress,
            onResolved: (addressName) => memberLocationName = addressName,
            failureLogLabel: '회원 주소 변환 실패',
          );
        }

        isLoading = false;
      });

      // 캐시 시드 (force=true: 서버 최신값 우선)
      final id = item?.itemId;
      if (id != null && id.isNotEmpty) {
        ref
            .read(itemLikeProvider.notifier)
            .seed(itemId: id, isLiked: response.isLiked == true, likeCount: item?.likeCount ?? 0, force: true);
      }
    } catch (e) {
      debugPrint('물품 상세 정보 로드 실패: $e');
      if (!mounted) return;

      if (ErrorUtils.getErrorMessage(e) == ErrorCode.deletedMember.koMessage) {
        CommonModal.showOnceAfterFrame(
          context: context,
          isShown: () => deleteModalShown,
          markShown: () => deleteModalShown = true,
          shouldShow: () => ErrorUtils.getErrorMessage(e) == ErrorCode.deletedMember.koMessage,
          message: '존재하지 않거나 탈퇴한 사용자입니다.',
          onConfirm: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }

      setState(() {
        hasError = true;
        errorMessage = ErrorUtils.getErrorMessage(e);
        isLoading = false;
      });
    }
  }

  /// 좌표 > 주소 문자열 (실패·없음 시 '위치 정보 없음', 물품: 짧은 주소 / 회원: 중간 주소)
  Future<void> _resolveAddressName({
    required double latitude,
    required double longitude,
    required String Function(LocationAddress address) formatAddress,
    required void Function(String addressName) onResolved,
    required String failureLogLabel,
  }) async {
    try {
      final address = await LocationService().getAddressFromCoordinates(NLatLng(latitude, longitude));
      if (!mounted) return;
      setState(() => onResolved(address != null ? formatAddress(address) : '위치 정보 없음'));
    } catch (e) {
      debugPrint('$failureLogLabel: $e');
      if (mounted) setState(() => onResolved('위치 정보 없음'));
    }
  }

  /// 물품 상태 토글 (판매중 ↔ 거래완료)
  Future<void> _toggleItemStatus(Item item) async {
    if (item.itemId == null) {
      CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    try {
      // 현재 상태의 반대로 전환
      final targetStatus = item.itemStatus == ItemStatus.available.serverName
          ? ItemStatus.exchanged.serverName
          : ItemStatus.available.serverName;

      final request = ItemRequest(itemId: item.itemId, itemStatus: targetStatus);

      await ref.read(myItemsProvider.notifier).changeStatus(request);

      if (mounted) {
        final successMessage = item.itemStatus == ItemStatus.available.serverName
            ? '교환 완료로 변경되었습니다'
            : '교환 가능으로 변경되었습니다';

        CommonSnackBar.show(context: context, message: successMessage);

        // 상태 변경 후 화면 닫기 (성공 시 true 반환)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }

  void _popWithLikeResult() {
    Navigator.of(context).pop();
  }

  Future<void> _shareItem() async {
    final itemId = item?.itemId;
    if (itemId == null) return;
    try {
      final RenderBox? box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final Rect? origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      debugPrint('ItemDetail: sharing itemId=$itemId origin=$origin');
      await shareItem(itemId: itemId, sharePositionOrigin: origin);
      debugPrint('ItemDetail: share completed for itemId=$itemId');
    } catch (e, st) {
      debugPrint('ItemDetail: share failed for itemId=$itemId - $e\n$st');
      if (mounted) CommonSnackBar.show(context: context, message: '공유에 실패했습니다.', type: SnackBarType.error);
    }
  }

  @override
  void dispose() {
    currentIndexVN.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: AppColors.primaryBlack, body: ItemDetailSkeleton());
    }

    // 작성자가 탈퇴한 게시글인 경우 별도 화면 표시
    if (errorMessage == ErrorCode.deletedMember.koMessage) {
      return const ItemDetailErrorView(message: '작성자가 탈퇴한 게시글입니다.');
    }

    if (hasError) {
      return ItemDetailErrorView(message: errorMessage, onRetry: _loadItemDetail);
    }

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        // 물품 없음 화면에서도 뒤로가기 제공
        appBar: const CommonAppBar(title: ''),
        body: Center(child: Text('물품 정보가 없습니다.', style: CustomTextStyles.h3)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithLikeResult();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 전체 화면 콘텐츠 (상단 당김 시 이미지 늘림)
            ItemDetailStretchScrollView(
              stretchBaseHeight: widget.imageSize.height,

              /// 배경 이미지 (가로 스와이프 가능)
              header: ItemDetailImageHeader(
                imageSize: widget.imageSize,
                imageUrls: imageUrls,
                pageController: pageController,
                currentIndexNotifier: currentIndexVN,
                heroBaseId: 'itemImage_${widget.homeFeedItem?.itemUuid ?? widget.itemId}_',
                isExchanged: item!.itemStatus == ItemStatus.exchanged.serverName,
              ),

              /// 아이템 설명 영역
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    /// 사용자 프사, 위치, 닉네임, 좋아요 수
                    _buildSellerSection(),
                    Divider(color: AppColors.opacity20White, height: 1.h),

                    /// 물품 정보 및 설명
                    ItemDetailInfoSection(item: item!),
                    Divider(color: AppColors.opacity20White, height: 1.h),

                    /// 거래 희망 장소
                    ItemDetailTradeLocationSection(
                      itemId: widget.itemId,
                      locationName: locationName,
                      latitude: item!.latitude,
                      longitude: item!.longitude,
                      onMapTapped: _openTradeLocationDetail,
                    ),
                  ],
                ),
              ),
            ),

            /// 상단 고정 버튼들
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 24.w,
              child: ItemDetailCircleIconButton(
                icon: AppIcons.navigateBefore,
                iconSize: 24,
                semanticLabel: '뒤로 가기',
                onTap: _popWithLikeResult,
              ),
            ),

            ItemDetailTopActions(
              isMyItem: widget.isMyItem,
              shareButtonKey: _shareButtonKey,
              isAvailableStatus: item!.itemStatus == ItemStatus.available.serverName,
              onSharePressed: _shareItem,
              onReportPressed: _openReportScreen,
              onChangeStatusPressed: () => _toggleItemStatus(item!),
              onEditPressed: _openItemModification,
              onDeletePressed: _confirmAndDeleteItem,
            ),

            // 오버레이 그레디언트 + 하단 액션 버튼
            ItemDetailBottomGradient(isVisible: widget.isChatAccessAllowed || widget.isTradeRequestAllowed),
            ItemDetailBottomActionButton(
              isVisible: widget.isChatAccessAllowed,
              isEnabled: !_isChatCreationInProgress,
              buttonText: '채팅하기',
              onPressed: _handleChatButtonPressed,
            ),
            ItemDetailBottomActionButton(
              isVisible: widget.isTradeRequestAllowed,
              isEnabled: true,
              buttonText: '요청하기',
              onPressed: _navigateToRequestScreen,
            ),
          ],
        ),
      ),
    );
  }

  /// 판매자 행 (좋아요 상태·개수는 itemLikeProvider 구독)
  Widget _buildSellerSection() {
    final id = item?.itemId;
    final hasItemId = id != null && id.isNotEmpty;
    // (좋아요 여부, 좋아요 수) 레코드 select: 이 물품 값이 바뀔 때만 재빌드
    final (isLiked, likeCount) = ref.watch(
      itemLikeProvider.select(
        (likeStateById) =>
            hasItemId ? (likeStateById[id]?.isLiked ?? false, likeStateById[id]?.likeCount ?? 0) : (false, 0),
      ),
    );

    return ItemDetailSellerSection(
      profileUrl: item?.member?.profileUrl,
      isDeletedAccount: item?.member?.accountStatus == AccountStatus.deleteAccount.serverName,
      nickname: item?.member?.nickname,
      memberLocationName: memberLocationName,
      shouldLimitNicknameWidth: !widget.isMyItem && widget.isRequestManagement,
      isLiked: isLiked,
      likeCount: likeCount,
      onProfileTap: _openSellerProfile,
      onLikeTap: _toggleLike,
    );
  }

  void _openSellerProfile() {
    if (item?.member?.memberId != null) {
      context.navigateTo(screen: MemberProfileScreen(memberId: item!.member!.memberId!));
    }
  }

  void _openTradeLocationDetail() {
    if (item?.latitude != null && item?.longitude != null) {
      context.navigateTo(
        screen: TradeLocationDetailScreen(latitude: item!.latitude!, longitude: item!.longitude!),
      );
    }
  }

  /// 신고: 신고 화면 > 접수 시 완료 모달 > 상세 닫기
  Future<void> _openReportScreen() async {
    final bool? reported = await context.navigateTo(screen: ReportScreen(itemId: widget.itemId));

    if (reported == true && mounted) {
      await CommonModal.success(
        context: context,
        message: '신고가 접수되었습니다.',
        onConfirm: () {
          Navigator.of(context).pop();
          _popWithLikeResult();
        },
      );
    }
  }

  /// 수정: 수정 화면 > 변경됐으면 상세 재조회
  Future<void> _openItemModification() async {
    final result = await context.navigateTo<Map<String, dynamic>>(
      screen: ItemModificationScreen(itemId: item?.itemId!, onClose: () => Navigator.pop(context)),
    );
    if (result != null && result['updated'] == true && mounted) {
      _loadItemDetail();
    }
  }

  /// 삭제: 확인 모달 > 삭제(myItemsProvider) > 성공 안내 후 상세 닫기(true)
  Future<void> _confirmAndDeleteItem() async {
    final isConfirmed = await context.showDeleteDialog(title: '물품 삭제', description: '정말 삭제하시겠습니까?');
    if (isConfirmed != true) return;

    final itemId = item!.itemId;
    if (itemId == null) {
      if (mounted) CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    try {
      await ref.read(myItemsProvider.notifier).delete(itemId);
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '물품이 삭제되었습니다');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }

  void _toggleLike() {
    final id = item?.itemId;
    if (id == null || id.isEmpty) return;

    // 본인글 차단은 toggle 내부에서 동기 처리 — await 없이 즉시 하트 반응
    ref.read(itemLikeProvider.notifier).toggle(id, authorMemberId: item?.member?.memberId);
  }

  /// 채팅하기: 진행 중이면 무시 > 채팅방 생성 > 목록 갱신 > 채팅방 이동
  Future<void> _handleChatButtonPressed() async {
    if (_isChatCreationInProgress) return;
    if (item == null || widget.tradeRequestHistoryId == null) {
      CommonSnackBar.show(context: context, message: '채팅방을 생성할 수 없습니다', type: SnackBarType.error);
      return;
    }

    setState(() => _isChatCreationInProgress = true);
    try {
      // 1. 채팅방 생성 + 채팅 목록 재조회 (이미 있으면 기존 방 반환, chatRoomsProvider 경유)
      final chatRoom = await ref
          .read(chatRoomsProvider.notifier)
          .createRoom(opponentMemberId: item!.member!.memberId!, tradeRequestHistoryId: widget.tradeRequestHistoryId!);

      if (!mounted) return;

      // 2. 채팅방 화면으로 이동
      context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoom.chatRoomId!));
    } catch (e) {
      debugPrint('채팅방 생성 실패: $e');
      if (!mounted) return;

      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    } finally {
      // 버튼 잠금 해제 (성공·실패 공통)
      if (mounted) setState(() => _isChatCreationInProgress = false);
    }
  }

  void _navigateToRequestScreen() {
    if (item == null) return;

    context.navigateTo(
      screen: TradeRequestScreen(targetItem: item!, targetImageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null),
    );
  }
}
