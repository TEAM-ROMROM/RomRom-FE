import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
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

/// 요청관리 탭: 내 물품 카드(myItemsProvider 구독) + 받은·보낸 요청(tradeRequestsProvider 구독)
/// 조회·정렬·읽음·취소는 notifier 위임, 화면은 카드 선택·토글·이동·안내만 담당
class RequestManagementTabScreen extends ConsumerStatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  ConsumerState<RequestManagementTabScreen> createState() => _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends ConsumerState<RequestManagementTabScreen> with TickerProviderStateMixin {
  // 요청관리 카드 최대 개수 (판매중 내 물품 첫 페이지 10개)
  static const int maximumItemCardCount = 10;

  final ScrollController _scrollController = ScrollController();

  // 진행 중인 거래 요청 로드 수 (0 초과 = 로딩 표시)
  int _activeLoadCount = 0;

  // 진행 중인 취소 요청 ID (중복 탭 방지)
  final Set<String> _pendingCancelRequestIds = {};

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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cardController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  /// 내 물품 변경 > 카드 갱신 > 거래 요청 재조회 (로딩 중 무시, 첫 로드 실패 시 안내)
  void _onMyItemsChanged(AsyncValue<MyItemsState>? previous, AsyncValue<MyItemsState> next) {
    if (next.isLoading) return;
    final myItems = next.valueOrNull;
    if (myItems == null) {
      if (next.hasError) scheduleMicrotask(() => _showLoadError(next.error!));
      return;
    }
    setState(() {
      _itemCards = myItems.available.take(maximumItemCardCount).map(RequestManagementItemCard.fromItem).toList();
      // 카드 감소 시 현재 위치 보정 (빈 목록 > 0)
      _currentCardIndex = _itemCards.isEmpty ? 0 : _currentCardIndex.clamp(0, _itemCards.length - 1);
    });
    if (_cardController.hasClients) _cardController.jumpToPage(_currentCardIndex);
    // 빌드 중 provider 변경 금지 > 현재 빌드 이후 실행
    scheduleMicrotask(_loadTradeRequests);
  }

  /// 당겨서 새로고침: 내 물품 재조회 > 거래 요청 재조회 (진행 중 로드에 합류), 실패 시 안내
  Future<void> _refreshAll() async {
    await ref.read(myItemsProvider.notifier).reload();
    if (!mounted) return;
    final myItems = ref.read(myItemsProvider);
    if (myItems.hasError) {
      _showLoadError(myItems.error!);
      return;
    }
    await _loadTradeRequests();
  }

  /// 모든 카드 거래 요청 로드 (받은: 현재 카드, 보낸: 모든 카드)
  Future<void> _loadTradeRequests() {
    return _runWithLoading(
      () => ref
          .read(tradeRequestsProvider.notifier)
          .loadForItems(myItemIds: [for (final card in _itemCards) card.itemId], takeItemId: _currentTakeItemId),
    );
  }

  /// 현재 카드 물품 ID (카드 없음·범위 밖 > null)
  String? get _currentTakeItemId {
    final isCardIndexInRange = _currentCardIndex >= 0 && _currentCardIndex < _itemCards.length;
    return isCardIndexInRange ? _itemCards[_currentCardIndex].itemId : null;
  }

  /// 로드 동안 로딩 표시 (성공·실패 공통 해제)
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

  /// 거래 요청 취소 > 성공·실패 안내 (실패 문구 미지정 시 서버 오류 문구, 진행 중 같은 요청 무시)
  Future<void> _cancelTradeRequest(
    TradeRequestHistory request, {
    required String successMessage,
    String? failureMessage,
  }) async {
    final tradeRequestHistoryId = request.tradeRequestHistoryId ?? '';
    if (_pendingCancelRequestIds.contains(tradeRequestHistoryId)) return;
    _pendingCancelRequestIds.add(tradeRequestHistoryId);
    try {
      await ref.read(tradeRequestsProvider.notifier).cancel(tradeRequestHistoryId: tradeRequestHistoryId);
      if (mounted) CommonSnackBar.show(context: context, message: successMessage);
    } catch (error) {
      debugPrint('[request management] cancel failed : $error');
      if (!mounted) return;
      final message = failureMessage ?? ErrorUtils.getErrorMessage(error);
      CommonSnackBar.show(context: context, message: message, type: SnackBarType.error);
    } finally {
      _pendingCancelRequestIds.remove(tradeRequestHistoryId);
    }
  }

  /// 물품 상세 이동 (요청관리 진입, 첫 이미지 Hero)
  void _openItemDetail({
    required String itemId,
    required bool isMyItem,
    required bool isChatAccessAllowed,
    String? tradeRequestHistoryId,
  }) {
    context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: itemId,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: 'itemImage_${itemId}_0',
        isMyItem: isMyItem,
        isRequestManagement: true,
        tradeRequestHistoryId: tradeRequestHistoryId,
        isChatAccessAllowed: isChatAccessAllowed,
      ),
    );
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

  /// 카드 전환 > 해당 카드 받은 요청 재조회
  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
    });
    _runWithLoading(() => ref.read(tradeRequestsProvider.notifier).selectItem(_currentTakeItemId));
  }

  @override
  Widget build(BuildContext context) {
    final tradeRequests = ref.watch(tradeRequestsProvider).valueOrNull ?? const TradeRequestsState();
    // 거래 요청 로드 중 또는 내 물품 첫 로드 중
    final isLoading = _activeLoadCount > 0 || ref.watch(myItemsProvider.select((myItems) => myItems.isLoading));

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

                          // 4. 요청 목록 리스트
                          if (_isRightSelected)
                            _buildSentRequestsList(tradeRequests, isLoading)
                          else
                            _buildReceivedRequestsList(tradeRequests.received, isLoading),

                          const SizedBox(height: 100), // 하단 여백
                        ],
                      ),
                    ),
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
        _runWithLoading(() => ref.read(tradeRequestsProvider.notifier).changeReceivedSort(selected));
      },
      onToggleCompleted: _toggleCompletedRequests,
    );
  }

  /// 보낸 요청 목록 (정렬 변경 > 모든 카드 재조회, 교환 완료 탭 > 삭제, 그 외 탭 > 상대 물품 상세)
  Widget _buildSentRequestsList(TradeRequestsState tradeRequests, bool isLoading) {
    return RequestSentList(
      sentRequests: tradeRequests.sent,
      isLoading: isLoading,
      currentSort: tradeRequests.sentSortType,
      onSortChanged: (selected) {
        if (selected == tradeRequests.sentSortType) return; // 동일 정렬 재선택 시 무시
        _runWithLoading(() => ref.read(tradeRequestsProvider.notifier).changeSentSort(selected));
      },
      onCardTap: (request) {
        if (request.tradeStatus == TradeStatus.traded.serverName) {
          _cancelTradeRequest(request, successMessage: '삭제되었습니다.', failureMessage: '삭제에 실패했습니다');
          return;
        }
        _openItemDetail(
          itemId: request.takeItem.itemId!,
          isMyItem: false,
          tradeRequestHistoryId: request.tradeRequestHistoryId,
          isChatAccessAllowed: false, // 보낸요청 = 채팅 불가
        );
      },
      onEditTap: (request) {
        context.navigateTo(
          screen: ItemModificationScreen(itemId: request.giveItem.itemId, onClose: () => Navigator.pop(context)),
        );
      },
      onCancelTap: (request) async {
        final result = await context.showDeleteDialog(
          title: '교환 요청 취소',
          description: '교환 요청을 취소하시겠습니까?',
          confirmText: '확인',
        );
        if (result == true) await _cancelTradeRequest(request, successMessage: '요청을 취소했습니다.');
      },
    );
  }

  /// 받은 요청 목록 (완료 표시 OFF: 진행 중만, ON: 전체 / 탭 > 읽음 처리 + 요청 물품 상세)
  Widget _buildReceivedRequestsList(List<TradeRequestHistory> receivedRequests, bool isLoading) {
    final filteredRequests = _showCompletedRequests
        ? receivedRequests
        : receivedRequests.where((request) => request.tradeStatus != TradeStatus.traded.serverName).toList();

    return RequestReceivedList(
      filteredRequests: filteredRequests,
      isLoading: isLoading,
      onCardTap: (request) {
        final tradeRequestHistoryId = request.tradeRequestHistoryId;
        if (tradeRequestHistoryId != null) {
          unawaited(
            ref
                .read(tradeRequestsProvider.notifier)
                .markReceivedAsRead(tradeRequestHistoryId)
                .catchError((Object error) => debugPrint('[request management] mark as read failed : $error')),
          );
        }
        _openItemDetail(
          itemId: request.giveItem.itemId!,
          isMyItem: false,
          tradeRequestHistoryId: tradeRequestHistoryId,
          isChatAccessAllowed: true, // 받은요청 = 채팅 가능
        );
      },
      onMenuTap: (request) async {
        final result = await context.showDeleteDialog(title: '교환 요청 삭제', description: '정말 삭제하시겠습니까?');
        if (result == true) await _cancelTradeRequest(request, successMessage: '요청을 삭제했습니다.');
      },
    );
  }
}
