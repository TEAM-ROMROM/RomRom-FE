import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/sent_requests_focus_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/states/my_items_state.dart';
import 'package:romrom_fe/states/trade_requests_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/request_management/request_item_cards_carousel.dart';
import 'package:romrom_fe/widgets/request_management/request_list_header.dart';
import 'package:romrom_fe/widgets/request_management/request_page_indicator.dart';
import 'package:romrom_fe/widgets/request_management/request_received_list.dart';
import 'package:romrom_fe/widgets/request_management/request_sent_list.dart';
import 'package:romrom_fe/widgets/request_management/trade_request_option_edit_sheet.dart';

part 'request_management/request_management_request_actions.dart';

/// 요청관리 탭: 내 물품 카드(myItemsProvider 판매중 전체 구독) + 받은·보낸 요청(tradeRequestsProvider 구독, 차단 회원 제외)
/// 조회·정렬·읽음·수정·취소는 notifier 위임, 화면은 카드 선택·토글·이동·안내만 담당
class RequestManagementTabScreen extends ConsumerStatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  ConsumerState<RequestManagementTabScreen> createState() => _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends ConsumerState<RequestManagementTabScreen>
    with TickerProviderStateMixin, _RequestManagementRequestActions {
  final ScrollController _scrollController = ScrollController();

  // 진행 중인 거래 요청 전체 로드 수 (0 초과 = 보낸 요청·카드 로딩 표시, 받은 요청 로딩은 상태 값)
  int _activeLoadCount = 0;

  // 앱 포그라운드 복귀 감지 (요청관리 탭 표시 중이면 보낸 요청 백그라운드 재조회)
  late final AppLifecycleListener _appLifecycleListener;

  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 현재 선택된 카드 인덱스
  int _currentCardIndex = 0;

  // 카드 컨트롤러 (초기값 0.578 = 227/393, didChangeDependencies에서 실제 화면 크기로 재생성)
  PageController _cardController = PageController(initialPage: 0, viewportFraction: 227 / 393);
  bool _isCardControllerInitialized = false;

  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 받은 요청, true: 보낸 요청)
  bool _isRightSelected = false;

  // 완료된 요청 표시 여부
  @override
  bool _showCompletedRequests = false;

  // 내 물건 카드 목록 (myItemsProvider 판매중 목록에서 변환)
  List<RequestManagementItemCard> _itemCards = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 토글 애니메이션 컨트롤러 초기화
    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: AppMotion.standard));

    // 첫 진입(이미 로드된 경우 즉시) + 이후 내 물품 변경마다 1회 로드
    ref.listenManual<AsyncValue<MyItemsState>>(myItemsProvider, _onMyItemsChanged, fireImmediately: true);

    // 교환 요청 화면 '보낸 요청 보기' 신호 > 신호 소비 > 보낸 요청 토글 (initState 중 setState 금지 > 프레임 이후)
    ref.listenManual<bool>(sentRequestsFocusTriggerProvider, (previous, isTriggered) {
      if (!isTriggered) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sentRequestsFocusTriggerProvider.notifier).consume();
        if (!_isRightSelected) _onToggleChanged(true);
      });
    }, fireImmediately: true);

    // 다른 탭 > 요청관리 탭 진입 (IndexedStack이라 initState 재실행 없음) > 보낸 요청 백그라운드 재조회
    ref.listenManual<int>(currentTabIndexProvider, (previousTabIndex, nextTabIndex) {
      final requestManagementTabIndex = NavigationTabItems.requestManagement.index;
      if (nextTabIndex == requestManagementTabIndex && previousTabIndex != requestManagementTabIndex) {
        _reloadSentRequestsInBackground();
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        if (ref.read(currentTabIndexProvider) == NavigationTabItems.requestManagement.index) {
          _reloadSentRequestsInBackground();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isCardControllerInitialized) {
      final screenWidth = MediaQuery.of(context).size.width;
      _cardController = PageController(initialPage: 0, viewportFraction: 219 / screenWidth);
      _isCardControllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cardController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  /// 내 물품 변경 > 카드 갱신 > 거래 요청 재조회 (로딩 중 무시, 첫 로드 실패 시 안내)
  /// 보낸 요청은 카드 목록 변경(notifier 판단) 또는 대표 이미지 변경(보낸 요청 카드에 표시) 시에만 재조회
  void _onMyItemsChanged(AsyncValue<MyItemsState>? previous, AsyncValue<MyItemsState> next) {
    if (next.isLoading) return;
    final myItems = next.valueOrNull;
    if (myItems == null) {
      if (next.hasError) scheduleMicrotask(() => _showLoadError(next.error!));
      return;
    }
    final previousItemCards = _itemCards;
    setState(() {
      _itemCards = myItems.available.map(RequestManagementItemCard.fromItem).toList();
      // 카드 감소 시 현재 위치 보정 (빈 목록 > 0)
      _currentCardIndex = _itemCards.isEmpty ? 0 : _currentCardIndex.clamp(0, _itemCards.length - 1);
    });
    if (_cardController.hasClients) _cardController.jumpToPage(_currentCardIndex);
    final hasMyItemImageChanged = !listEquals(
      [for (final card in previousItemCards) card.imageUrl],
      [for (final card in _itemCards) card.imageUrl],
    );
    // 빌드 중 provider 변경 금지 > 현재 빌드 이후 실행
    scheduleMicrotask(() => _loadTradeRequests(isSentReloadForced: hasMyItemImageChanged));
  }

  /// 당겨서 새로고침: 내 물품 재조회 > 거래 요청 재조회 (보낸 요청 강제, 진행 중 로드에 합류), 실패 시 안내
  Future<void> _refreshAll() async {
    await ref.read(myItemsProvider.notifier).reload();
    if (!mounted) return;
    final myItems = ref.read(myItemsProvider);
    if (myItems.hasError) {
      _showLoadError(myItems.error!);
      return;
    }
    await _loadTradeRequests(isSentReloadForced: true);
  }

  /// 거래 요청 로드 (받은: 현재 카드, 보낸: 카드 목록 변경·강제 시 모든 카드)
  Future<void> _loadTradeRequests({bool isSentReloadForced = false}) {
    return _runWithLoading(
      () => ref
          .read(tradeRequestsProvider.notifier)
          .loadForItems(
            myItemIds: [for (final card in _itemCards) card.itemId],
            takeItemId: _currentTakeItemId,
            isSentReloadForced: isSentReloadForced,
          ),
    );
  }

  /// 상대 수락·취소 반영: 보낸 요청 백그라운드 재조회 (로딩 표시 없음, 최소 간격·첫 로드 전 생략은 notifier 판단)
  void _reloadSentRequestsInBackground() {
    unawaited(ref.read(tradeRequestsProvider.notifier).reloadSentIfStale());
  }

  /// 현재 카드 물품 ID (카드 없음·범위 밖 > null)
  String? get _currentTakeItemId {
    final isCardIndexInRange = _currentCardIndex >= 0 && _currentCardIndex < _itemCards.length;
    return isCardIndexInRange ? _itemCards[_currentCardIndex].itemId : null;
  }

  /// 로드 동안 로딩 표시 (성공·실패 공통 해제)
  @override
  Future<void> _runWithLoading(Future<void> Function() load) async {
    if (!mounted) return;
    setState(() => _activeLoadCount++);
    try {
      await load();
    } finally {
      if (mounted) setState(() => _activeLoadCount--);
    }
  }

  void _showLoadError(Object error) {
    if (!mounted) return;
    CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
  }

  void _scrollListener() {
    // 스크롤 상태 감지
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

  // 카드 컨트롤러 재생성
  void _recreateCardController(int initialPage) {
    // 기존 컨트롤러 정리 후 새로 생성
    _cardController.dispose();
    final screenWidth = MediaQuery.of(context).size.width;
    _cardController = PageController(
      initialPage: initialPage,
      keepPage: false, // 이전 위치 자동 복원 방지
      viewportFraction: 219 / screenWidth, // 카드 너비 219px 고정
    );
  }

  // 토글 변경 처리
  void _onToggleChanged(bool isRightSelected) {
    // 탭 전환 직전에(= 빌드 전) 컨트롤러를 재생성해서 초기 페이지 지정
    if (!isRightSelected && _itemCards.isNotEmpty) {
      final int targetIndex = (_currentCardIndex < 0)
          ? 0
          : (_currentCardIndex >= _itemCards.length ? _itemCards.length - 1 : _currentCardIndex);

      _recreateCardController(targetIndex);
    }

    setState(() {
      _isRightSelected = isRightSelected;
      if (isRightSelected) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    });
  }

  void _toggleCompletedRequests(bool value) {
    setState(() {
      _showCompletedRequests = value;
    });
  }

  /// 카드 전환 > 해당 카드 받은 요청 재조회 (캐시 있으면 즉시 표시, 로딩 표시는 상태 값)
  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
    });
    unawaited(ref.read(tradeRequestsProvider.notifier).selectItem(_currentTakeItemId));
  }

  @override
  Widget build(BuildContext context) {
    final tradeRequests = ref.watch(tradeRequestsProvider).valueOrNull ?? const TradeRequestsState();
    final blockedMemberIds = ref.watch(memberBlockProvider.select((memberBlock) => memberBlock.blockedIds));
    final isMyItemsFirstLoading = ref.watch(myItemsProvider.select((myItems) => myItems.isLoading));
    // 거래 요청 전체 로드 중 또는 내 물품 첫 로드 중
    final isLoading = _activeLoadCount > 0 || isMyItemsFirstLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // === 콘텐츠 ===
            SafeArea(
              top: false,
              child: RefreshIndicator(
                color: AppColors.primaryYellow,
                backgroundColor: AppColors.transparent,
                onRefresh: _refreshAll,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: GlassHeaderDelegate(
                        headerTitle: '요청 관리',
                        toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                          animation: _toggleAnimation,
                          isRightSelected: _isRightSelected,
                          onLeftTap: () => _onToggleChanged(false),
                          onRightTap: () => _onToggleChanged(true),
                          leftText: '받은 요청',
                          rightText: '보낸 요청',
                        ),
                        statusBarHeight: MediaQuery.of(context).padding.top,
                        // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 62.h,
                        expandedExtra: 16.h,
                        // 큰 제목/여백
                        enableBlur: _isScrolled, // 스크롤 시 더 진해지게
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 물품 카드 캐러셀 섹션 (받은 요청일 때만 표시)
                          if (!_isRightSelected) ...[SizedBox(height: 26.h), _buildItemCardsCarousel(isLoading)],

                          // 2. 페이지 인디케이터 (받은 요청일 때만 표시)
                          if (!_isRightSelected)
                            RequestPageIndicator(itemCount: _itemCards.length, currentIndex: _currentCardIndex),

                          // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
                          _buildRequestListHeader(tradeRequests.receivedSortType),
                        ],
                      ),
                    ),

                    // 4. 요청 목록 (sliver, 화면 근처 항목만 생성)
                    if (_isRightSelected)
                      _buildSentRequestsList(tradeRequests, blockedMemberIds, isLoading)
                    else
                      _buildReceivedRequestsList(
                        tradeRequests,
                        blockedMemberIds,
                        isLoading: tradeRequests.isReceivedLoading || isMyItemsFirstLoading,
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)), // 하단 여백
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 물품 카드 캐러셀 섹션
  Widget _buildItemCardsCarousel(bool isLoading) {
    return RequestItemCardsCarousel(
      itemCards: _itemCards,
      currentCardIndex: _currentCardIndex,
      cardController: _cardController,
      isLoading: isLoading,
      onPageChanged: _onCardPageChanged,
      onCardTap: (card) => _openItemDetail(itemId: card.itemId, isMyItem: true, isChatAccessAllowed: false),
    );
  }

  /// 요청 목록 헤더 섹션 (받은 요청 정렬 변경 > 현재 카드 재조회)
  Widget _buildRequestListHeader(RequestSortType receivedSortType) {
    return RequestListHeader(
      isRightSelected: _isRightSelected,
      currentSort: receivedSortType,
      showCompletedRequests: _showCompletedRequests,
      onSortChanged: (selected) {
        if (selected == receivedSortType) return; // 동일 정렬 재선택 시 무시
        unawaited(ref.read(tradeRequestsProvider.notifier).changeReceivedSort(selected));
      },
      onToggleCompleted: _toggleCompletedRequests,
    );
  }
}
