import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'dart:async';

import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';

class RequestManagementTabScreen extends StatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  State<RequestManagementTabScreen> createState() =>
      _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends State<RequestManagementTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  final int _currentPage = 0;
  final int _pageSize = 10;

  // 로딩 상태
  bool _isLoading = false;

  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 현재 선택된 카드 인덱스
  int _currentCardIndex = 0;

  // 카드 컨트롤러
  late PageController _cardController;

  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 받은 요청, true: 보낸 요청)
  bool _isRightSelected = false;

  // 완료된 요청 표시 여부
  bool _showCompletedRequests = false;

  // 테스트용 샘플 데이터
  final List<RequestManagementItemCard> _itemCards = [];

  // 받은 요청 목록 데이터
  final List<TradeRequestHistory> _receivedRequests = [];
  final List<TradeRequestHistory> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 카드 컨트롤러 초기화
    _cardController = PageController(
      initialPage: 0,
      viewportFraction: 0.6, // 화면에 보이는 카드의 비율
    );

    // 토글 애니메이션 컨트롤러 초기화
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadInitialItems();
  }

  /// 초기 아이템 로드
  Future<void> _loadInitialItems({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    if (!mounted) return;

    try {
      final itemApi = ItemApi();
      final response = await itemApi.getMyItems(ItemRequest(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        itemStatus: ItemStatus.available.serverName,
      ));

      if (!mounted) return;

      final itemCard = await _convertToRequestManagementItemCard(
          response.itemPage?.content ?? []);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 로딩 실패: $e')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  /// ItemDetail을 RequestManagementItemCard로 변환
  Future<List<RequestManagementItemCard>> _convertToRequestManagementItemCard(
      List<Item> details) async {
    final itemCards = <RequestManagementItemCard>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      String category =
          ItemCategories.fromServerName(d.itemCategory ?? '기타').label;

      final itemCard = RequestManagementItemCard(
        itemId: d.itemId ?? '',
        imageUrl: d.primaryImageUrl != null
            ? d.primaryImageUrl!
            : 'https://picsum.photos/400/300',
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

  /// 현재 선택된 카드의 받은 요청 목록 로드
  Future<List<TradeRequestHistory>>
      _loadReceivedRequestsForCurrentCard() async {
    if (!mounted) return const [];

    setState(() => _isLoading = true);
    try {
      if (_itemCards.isEmpty ||
          _currentCardIndex < 0 ||
          _currentCardIndex >= _itemCards.length) {
        if (mounted) setState(() => _receivedRequests.clear());
        return const [];
      }

      final currentCard = _itemCards[_currentCardIndex];
      final api = TradeApi();

      final paged = await api.getReceivedTradeRequests(
        TradeRequest(
            takeItemId: currentCard.itemId, pageNumber: 0, pageSize: 10),
      );

      final list = paged.content;
      if (list.isEmpty) {
        if (mounted) setState(() => _receivedRequests.clear());
        return const [];
      }

      // 주소 캐시를 모두 채워둠
      await Future.wait(list.map((r) async {
        await r.takeItem.resolveAndCacheAddress();
        await r.giveItem.resolveAndCacheAddress();
      }));

      if (mounted) {
        setState(() {
          _receivedRequests
            ..clear()
            ..addAll(list);
        });
      }
      return list;
    } catch (e, st) {
      debugPrint('현재 카드의 받은 요청 목록 로드 실패: $e\n$st');
      if (mounted) setState(() => _receivedRequests.clear());
      return const [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  /// 현재 선택된 카드의 보낸 요청 목록 로드
  Future<List<TradeRequestHistory>> _loadSentRequestsForCurrentCard() async {
    if (!mounted) return const [];

    setState(() => _isLoading = true);
    try {
      if (_itemCards.isEmpty ||
          _currentCardIndex < 0 ||
          _currentCardIndex >= _itemCards.length) {
        if (mounted) setState(() => _sentRequests.clear());
        return const [];
      }

      final currentCard = _itemCards[_currentCardIndex];
      final api = TradeApi();

      final paged = await api.getSentTradeRequests(
        TradeRequest(giveItemId: currentCard.itemId),
      );

      final list = paged.content;
      if (list.isEmpty) {
        if (mounted) setState(() => _sentRequests.clear());
        return const [];
      }

      // 주소 캐시를 모두 채워둠
      await Future.wait(list.map((r) async {
        await r.takeItem.resolveAndCacheAddress();
        await r.giveItem.resolveAndCacheAddress();
      }));

      if (mounted) {
        setState(() {
          _sentRequests
            ..clear()
            ..addAll(list);
        });
      }
      return list;
    } catch (e, st) {
      debugPrint('현재 카드의 받은 요청 목록 로드 실패: $e\n$st');
      if (mounted) setState(() => _sentRequests.clear());
      return const [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  /// 보낸 요청 목록
  Widget _buildSentRequestsList() {
    // 보낸 요청은 필터링 없이 모든 요청 표시
    if (_sentRequests.isEmpty) {
      return _isLoading
          ? SizedBox(
              height: 500.h,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                  strokeWidth: 2,
                ),
              ),
            )
          : Container(
              height: 200.h,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text(
                  '보낸 요청이 없습니다',
                  style: CustomTextStyles.p2.copyWith(
                    color: AppColors.opacity60White,
                  ),
                ),
              ),
            );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: List.generate(_sentRequests.length, (index) {
          final request = _sentRequests[index];
          final takeItem = request.takeItem;
          final giveItem = request.giveItem;

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: GestureDetector(
              onTap: () {
                context.navigateTo(
                  screen: ItemDetailDescriptionScreen(
                    itemId: takeItem.itemId!, // 내가 요청 보낸 카드로 이동
                    imageSize: Size(MediaQuery.of(context).size.width, 400.h),
                    currentImageIndex: 0,
                    heroTag: 'itemImage_${takeItem.itemId!}_0', // ← 인덱스 포함
                    isMyItem: false,
                    isRequestManagement: true,
                  ),
                );
              },
              child: SentRequestItemCard(
                myItemImageUrl: giveItem.imageUrlList.isNotEmpty
                    ? giveItem.imageUrlList.first
                    : 'https://picsum.photos/400/300',
                otherItemImageUrl: takeItem.imageUrlList.isNotEmpty
                    ? takeItem.imageUrlList.first
                    : 'https://picsum.photos/400/300',
                otherUserProfileUrl: takeItem.member!.profileUrl!,
                title: takeItem.itemName!,
                location: takeItem.address!,
                createdDate: takeItem.createdDate!,
                tradeOptions: takeItem.itemTradeOptions != null
                    ? takeItem.itemTradeOptions!
                        .map((s) => ItemTradeOption.values
                            .firstWhere((e) => e.serverName == s))
                        .toList()
                    : [],
                tradeStatus: request.tradeStatus != null
                    ? TradeStatus.values.firstWhere(
                        (e) => e.serverName == request.tradeStatus,
                        orElse: () => TradeStatus.chatting,
                      )
                    : TradeStatus.chatting,
                onEditTap: () {
                  context.navigateTo(
                    screen: ItemModificationScreen(
                      itemId: giveItem.itemId,
                      onClose: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
                onCancelTap: () async {
                  try {
                    await TradeApi().cancelTradeRequest(
                      TradeRequest(
                        tradeRequestHistoryId: request.tradeRequestHistoryId,
                      ),
                    );
                  } catch (e) {
                    debugPrint('요청 취소 실패: $e');
                  }
                  if (mounted) {
                    setState(() {
                      _sentRequests
                          .removeAt(index); // Use the correct index here
                    });
                  }
                },
              ),
            ),
          );
        }),
      ),
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

  void _onToggleChanged(bool isRightSelected) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: AppColors.transparent),
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
                        statusBarHeight:
                            MediaQuery.of(context).padding.top, // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 70.h,
                        expandedExtra: 32.h, // 큰 제목/여백
                        enableBlur: _isScrolled, // 스크롤 시 더 진해지게
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 물품 카드 캐러셀 섹션 (받은 요청일 때만 표시)
                          if (!_isRightSelected) ...[
                            SizedBox(height: 10.h),
                            _buildItemCardsCarousel(),
                          ],

                          // 2. 페이지 인디케이터 (받은 요청일 때만 표시)
                          if (!_isRightSelected) _buildPageIndicator(),

                          // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
                          _buildRequestListHeader(),

                          // 4. 요청 목록 리스트
                          _buildFullRequestItemsList(),

                          SizedBox(height: 100.h), // 하단 여백
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
    if (_itemCards.isEmpty) {
      // 데이터가 없을 때 빈 상태 표시
      return _isLoading
          ? SizedBox(
              height: 150.h,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                  strokeWidth: 2,
                ),
              ),
            )
          : Container(
              height: 326.h,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text(
                  '등록된 물품이 없습니다',
                  style: CustomTextStyles.p2.copyWith(
                    color: AppColors.opacity60White,
                  ),
                ),
              ),
            );
    }

    return SizedBox(
      height: 326.h,
      child: PageView.builder(
        controller: _cardController,
        onPageChanged: _onCardPageChanged,
        itemCount: _itemCards.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              context.navigateTo(
                screen: ItemDetailDescriptionScreen(
                  itemId: _itemCards[index].itemId,
                  imageSize: Size(MediaQuery.of(context).size.width, 400.h),
                  currentImageIndex: 0,
                  heroTag:
                      'itemImage_${_itemCards[index].itemId}_0', // ← 인덱스 포함
                  isMyItem: true,
                  isRequestManagement: true,
                ),
              );
            },
            child: RequestManagementItemCardWidget(
              card: _itemCards[index],
              isActive: index == _currentCardIndex,
            ),
          );
        },
      ),
    );
  }

  /// 페이지 인디케이터
  Widget _buildPageIndicator() {
    if (_itemCards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 37.h, 0, 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _itemCards.length,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentCardIndex == index
                  ? AppColors.primaryYellow
                  : AppColors.opacity30White,
            ),
          ),
        ),
      ),
    );
  }

  /// 요청 목록 헤더 섹션
  Widget _buildRequestListHeader() {
    // 보낸 요청에서는 헤더 표시 안함
    if (_isRightSelected) {
      return const SizedBox.shrink();
    }

    // 받은 요청에서만 헤더 표시
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 토글을 한 줄에 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 제목
              Text(
                '요청 목록',
                style: TextStyle(
                  color: AppColors.textColorWhite,
                  fontFamily: 'Pretendard',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              // 완료된 요청 필터 토글
              Row(
                children: [
                  Text(
                    '거래완료된 글표시',
                    style: CustomTextStyles.p3.copyWith(
                      color: const Color(0x80FFFFFF),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CompletedToggleSwitch(
                    value: _showCompletedRequests,
                    onChanged: _toggleCompletedRequests,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 설명 텍스트
          Text(
            '내 물건에 온 교환 요청이에요',
            style: TextStyle(
              color: const Color(0xFFFFFFCC),
              fontFamily: 'Pretendard',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// 요청 목록 리스트
  Widget _buildFullRequestItemsList() {
    // 보낸 요청인 경우
    if (_isRightSelected) {
      return _buildSentRequestsList();
    }

    // 받은 요청인 경우 - 로드된 데이터 사용
    // 완료 여부에 따른 필터링
    final filteredRequests = _receivedRequests.where((request) {
      final status = request.tradeStatus;
      if (_showCompletedRequests) {
        return status == TradeStatus.traded.serverName;
      } else {
        return status != TradeStatus.traded.serverName;
      }
    }).toList();

    if (filteredRequests.isEmpty) {
      return _isLoading
          ? SizedBox(
              height: 150.h,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                  strokeWidth: 2,
                ),
              ),
            )
          : Container(
              height: 200.h,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text(
                  _showCompletedRequests ? '완료된 요청이 없습니다' : '진행 중인 요청이 없습니다',
                  style: CustomTextStyles.p2.copyWith(
                    color: AppColors.opacity60White,
                  ),
                ),
              ),
            );
    }

    return _isLoading
        ? SizedBox(
            height: 150.h,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryYellow,
                strokeWidth: 2,
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: List.generate(filteredRequests.length, (index) {
                final request = filteredRequests[index];
                final giveItem = request.giveItem;

                return Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque, // 빈 공간도 터치 가능
                      onTap: () {
                        context.navigateTo(
                          screen: ItemDetailDescriptionScreen(
                            itemId: giveItem.itemId!, // 요청 받은 카드로 이동
                            imageSize:
                                Size(MediaQuery.of(context).size.width, 400.h),
                            currentImageIndex: 0,
                            heroTag:
                                'itemImage_${request.giveItem.itemId!}_0', // ← 인덱스 포함
                            isMyItem: false,
                            isRequestManagement: true,
                          ),
                        );
                      },
                      child: RequestListItemCardWidget(
                        imageUrl: giveItem.imageUrlList.isNotEmpty
                            ? giveItem.imageUrlList.first
                            : 'https://picsum.photos/400/300',
                        title: giveItem.itemName ?? ' ',
                        address: giveItem.address!,
                        createdDate: giveItem.createdDate!,
                        isNew: request.isNew!,
                        tradeOptions: giveItem.itemTradeOptions != null
                            ? giveItem.itemTradeOptions!
                                .map((s) => ItemTradeOption.values
                                    .firstWhere((e) => e.serverName == s))
                                .toList()
                            : [],
                        tradeStatus: request.tradeStatus != null
                            ? TradeStatus.values.firstWhere(
                                (e) => e.serverName == request.tradeStatus,
                                orElse: () => TradeStatus.chatting,
                              )
                            : TradeStatus.chatting,
                        onMenuTap: () async {
                          try {
                            await TradeApi().cancelTradeRequest(TradeRequest(
                              tradeRequestHistoryId:
                                  request.tradeRequestHistoryId,
                            ));
                          } catch (e) {
                            debugPrint('요청 취소 실패: $e');
                          }
                          if (mounted) {
                            setState(() {
                              _receivedRequests.removeWhere((e) =>
                                  e.tradeRequestHistoryId ==
                                  request.tradeRequestHistoryId);
                            });
                          }
                        },
                      ),
                    ),
                    if (index < filteredRequests.length - 1)
                      Divider(
                        thickness: 1.5,
                        color: AppColors.opacity10White,
                        height: 32.h,
                      ),
                  ],
                );
              }),
            ));
  }
}
