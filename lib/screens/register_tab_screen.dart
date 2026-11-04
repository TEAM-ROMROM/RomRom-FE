import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/location_verification_purpose.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';
import 'package:romrom_fe/widgets/register_tab/register_tab_floating_register_button.dart';
import 'package:romrom_fe/widgets/register_tab/register_tab_item_tile.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/notification_permission_prompt_modal.dart';
import 'dart:async';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/location_verification_gate.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';

import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/models/trade_complete_partner_selection.dart';
import 'package:romrom_fe/screens/trade_complete_partner_select_screen.dart';

class RegisterTabScreen extends ConsumerStatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  ConsumerState<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends ConsumerState<RegisterTabScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isScrolling = false;
  // 스크롤 종료 판정 대기 시간
  static const Duration _scrollIdleDelay = Duration(milliseconds: 500);
  Timer? _scrollTimer;

  // 물품 등록 제한
  static const int _maxAvailableItemCount = 10;

  // FAB 중복 탭 방지
  bool _isFabProcessing = false;

  // 에러 뷰 다시 시도 진행 중 여부 (reload는 로딩 상태를 내지 않아 화면에서 추적)
  bool _isRetryingMyItems = false;

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.selling;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();

    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: AppMotion.standard));

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  /// 첫 물건 등록 후 홈탭으로 전환하고 코치마크 표시
  void _navigateToHomeAndShowCoachMark() {
    ref.read(coachMarkTriggerProvider.notifier).trigger();
    ref.read(currentTabIndexProvider.notifier).set(0);
  }

  void _scrollListener() {
    // 값이 바뀔 때만 리빌드 (스크롤 이벤트마다 setState 금지)
    if (!_isScrolling) setState(() => _isScrolling = true);
    _scrollTimer?.cancel();
    _scrollTimer = Timer(_scrollIdleDelay, () {
      if (mounted && _isScrolling) setState(() => _isScrolling = false);
    });

    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myItemsAsync = ref.watch(myItemsProvider);
    final isLoading = myItemsAsync.isLoading;
    final myItems = myItemsAsync.valueOrNull;
    // 불러오기 실패 + 이전 값 없음 > 에러 뷰 (이전 값 있으면 목록 유지)
    final hasLoadErrorWithoutItems = myItemsAsync.hasError && myItems == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: RefreshIndicator(
                color: AppColors.primaryYellow,
                backgroundColor: AppColors.transparent,
                displacement: MediaQuery.of(context).padding.top + 58.h + 62.h,
                onRefresh: () async {
                  try {
                    await ref.read(myItemsProvider.notifier).reload();
                  } finally {
                    if (mounted) setState(() => _isScrolling = false);
                  }
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: GlassHeaderDelegate(
                        headerTitle: '나의 등록된 물품',
                        toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                          animation: _toggleAnimation,
                          isRightSelected: _currentTabStatus == MyItemToggleStatus.completed,
                          onLeftTap: () => _onToggleChanged(MyItemToggleStatus.selling),
                          onRightTap: () => _onToggleChanged(MyItemToggleStatus.completed),
                          leftText: '교환 가능',
                          rightText: '교환 완료',
                        ),
                        statusBarHeight: MediaQuery.of(context).padding.top,
                        toolbarHeight: 58.h,
                        toggleHeight: 62.h,
                        expandedExtra: 16.h,
                        enableBlur: _isScrolled,
                      ),
                    ),
                    ..._buildItemSlivers(
                      isLoading: isLoading,
                      hasLoadErrorWithoutItems: hasLoadErrorWithoutItems,
                      myItems: myItems,
                    ),
                  ],
                ),
              ),
            ),
            _buildRegisterFabStacked(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemSlivers({required bool isLoading, required bool hasLoadErrorWithoutItems, required myItems}) {
    if (isLoading && myItems == null) {
      return const [RegisterTabSkeletonSliver()];
    }

    if (hasLoadErrorWithoutItems) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView.error(
            centerText: '물품을 불러오지 못했어요',
            onRetry: _onRetryMyItemsPressed,
            isRetrying: _isRetryingMyItems,
          ),
        ),
      ];
    }

    final List<Item> filteredItems = switch (_currentTabStatus) {
      MyItemToggleStatus.selling => myItems?.available ?? const [],
      MyItemToggleStatus.completed => myItems?.exchanged ?? const [],
      _ => const [],
    };

    if (filteredItems.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())];
    }

    final itemCountWithSeparators = filteredItems.length * 2 - 1;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(right: 24.w, bottom: 16.h),
          child: Text(
            _currentTabStatus == MyItemToggleStatus.selling
                ? '${filteredItems.length}/10개'
                : '${filteredItems.length}개',
            textAlign: TextAlign.right,
            style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w400),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
            );
          }
          final item = filteredItems[index ~/ 2];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: RegisterTabItemTile(
              item: item,
              isSellingTab: _currentTabStatus == MyItemToggleStatus.selling,
              onTap: () => _navigateToItemDetail(item),
              onChangeStatusTap: () => _showChangeStatusConfirmDialog(item),
              onEditTap: () => _navigateToEditItem(item),
              onDeleteTap: () => _showDeleteConfirmDialog(item),
            ),
          );
        }, childCount: itemCountWithSeparators),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
    ];
  }

  /// 에러 뷰 다시 시도: 진행 중이면 무시 > 내 물품 재조회
  Future<void> _onRetryMyItemsPressed() async {
    if (_isRetryingMyItems) return;
    setState(() => _isRetryingMyItems = true);
    try {
      await ref.read(myItemsProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _isRetryingMyItems = false);
    }
  }

  /// 탭별 빈 목록 안내 (교환 가능·전체 > 등록 안내, 교환 완료 > 교환 완료 안내)
  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: AppIcons.register,
      centerText: _currentTabStatus.emptyItemsTitle,
      descriptionText: _currentTabStatus.emptyItemsDescription,
    );
  }

  Widget _buildRegisterFabStacked() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32.h,
      child: RegisterTabFloatingRegisterButton(isHidden: _isScrolling, onTap: _onRegisterButtonPressed),
    );
  }

  /// 등록 버튼: 중복 탭 차단 > GPS 동네 인증 > 등록 가능 개수 확인 > 등록 화면 > 알림 권한 1회 안내 > 첫 등록이면 홈 코치마크
  Future<void> _onRegisterButtonPressed() async {
    if (_isFabProcessing) return;
    setState(() => _isFabProcessing = true);
    try {
      final isLocationVerified = await ref
          .read(locationVerificationGateProvider)
          .ensureVerified(context, purpose: LocationVerificationPurpose.itemRegistration);
      if (!mounted || !isLocationVerified) return;

      // 거래중(AVAILABLE) 물품 개수 확인 - 최대 10개 제한
      // provider 미로딩 시(null) 등록 차단 — stale 0으로 제한 우회 방지
      final myItemsAsyncValue = ref.read(myItemsProvider);
      final myItemsValue = myItemsAsyncValue.valueOrNull;
      if (myItemsValue == null) {
        // 문구 분기: 실제 로딩 중(첫 로드·재시도) / 불러오기 실패
        final isMyItemsLoading = myItemsAsyncValue.isLoading || _isRetryingMyItems;
        final blockedMessage = isMyItemsLoading ? '물품 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.' : '물품 정보를 불러오지 못했어요. 다시 시도해 주세요.';
        if (mounted) {
          CommonSnackBar.show(context: context, message: blockedMessage, type: SnackBarType.error);
        }
        return;
      }
      // 한도 도달: 이유 + 해결 방법(교환 완료 처리·삭제) 안내
      if (myItemsValue.available.length >= _maxAvailableItemCount) {
        if (mounted) {
          await CommonModal.error(
            context: context,
            message: '교환 가능한 물품은 최대 $_maxAvailableItemCount개까지 등록할 수 있어요.\n교환이 끝난 물품은 교환 완료로 바꾸거나\n삭제한 뒤 등록해 주세요.',
            onConfirm: () => Navigator.of(context).pop(),
          );
        }
        return;
      }

      final result = await context.navigateTo(
        screen: ItemRegisterScreen(
          onClose: () {
            Navigator.pop(context);
          },
        ),
      );

      if (!mounted) return;
      // 등록 성공(결과 Map) 직후 알림 권한 1회 안내 (코치마크 전)
      if (result is Map<String, dynamic>) await showNotificationPermissionPromptOnce(context, ref);
      if (!mounted) return;

      debugPrint('====================================');
      debugPrint('ItemRegisterScreen에서 돌아옴: result=$result');
      debugPrint('result type: ${result.runtimeType}');
      if (result is Map<String, dynamic>) {
        debugPrint('  - isFirstItemPosted: ${result['isFirstItemPosted']}');
      }
      debugPrint('====================================');

      if (result is Map<String, dynamic> && result['isFirstItemPosted'] == true) {
        debugPrint('첫 물건 등록 확인! 홈 탭으로 이동 시작...');
        _navigateToHomeAndShowCoachMark();
      } else {
        debugPrint('첫 물품 등록 조건 불충족: isFirstItemPosted=${result is Map ? result['isFirstItemPosted'] : 'N/A'}');
      }
    } finally {
      if (mounted) setState(() => _isFabProcessing = false);
    }
  }

  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus == newStatus) return;
    if (newStatus == MyItemToggleStatus.completed) {
      _toggleAnimationController.forward();
    } else {
      _toggleAnimationController.reverse();
    }
    setState(() => _currentTabStatus = newStatus);
  }

  Future<void> _navigateToItemDetail(Item item) async {
    if (item.itemId == null) return;
    await context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: item.itemId!,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: 'itemImage_${item.itemId}_0',
        isMyItem: true,
        isRequestManagement: false,
      ),
    );
    // 상태 변경/삭제 시 myItemsProvider가 notifier 경유로 자동 갱신
  }

  Future<void> _navigateToEditItem(Item item) async {
    await context.navigateTo(
      screen: ItemModificationScreen(
        itemId: item.itemId,
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
    // 수정 저장 시 RegisterInputForm이 myItemsProvider.edit 호출 > ref.watch로 목록 자동 갱신
  }

  Future<void> _showChangeStatusConfirmDialog(Item item) async {
    final isToCompleted = _currentTabStatus == MyItemToggleStatus.selling;

    if (isToCompleted) {
      // 상대 선택 결과: 채팅 상대 > 채팅방에서 교환 완료 요청, 앱 밖 교환 > 물품 상태만 교환 완료로 변경
      final selection = await context.navigateTo<TradeCompletePartnerSelection>(
        screen: TradeCompletePartnerSelectScreen(item: item),
      );
      if (!mounted || selection == null) return;
      final chatRoomId = selection.chatRoomId;
      if (selection.isCompletedOutsideApp || chatRoomId == null) {
        await _toggleItemStatus(item);
        return;
      }
      context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoomId, autoTriggerExchangeRequest: true));
    } else {
      final result = await context.showDeleteDialog(
        title: '교환 가능으로 변경하시겠습니까?',
        description: '교환 가능으로 변경하시겠습니까?',
        confirmText: '확인',
      );
      if (result == true) {
        await _toggleItemStatus(item);
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(Item item) async {
    final isConfirmed = await context.showItemDeleteConfirmDialog();
    if (isConfirmed == true) {
      await _deleteItem(item);
    }
  }

  Future<void> _toggleItemStatus(Item item) async {
    if (item.itemId == null) {
      CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    try {
      final isChangingToExchanged = _currentTabStatus == MyItemToggleStatus.selling;
      final targetStatus = isChangingToExchanged ? ItemStatus.exchanged.serverName : ItemStatus.available.serverName;
      await ref.read(myItemsProvider.notifier).changeStatus(ItemRequest(itemId: item.itemId, itemStatus: targetStatus));
      if (!mounted) return;
      // 변경 방향별 성공 안내 (상세 화면과 같은 문구)
      CommonSnackBar.show(context: context, message: isChangingToExchanged ? '교환 완료로 변경되었습니다' : '교환 가능으로 변경되었습니다');
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }

  Future<void> _deleteItem(Item item) async {
    if (item.itemId == null) {
      CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    try {
      await ref.read(myItemsProvider.notifier).delete(item.itemId!);
      if (mounted) {
        CommonSnackBar.show(context: context, message: '물품이 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }
}
