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
import 'package:romrom_fe/screens/trade_complete_partner_select_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_bottom_action_button.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_bottom_gradient.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_circle_icon_button.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/error_scaffold.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_image_header.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_info_section.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_seller_section.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_stretch_scroll_view.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_top_actions.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_trade_location_section.dart';
import 'package:romrom_fe/widgets/skeletons/item_detail_skeleton.dart';

part 'item_detail/item_detail_loading.dart';
part 'item_detail/item_detail_owner_actions.dart';
part 'item_detail/item_detail_viewer_actions.dart';

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

/// 물품 상세 화면 상태 필드 (책임별 mixin이 공유, part 파일: item_detail/)
abstract class _ItemDetailDescriptionScreenStateFields extends ConsumerState<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late final ValueNotifier<int> currentIndexVN;
  final GlobalKey _shareButtonKey = GlobalKey();

  bool deleteModalShown = false; // 삭제/존재하지 않는 사용자 모달 중복 방지 플래그
  bool _isChatCreationInProgress = false; // 채팅방 생성 요청 진행 여부 (채팅하기 중복 탭 방지)
  bool _isStatusChangeInProgress = false; // 교환 가능 변경 요청 진행 여부 (메뉴 중복 탭 방지)
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  // 삭제됐거나 없는 물품 (재시도해도 같은 결과 > 다시 시도 없이 안내만)
  bool _isDeletedItem = false;

  Item? item;
  String locationName = '위치 정보 로딩 중...';
  String memberLocationName = '위치 정보 로딩 중...';

  List<String> imageUrls = [];
}

/// 물품 상세 화면: 이미지 헤더·판매자·물품 정보·거래 장소·하단 버튼 구성 (조회·내 물품 관리·보는 사람 액션은 mixin)
class _ItemDetailDescriptionScreenState extends _ItemDetailDescriptionScreenStateFields
    with _ItemDetailLoading, _ItemDetailOwnerActions, _ItemDetailViewerActions {
  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    // 피드에서 넘겨받은 목록 원본이 있으면 스켈레톤 없이 먼저 그림 > 상세 응답 오면 교체
    final previewItem = widget.homeFeedItem?.previewItemFor(widget.itemId);
    if (previewItem != null) {
      _applyItem(previewItem);
      isLoading = false;
    }
    _loadItemDetail();
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
      return const ErrorScaffold(message: '작성자가 탈퇴한 게시글입니다.');
    }

    // 삭제됐거나 없는 물품: 다시 시도 없이 안내
    if (_isDeletedItem) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: CommonAppBar(title: ''),
        body: EmptyStateView(
          icon: AppIcons.trash,
          centerText: '삭제된 물품이에요',
          descriptionText: '판매자가 삭제했거나\n더 이상 볼 수 없는 물품이에요',
        ),
      );
    }

    if (hasError) {
      return ErrorScaffold(message: errorMessage, onRetry: _loadItemDetail);
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
              onChangeStatusPressed: () => _onChangeStatusPressed(item!),
              onEditPressed: _openItemModification,
              onDeletePressed: _confirmAndDeleteItem,
            ),

            // 오버레이 그레디언트 + 하단 액션 버튼
            ItemDetailBottomGradient(isVisible: widget.isChatAccessAllowed || _isTradeRequestButtonVisible),
            ItemDetailBottomActionButton(
              isVisible: widget.isChatAccessAllowed,
              isEnabled: !_isChatCreationInProgress,
              buttonText: '채팅하기',
              onPressed: _handleChatButtonPressed,
            ),
            ItemDetailBottomActionButton(
              isVisible: _isTradeRequestButtonVisible,
              isEnabled: true,
              buttonText: '요청하기',
              onPressed: _navigateToRequestScreen,
            ),
          ],
        ),
      ),
    );
  }

  /// 요청하기 버튼 노출: 요청 허용 진입 + 교환 완료 아닌 물품 (상태 누락 시 기존처럼 노출)
  bool get _isTradeRequestButtonVisible =>
      widget.isTradeRequestAllowed && item?.itemStatus != ItemStatus.exchanged.serverName;

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
}
