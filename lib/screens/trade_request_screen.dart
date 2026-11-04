import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';

import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/enums/trade_request_existence_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/sent_requests_focus_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/utils/item_label_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/notification_permission_prompt_modal.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/request_management/request_page_indicator.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/widgets/trade_request_action_buttons.dart';
import 'package:romrom_fe/widgets/trade_request_existence_notice.dart';
import 'package:romrom_fe/widgets/trade_request_target_preview.dart';
import 'package:romrom_fe/widgets/trade_request_text_action_button.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';

/// 요청하기 화면
/// 내 물품 카드 선택 후 거래방식을 선택하여 요청을 전송하는 화면
class TradeRequestScreen extends ConsumerStatefulWidget {
  /// 교환 대상 물품 (상대방 물품)
  final Item targetItem;

  /// 교환 대상 물품 이미지 URL
  final String? targetImageUrl;

  /// 홈탭에서 스와이프한 카드 ID (선택사항)
  /// 이 값이 있으면 해당 카드를 자동 선택하고 2단계로 시작
  final String? preSelectedCardId;

  const TradeRequestScreen({super.key, required this.targetItem, this.targetImageUrl, this.preSelectedCardId});

  @override
  ConsumerState<TradeRequestScreen> createState() => _TradeRequestScreenState();
}

class _TradeRequestScreenState extends ConsumerState<TradeRequestScreen> {
  // 내 물품 한 페이지 크기
  static const int myItemsPageSize = 20;

  // 끝에서 이 장수 이내 카드 도달 시 다음 페이지 로드
  static const int loadMoreThresholdCardCount = 3;

  // 홈에서 고른 카드 탐색 최대 페이지 수 (첫 페이지 포함, 무한 조회 방지)
  static const int maximumPreSelectedSearchPageCount = 10;

  /// 선택된 카드가 있는지 여부에 따라 초기값 설정
  bool _hasSelectedCard = false;

  /// 내 물품 목록
  List<Item> _myItems = [];

  /// 화면에 표시할 카드 데이터
  List<RequestManagementItemCard> _myItemCards = [];

  /// 로딩 상태
  bool _isLoading = true;

  // 내 물품 페이지 상태: 다음 조회 페이지 번호, 다음 페이지 여부, 다음 페이지 조회 중 여부
  int _nextMyItemsPageNumber = 0;
  bool _hasMoreMyItems = false;
  bool _isLoadingMoreMyItems = false;

  /// PageView 컨트롤러
  late PageController _pageController;

  /// 현재 선택된 카드 인덱스
  int _selectedCardIndex = 0;

  /// 선택된 거래 옵션들
  final Set<ItemTradeOption> _selectedTradeOptions = {};

  /// API 요청 진행 중 여부
  bool _isSubmitting = false;

  /// 선택한 카드 > 상대 물품 거래 요청 존재 확인 상태
  TradeRequestExistenceStatus _existenceStatus = TradeRequestExistenceStatus.checking;

  /// 존재 여부 확인 회차 (빠른 슬라이드 시 이전 카드 응답 무시용)
  int _existenceCheckGeneration = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 227.w / 345.w);
    _loadMyItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 내 물품 첫 로드: 첫 페이지 > 홈에서 고른 카드 탐색 > 초기 카드 선택·요청 존재 확인 (조회 실패해도 받은 카드로 진행)
  Future<void> _loadMyItems() async {
    setState(() => _isLoading = true);

    try {
      await _fetchNextMyItemsPage();
      await _searchPreSelectedCard();
    } catch (e) {
      debugPrint('내 물품 목록 로드 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }

    if (!mounted) return;
    _selectInitialCard();
  }

  /// 홈에서 고른 카드 탐색: 찾을 때까지 다음 페이지 (최대 페이지 수·마지막 페이지·새 물품 없는 페이지 > 중단)
  Future<void> _searchPreSelectedCard() async {
    final preSelectedCardId = widget.preSelectedCardId;
    if (preSelectedCardId == null) return;
    while (mounted &&
        _hasMoreMyItems &&
        _nextMyItemsPageNumber < maximumPreSelectedSearchPageCount &&
        !_myItems.any((item) => item.itemId == preSelectedCardId)) {
      final addedItemCount = await _fetchNextMyItemsPage();
      if (addedItemCount == 0) return;
    }
  }

  /// 초기 카드 선택: 고른 카드 있음 > 그 카드 선택 완료 상태, 없음 > 첫 카드 > 요청 존재 확인 (카드 없으면 생략)
  void _selectInitialCard() {
    final preSelectedIndex = _myItems.indexWhere((item) => item.itemId == widget.preSelectedCardId);
    final initialIndex = preSelectedIndex >= 0 ? preSelectedIndex : 0;
    // 카드 선택 모드로 돌아갈 때 고른 카드 위치에서 시작
    if (preSelectedIndex >= 0) _recreatePageController(preSelectedIndex);
    setState(() {
      _selectedCardIndex = initialIndex;
      _hasSelectedCard = preSelectedIndex >= 0;
      _isLoading = false;
    });

    if (_myItems.isNotEmpty) _checkTradeRequestExistence(initialIndex);
  }

  /// 내 물품 다음 페이지 조회 > 이미 받은 물품 제외하고 뒤에 추가 > 추가된 개수 반환
  /// (새 물품 없는 페이지 > 마지막 페이지로 처리)
  Future<int> _fetchNextMyItemsPage() async {
    final myItemsPage = await ref
        .read(itemRepositoryProvider)
        .getMyItemsPage(ItemStatus.available, pageNumber: _nextMyItemsPageNumber, pageSize: myItemsPageSize);
    if (!mounted) return 0;

    final loadedItemIds = _myItems.map((item) => item.itemId).toSet();
    final newItems = myItemsPage.items.where((item) => loadedItemIds.add(item.itemId)).toList();
    setState(() {
      _myItems = [..._myItems, ...newItems];
      _myItemCards = [..._myItemCards, ..._convertToItemCards(newItems)];
      _nextMyItemsPageNumber++;
      _hasMoreMyItems = myItemsPage.hasMore && newItems.isNotEmpty;
    });
    return newItems.length;
  }

  /// 끝 근처 카드 도달 > 다음 페이지 로드 (조회 중·마지막 페이지면 무시, 실패 시 안내 후 다음 슬라이드에 재시도)
  Future<void> _loadMoreMyItemsIfNeeded(int cardIndex) async {
    final isNearLastCard = cardIndex >= _myItemCards.length - loadMoreThresholdCardCount;
    if (!isNearLastCard || !_hasMoreMyItems || _isLoadingMoreMyItems) return;

    setState(() => _isLoadingMoreMyItems = true);
    try {
      await _fetchNextMyItemsPage();
    } catch (e) {
      debugPrint('내 물품 다음 페이지 로드 실패: $e');
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoadingMoreMyItems = false);
    }
  }

  /// Item 목록을 RequestManagementItemCard 목록으로 변환
  List<RequestManagementItemCard> _convertToItemCards(List<Item> items) {
    return items.map((item) => RequestManagementItemCard.fromItem(item, titleFallback: '')).toList();
  }

  /// 카드 PageView 컨트롤러 재생성 (카드 선택 모드 진입 시 지정 카드에서 시작)
  void _recreatePageController(int initialPage) {
    _pageController.dispose();
    _pageController = PageController(initialPage: initialPage, viewportFraction: 227.w / 345.w);
  }

  /// 다른 물품 선택: 선택 완료 카드 > 카드 선택 모드 (현재 카드 위치 유지)
  void _showCardSelection() {
    _recreatePageController(_selectedCardIndex);
    setState(() => _hasSelectedCard = false);
  }

  /// 카드 슬라이드 > 선택 변경 > 요청 존재 확인 > 끝 근처면 다음 페이지
  void _onCardPageChanged(int index) {
    setState(() => _selectedCardIndex = index);
    _checkTradeRequestExistence(index);
    _loadMoreMyItemsIfNeeded(index);
  }

  /// 선택한 카드 > 상대 물품 요청 존재 확인 (실패 > 확인 실패 상태, 요청 없음으로 처리하지 않음)
  Future<void> _checkTradeRequestExistence(int cardIndex) async {
    if (_myItems.isEmpty) return;

    final generation = ++_existenceCheckGeneration;
    setState(() => _existenceStatus = TradeRequestExistenceStatus.checking);

    // 최신 회차 응답만 반영 (이전 카드 응답이 늦게 와도 현재 카드 상태 유지)
    bool isLatestCheck() => mounted && generation == _existenceCheckGeneration;

    try {
      final exists = await ref
          .read(tradeRepositoryProvider)
          .hasTradeRequest(takeItemId: widget.targetItem.itemId, giveItemId: _myItems[cardIndex].itemId);

      if (!isLatestCheck()) return;

      setState(
        () => _existenceStatus = exists
            ? TradeRequestExistenceStatus.alreadyRequested
            : TradeRequestExistenceStatus.notRequested,
      );
    } catch (e) {
      debugPrint('거래 요청 존재 여부 확인 실패: $e');
      if (!isLatestCheck()) return;
      setState(() => _existenceStatus = TradeRequestExistenceStatus.checkFailed);
    }
  }

  /// 보낸 요청 보기: 요청관리 탭 보낸 요청 신호 > 요청관리 탭 선택 > 메인 화면까지 닫기
  void _openSentRequests() {
    ref.read(sentRequestsFocusTriggerProvider.notifier).trigger();
    ref.read(currentTabIndexProvider.notifier).set(NavigationTabItems.requestManagement.index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 거래 요청 API 호출
  Future<void> _submitTradeRequest() async {
    if (_selectedTradeOptions.isEmpty) {
      CommonSnackBar.show(context: context, message: '교환 방식을 선택해주세요.', type: SnackBarType.info);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(tradeRequestsProvider.notifier)
          .sendRequest(
            takeItemId: widget.targetItem.itemId,
            giveItemId: _myItems[_selectedCardIndex].itemId,
            itemTradeOptions: _selectedTradeOptions.map((o) => o.serverName).toList(),
          );

      if (!mounted) return;

      CommonSnackBar.show(context: context, message: '교환 요청이 전송되었습니다.', type: SnackBarType.success);
      await showNotificationPermissionPromptOnce(context, ref);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('거래 요청 실패: $e');
      if (!mounted) return;

      final errorMessage = ErrorUtils.getErrorMessage(e);

      await CommonModal.error(context: context, message: errorMessage, onConfirm: () => Navigator.of(context).pop());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// AppBar 높이만큼 상단 여백 추가
  Widget _buildAppBarSpacing() {
    return Container(
      height: MediaQuery.of(context).padding.top + kToolbarHeight,
      constraints: BoxConstraints(minHeight: 115.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const CommonAppBar(title: '요청하기'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, -1),
                  end: Alignment(0, 1),
                  stops: [0.0, 0.5, 1.0],
                  colors: AppColors.tradeRequestBackgroundGradient,
                ),
              ),
            ),
          ),
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: [
                _buildAppBarSpacing(),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CommonLoadingIndicator())
                      : _myItemCards.isEmpty
                      ? _buildEmptyState()
                      : _buildTradeRequestStep(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 UI (내 물품이 없을 때)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64.sp, color: AppColors.opacity50White),
                SizedBox(height: 16.h),
                Text('등록된 물품이 없습니다', style: CustomTextStyles.h2.copyWith(color: AppColors.opacity80White)),
                SizedBox(height: 8.h),
                Text(
                  '교환 요청을 하려면 먼저\n물품을 등록해주세요.',
                  style: CustomTextStyles.p1.copyWith(color: AppColors.opacity50White, height: 1.2),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomFloatingButton(
                  isEnabled: true,
                  enabledOnPressed: () => Navigator.pop(context),
                  buttonText: '돌아가기',
                  buttonWidth: 120,
                  buttonHeight: 44,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 거래방식 선택 및 요청
  Widget _buildTradeRequestStep() {
    final bool isRequestDisabled = _isSubmitting || _existenceStatus != TradeRequestExistenceStatus.notRequested;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        children: [
          // 교환 대상 물품 미리보기
          TradeRequestTargetPreview(
            imageUrl: widget.targetImageUrl,
            itemName: widget.targetItem.itemName ?? '물품',
            tags: itemTagLabels(
              condition: widget.targetItem.itemCondition,
              tradeOptions: widget.targetItem.itemTradeOptions,
            ),
          ),

          // 내 물품 카드 영역
          Padding(
            padding: EdgeInsets.only(top: 32.h),
            child: !_hasSelectedCard
                ?
                  // 카드 선택 상태: 내 물품 카드 PageView로 선택 가능
                  Column(
                    children: [
                      SizedBox(
                        height: 334.h,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _myItemCards.length,
                          onPageChanged: _onCardPageChanged,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0.h, horizontal: 4.w),
                              child: RequestManagementItemCardWidget(
                                card: _myItemCards[index],
                                isActive: index == _selectedCardIndex,
                              ),
                            );
                          },
                        ),
                      ),

                      // 페이지 인디케이터 (불러온 카드 기준)
                      RequestPageIndicator(
                        itemCount: _myItemCards.length,
                        currentIndex: _selectedCardIndex,
                        padding: EdgeInsets.only(top: 24.h),
                      ),
                    ],
                  )
                :
                  // 카드 선택 완료: 선택한 내 물품 카드 + 다른 물품 선택
                  Column(
                    children: [
                      Center(
                        child: RequestManagementItemCardWidget(card: _myItemCards[_selectedCardIndex], isActive: true),
                      ),
                      SizedBox(height: 12.h),
                      TradeRequestTextActionButton(text: '다른 물품 선택', onTap: _showCardSelection),
                    ],
                  ),
          ),

          SizedBox(height: _hasSelectedCard ? 16.h : 23.h),

          // 거래방식 선택 섹션 (확인 중에는 선택 탭 대신 로딩 > 이미 요청한 물품의 선택 탭 깜빡임 방지, #855)
          _buildTradeOptionSection(),

          SizedBox(height: _hasSelectedCard ? 24.h : 16.h),

          // 하단 버튼 (취소, 요청하기)
          TradeRequestActionButtons(
            isRequestDisabled: isRequestDisabled,
            isRequestLoading: _isSubmitting || _existenceStatus == TradeRequestExistenceStatus.checking,
            onCancel: () => Navigator.pop(context),
            onRequest: _submitTradeRequest,
          ),
        ],
      ),
    );
  }

  /// 거래 방식 영역: 확인 중 로딩, 이미 요청 > 보낸 요청 보기, 확인 실패 > 다시 확인, 요청 없음 > 선택 탭
  Widget _buildTradeOptionSection() {
    switch (_existenceStatus) {
      case TradeRequestExistenceStatus.checking:
        return SizedBox(
          height: 90.h,
          child: const Center(child: CommonLoadingIndicator()),
        );
      case TradeRequestExistenceStatus.alreadyRequested:
        return TradeRequestExistenceNotice(
          message: '이미 교환을 요청한 물품입니다.',
          actionText: '보낸 요청 보기',
          onActionTap: _openSentRequests,
        );
      case TradeRequestExistenceStatus.checkFailed:
        return TradeRequestExistenceNotice(
          message: '요청 여부를 확인하지 못했어요.',
          actionText: '다시 확인',
          onActionTap: () => _checkTradeRequestExistence(_selectedCardIndex),
        );
      case TradeRequestExistenceStatus.notRequested:
        return TradeRequestTradeOptionSelector(
          selectedOptions: _selectedTradeOptions,
          onChanged: (next) {
            setState(() {
              _selectedTradeOptions
                ..clear()
                ..addAll(next);
            });
          },
        );
    }
  }
}
