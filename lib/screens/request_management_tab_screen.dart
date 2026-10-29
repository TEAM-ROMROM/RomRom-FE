import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'dart:async';

import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/request_management/request_item_cards_carousel.dart';
import 'package:romrom_fe/widgets/request_management/request_list_header.dart';
import 'package:romrom_fe/widgets/request_management/request_page_indicator.dart';
import 'package:romrom_fe/widgets/request_management/request_received_list.dart';
import 'package:romrom_fe/widgets/request_management/request_sent_list.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';

class RequestManagementTabScreen extends ConsumerStatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  ConsumerState<RequestManagementTabScreen> createState() => _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends ConsumerState<RequestManagementTabScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  final int _currentPage = 0;
  final int _pageSize = 10;

  // 로딩 상태
  bool _isLoading = false;

  // 카드 전환 중 레이스 방지: 진행 중인 받은요청 로드 키
  String? _pendingReceivedKey;

  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 현재 선택된 카드 인덱스
  int _currentCardIndex = 0;

  // 카드 컨트롤러 (초기값 0.578 = 227/393, didChangeDependencies에서 실제 화면 크기로 재생성)
  PageController _cardController = PageController(initialPage: 0, viewportFraction: 227 / 393);
  bool _cardControllerInitialized = false;

  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 받은 요청, true: 보낸 요청)
  bool _isRightSelected = false;

  // 완료된 요청 표시 여부
  bool _showCompletedRequests = false;

  // 정렬 상태 (받은 요청 / 보낸 요청 각각 독립)
  RequestSortType _receivedSortType = RequestSortType.latest;
  RequestSortType _sentSortType = RequestSortType.latest;

  // 내 물건 카드 목록
  final List<RequestManagementItemCard> _itemCards = [];

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

    _loadInitialItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cardControllerInitialized) {
      final screenWidth = MediaQuery.of(context).size.width;
      _cardController = PageController(initialPage: 0, viewportFraction: 219 / screenWidth);
      _cardControllerInitialized = true;
    }
  }

  /// 초기 아이템 로드
  Future<void> _loadInitialItems({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    if (!mounted) return;

    try {
      final itemApi = ItemApi();
      final response = await itemApi.getMyItems(
        ItemRequest(pageNumber: _currentPage, pageSize: _pageSize, itemStatus: ItemStatus.available.serverName),
      );

      if (!mounted) return;

      final itemCard = await _convertToRequestManagementItemCard(response.itemPage?.content ?? []);

      setState(() {
        _itemCards
          ..clear()
          ..addAll(itemCard);
      });

      // 아이템 카드가 로드된 후 첫 번째 카드의 받은 요청 목록도 로드
      await _loadReceivedRequestsForCurrentCard();
      // 아이템 카드가 로드된 후  보낸 요청 목록도 로드
      await _loadSentRequestsForCurrentCard();
    } catch (e) {
      if (!mounted) return;

      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    }
    setState(() {
      _isLoading = false;
    });
  }

  /// ItemDetail을 RequestManagementItemCard로 변환
  Future<List<RequestManagementItemCard>> _convertToRequestManagementItemCard(List<Item> details) async {
    final itemCards = <RequestManagementItemCard>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      String category = ItemCategories.fromServerName(d.itemCategory ?? '기타').label;

      final itemCard = RequestManagementItemCard(
        itemId: d.itemId ?? '',
        imageUrl: d.primaryImageUrl ?? '',
        category: category,
        title: d.itemName ?? ' ',
        price: d.price ?? 0,
        likeCount: d.likeCount ?? 0,
        aiPrice: d.isAiPredictedPrice ?? false,
      );

      itemCards.add(itemCard);
    }

    return itemCards;
  }

  /// 현재 선택된 카드의 받은 요청 목록 로드 — provider에 위임.
  /// 카드 전환 레이스: 요청 시작 시 현재 카드 ID를 _pendingReceivedKey에 기록하고,
  /// 응답 도착 시 키가 달라졌으면 결과를 버려 이전 카드 응답이 덮어쓰는 현상을 방지.
  Future<void> _loadReceivedRequestsForCurrentCard() async {
    if (!mounted) return;

    if (_itemCards.isEmpty || _currentCardIndex < 0 || _currentCardIndex >= _itemCards.length) {
      await ref.read(tradeRequestsProvider.notifier).loadReceived('');
      return;
    }

    final takeItemId = _itemCards[_currentCardIndex].itemId;
    _pendingReceivedKey = takeItemId;

    setState(() => _isLoading = true);
    try {
      final received = await TradeApi().getReceivedTradeRequests(
        TradeRequest(
          takeItemId: takeItemId,
          pageNumber: 0,
          pageSize: 10,
          sortField: _receivedSortType.serverSortField,
          sortDirection: _receivedSortType.serverDirection,
        ),
      );
      final list = received.content;

      // 주소 캐싱 (UI 관심사 — screen에서 수행)
      if (list.isNotEmpty) {
        await Future.wait(
          list.map((r) async {
            await r.takeItem.resolveAndCacheAddress();
            await r.giveItem.resolveAndCacheAddress();
          }),
        );
      }

      // 카드 전환 레이스: 이 응답이 현재 카드 기준인지 확인
      if (!mounted || _pendingReceivedKey != takeItemId) return;
      ref.read(tradeRequestsProvider.notifier).setReceived(takeItemId: takeItemId, received: list);
    } catch (e, st) {
      debugPrint('현재 카드의 받은 요청 목록 로드 실패: $e\n$st');
      if (!mounted || _pendingReceivedKey != takeItemId) return;
      ref.read(tradeRequestsProvider.notifier).setReceived(received: const []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 모든 카드의 보낸 요청 목록 로드 — provider에 위임.
  Future<void> _loadSentRequestsForCurrentCard() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      if (_itemCards.isEmpty) {
        ref.read(tradeRequestsProvider.notifier).setSent(const []);
        return;
      }

      final api = TradeApi();

      // 모든 카드에 대해 병렬로 요청을 보내고 결과를 합칩니다.
      final pagedResults = await Future.wait<PagedTradeRequestHistory?>(
        _itemCards.map((card) async {
          try {
            return await api.getSentTradeRequests(
              TradeRequest(
                giveItemId: card.itemId,
                sortField: _sentSortType.serverSortField,
                sortDirection: _sentSortType.serverDirection,
              ),
            );
          } catch (error, stackTrace) {
            debugPrint('보낸 요청 로드 실패 for itemId ${card.itemId}: $error\n$stackTrace');
            return null;
          }
        }),
        eagerError: false,
      );

      final allRequests = <TradeRequestHistory>[];
      for (final paged in pagedResults) {
        if (paged == null) continue;
        final list = paged.content;
        if (list.isNotEmpty) {
          // 각 요청의 take/give 아이템 주소 캐시 채우기
          await Future.wait(
            list.map((r) async {
              try {
                await r.takeItem.resolveAndCacheAddress();
              } catch (e) {
                debugPrint('takeItem 주소 해석 실패: $e');
              }
              try {
                await r.giveItem.resolveAndCacheAddress();
              } catch (e) {
                debugPrint('giveItem 주소 해석 실패: $e');
              }
            }),
            eagerError: false,
          );
          allRequests.addAll(list);
        }
      }

      if (!mounted) return;
      ref.read(tradeRequestsProvider.notifier).setSent(allRequests);
    } catch (e, st) {
      debugPrint('보낸 요청 목록 로드 실패: $e\n$st');
      if (!mounted) return;
      ref.read(tradeRequestsProvider.notifier).setSent(const []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 보낸 요청 목록 (정렬 버튼 + 목록)
  Widget _buildSentRequestsList() {
    final sentRequests = ref.watch(tradeRequestsProvider).value?.sent ?? const [];

    return RequestSentList(
      sentRequests: sentRequests,
      isLoading: _isLoading,
      currentSort: _sentSortType,
      onSortChanged: (selected) {
        if (selected == _sentSortType) return; // 동일 정렬 재선택 시 무시
        setState(() => _sentSortType = selected);
        _loadSentRequestsForCurrentCard(); // 정렬 변경 시 서버 재조회
      },
      onCardTap: (request) {
        final takeItem = request.takeItem;
        // 교환 완료 상태면 삭제 처리
        if (request.tradeStatus == TradeStatus.traded.serverName) {
          ref
              .read(tradeRequestsProvider.notifier)
              .cancel(tradeRequestHistoryId: request.tradeRequestHistoryId ?? '')
              .then((_) {
                if (mounted) {
                  CommonSnackBar.show(context: context, message: '삭제되었습니다.');
                }
              })
              .catchError((e) {
                debugPrint('교환 완료 항목 삭제 실패: $e');
                if (mounted) {
                  CommonSnackBar.show(context: context, message: '삭제에 실패했습니다', type: SnackBarType.error);
                }
              });
          return;
        }
        // 기존 로직: 상세 페이지 이동
        context.navigateTo(
          screen: ItemDetailDescriptionScreen(
            itemId: takeItem.itemId!,
            // 내가 요청 보낸 카드로 이동
            imageSize: Size(MediaQuery.of(context).size.width, 400.h),
            currentImageIndex: 0,
            heroTag: 'itemImage_${takeItem.itemId!}_0',
            // ← 인덱스 포함
            isMyItem: false,
            isRequestManagement: true,
            tradeRequestHistoryId: request.tradeRequestHistoryId,
            isChatAccessAllowed: false, // 보낸요청 = 채팅 불가
          ),
        );
      },
      onEditTap: (request) {
        context.navigateTo(
          screen: ItemModificationScreen(
            itemId: request.giveItem.itemId,
            onClose: () {
              Navigator.pop(context);
            },
          ),
        );
      },
      onCancelTap: (request) async {
        final result = await context.showDeleteDialog(
          title: '교환 요청 취소',
          description: '교환 요청을 취소하시겠습니까?',
          confirmText: '확인',
        );

        if (result == true) {
          try {
            await ref
                .read(tradeRequestsProvider.notifier)
                .cancel(tradeRequestHistoryId: request.tradeRequestHistoryId ?? '');
            if (mounted) {
              CommonSnackBar.show(context: context, message: '요청을 취소했습니다.');
            }
          } catch (e) {
            debugPrint('요청 취소 실패: $e');
            if (mounted) {
              CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
            }
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollTimer?.cancel();
    _cardController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 스크롤 타이머 리셋
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      // 스크롤이 멈췄을 때의 처리
    });

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

  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
    });

    // 카드가 변경되면 해당 카드의 받은 요청 목록을 로드
    _loadReceivedRequestsForCurrentCard();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myItemsProvider, (prev, next) {
      if (mounted && next.hasValue) _loadInitialItems(isRefresh: true);
    });

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
                onRefresh: () => _loadInitialItems(isRefresh: true),
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
                          if (!_isRightSelected) ...[SizedBox(height: 26.h), _buildItemCardsCarousel()],

                          // 2. 페이지 인디케이터 (받은 요청일 때만 표시)
                          if (!_isRightSelected) _buildPageIndicator(),

                          // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
                          _buildRequestListHeader(),

                          // 4. 요청 목록 리스트
                          _buildFullRequestItemsList(),

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
  Widget _buildItemCardsCarousel() {
    return RequestItemCardsCarousel(
      itemCards: _itemCards,
      currentCardIndex: _currentCardIndex,
      cardController: _cardController,
      isLoading: _isLoading,
      onPageChanged: _onCardPageChanged,
      onCardTap: (card) {
        context.navigateTo(
          screen: ItemDetailDescriptionScreen(
            itemId: card.itemId,
            imageSize: Size(MediaQuery.of(context).size.width, 400.h),
            currentImageIndex: 0,
            heroTag: 'itemImage_${card.itemId}_0',
            isMyItem: true,
            isRequestManagement: true,
            isChatAccessAllowed: false,
          ),
        );
      },
    );
  }

  /// 페이지 인디케이터
  Widget _buildPageIndicator() {
    return RequestPageIndicator(itemCount: _itemCards.length, currentIndex: _currentCardIndex);
  }

  /// 요청 목록 헤더 섹션
  Widget _buildRequestListHeader() {
    return RequestListHeader(
      isRightSelected: _isRightSelected,
      currentSort: _receivedSortType,
      showCompletedRequests: _showCompletedRequests,
      onSortChanged: (selected) {
        if (selected == _receivedSortType) return; // 동일 정렬 재선택 시 무시
        setState(() => _receivedSortType = selected);
        _loadReceivedRequestsForCurrentCard(); // 정렬 변경 시 서버 재조회
      },
      onToggleCompleted: _toggleCompletedRequests,
    );
  }

  /// 요청 목록 리스트
  Widget _buildFullRequestItemsList() {
    // 보낸 요청인 경우
    if (_isRightSelected) {
      return _buildSentRequestsList();
    }

    // 받은 요청인 경우 - provider에서 단일 소스로 파생
    final receivedRequests = ref.watch(tradeRequestsProvider).value?.received ?? const [];

    // 완료 표시 OFF: 진행 중만, ON: 진행 중 + 완료 전체
    final filteredRequests = receivedRequests.where((request) {
      final status = request.tradeStatus;
      if (_showCompletedRequests) {
        return true; // 완료 포함 전체 표시
      } else {
        return status != TradeStatus.traded.serverName;
      }
    }).toList();

    return RequestReceivedList(
      filteredRequests: filteredRequests,
      isLoading: _isLoading,
      onCardTap: (request) {
        final giveItem = request.giveItem;
        TradeApi()
            .getDetailedTradeRequest(request)
            .then((detailedRequest) {
              if (mounted) {
                // isNew 상태 갱신 — notifier setter 경유
                final updatedId = detailedRequest.tradeRequestHistory?.tradeRequestHistoryId;
                final updatedIsNew = detailedRequest.tradeRequestHistory?.isNew;
                if (updatedId != null) {
                  final cur = ref.read(tradeRequestsProvider).value;
                  if (cur != null) {
                    final updatedReceived = cur.received.map((r) {
                      if (r.tradeRequestHistoryId == updatedId) {
                        r.isNew = updatedIsNew;
                      }
                      return r;
                    }).toList();
                    ref.read(tradeRequestsProvider.notifier).setReceived(received: updatedReceived);
                  }
                }
              }
            })
            .catchError((e) {
              debugPrint('교환 요청 상세 조회 실패: $e');
            });
        context.navigateTo(
          screen: ItemDetailDescriptionScreen(
            itemId: giveItem.itemId!,
            // 요청 받은 카드로 이동
            imageSize: Size(MediaQuery.of(context).size.width, 400.h),
            currentImageIndex: 0,
            heroTag: 'itemImage_${request.giveItem.itemId!}_0',
            // ← 인덱스 포함
            isMyItem: false,
            isRequestManagement: true,
            tradeRequestHistoryId: request.tradeRequestHistoryId,
            isChatAccessAllowed: true, // 받은요청 = 채팅 가능
          ),
        );
      },
      onMenuTap: (request) async {
        final result = await context.showDeleteDialog(title: '교환 요청 삭제', description: '정말 삭제하시겠습니까?');

        if (result == true) {
          try {
            await ref
                .read(tradeRequestsProvider.notifier)
                .cancel(tradeRequestHistoryId: request.tradeRequestHistoryId ?? '');
            if (mounted) {
              CommonSnackBar.show(context: context, message: '요청을 삭제했습니다.');
            }
          } catch (e) {
            debugPrint('요청 취소 실패: $e');
            if (mounted) {
              CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
            }
          }
        }
      },
    );
  }
}
