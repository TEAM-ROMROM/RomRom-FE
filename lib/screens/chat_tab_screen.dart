import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/utils/chat_room_list_rules.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/list_ad_placement.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
import 'package:romrom_fe/widgets/list_native_ad/list_native_ad_cell.dart';
import 'package:romrom_fe/widgets/skeletons/chat_room_list_skeleton.dart';
import 'package:romrom_fe/screens/profile/member_profile_screen.dart';

/// 채팅 탭 화면
class ChatTabScreen extends ConsumerStatefulWidget {
  const ChatTabScreen({super.key});

  @override
  ConsumerState<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends ConsumerState<ChatTabScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  // 스크롤 이벤트 디바운스 시간
  static const Duration _scrollDebounceDelay = Duration(milliseconds: 100);
  Timer? _scrollTimer;
  final ChatWebSocketService _wsService = ChatWebSocketService();

  // 토글 상태 (0: 전체, 1: 보낸 요청, 2: 받은 요청)
  int _selectedTabIndex = 0;

  // 토글 애니메이션
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 페이지네이션 로딩 표시용
  bool _pagingLoading = false;
  bool _prefetchLoading = false;
  // 자동 프리패치 루프 실행 중 (필터 전환·새로고침이 겹쳐 같은 페이지 중복 조회 방지)
  bool _isAutoPrefetching = false;
  int _autoPrefetchCount = 0;
  static const int _autoPrefetchMax = 5;
  // 다음 페이지 실패 후 재시도 대기 시간 (바닥 스크롤마다 연속 재시도·안내 반복 방지)
  static const Duration _loadMoreRetryDelay = Duration(seconds: 3);
  DateTime? _loadMoreFailedAt;

  // 중복 요청 방지
  final Set<String> _pendingRequests = {};

  // 에러 뷰 다시 시도 진행 중 여부 (버튼 스피너·중복 탭 차단)
  bool _isRetryingChatRooms = false;

  // WebSocket 구독 관리
  final Map<String, StreamSubscription<ChatMessage>> _roomSubscriptions = {};
  String? _myMemberId;

  // 재연결 이벤트 구독
  StreamSubscription<void>? _reconnectSubscription;

  @override
  void initState() {
    super.initState();

    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this, upperBound: 2.0);
    _toggleAnimation = _toggleAnimationController;

    _initializeWebSocket();
    _scrollController.addListener(_onScroll);
    // 목록 상태 바뀔 때마다 새로 생긴 방 구독 (새로고침·페이징·병합·생성 경로 공통, 첫 상태 포함)
    ref.listenManual<AsyncValue<ChatRoomsState>>(
      chatRoomsProvider,
      (previous, next) => _subscribeToRoomsInState(),
      fireImmediately: true,
    );
  }

  /// WebSocket 초기화: 회원 ID 확인 > 보류된 목록 구독 > 연결 > 재연결 시 재구독 등록
  Future<void> _initializeWebSocket() async {
    try {
      _myMemberId = await MemberManager.getCurrentMemberId();
      if (_myMemberId == null) {
        debugPrint('채팅방 목록: 사용자 ID를 가져올 수 없습니다');
        return;
      }
      // 회원 ID 확인 전 도착한 목록 구독 보충
      _subscribeToRoomsInState();

      await _wsService.connect();

      // 재연결 시 기존 구독 맵 초기화 후 목록 갱신 + 재구독
      // reload()만 호출하면 _roomSubscriptions가 남아 새 세션 방 구독을 건너뛰므로 _triggerReload() 사용
      _reconnectSubscription = _wsService.onReconnected.listen((_) {
        if (!mounted) return;
        _triggerReload();
      });
    } catch (e) {
      debugPrint('채팅방 목록 WebSocket 초기화 실패: $e');
    }
  }

  /// 목록 상태의 방 중 미구독 방만 WebSocket 구독 (회원 ID 확인 전이면 보류)
  void _subscribeToRoomsInState() {
    if (_myMemberId == null || !mounted) return;
    final rooms = ref.read(chatRoomsProvider).valueOrNull?.rooms ?? const <ChatRoomDetailDto>[];
    final chatRoomIdsToSubscribe = findChatRoomIdsToSubscribe(
      rooms: rooms,
      subscribedChatRoomIds: _roomSubscriptions.keys.toSet(),
    );
    for (final chatRoomId in chatRoomIdsToSubscribe) {
      _roomSubscriptions[chatRoomId] = _wsService.subscribeToChatRoom(chatRoomId).listen((message) {
        if (!mounted) return;
        ref.read(chatRoomsProvider.notifier).onMessageReceived(message: message, myMemberId: _myMemberId);
      });
    }
  }

  /// 필터 탭 전환: 선택 반영 > 불러온 목록에 필터 결과가 모자라면 이어 불러오기
  void _onTabChanged(int index) {
    setState(() => _selectedTabIndex = index);
    _toggleAnimationController.animateTo(index.toDouble(), duration: AppMotion.normal, curve: AppMotion.standard);
    _autoPrefetchCount = 0;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoPrefetch();
    });
  }

  /// 채팅 탭 선택 시 첫 페이지 병합 재조회 (새 방 구독은 목록 상태 구독이 처리)
  /// (상대가 새로 만든 방은 구독 전이라 실시간 수신 불가, 이후 페이지·페이징 위치는 유지)
  Future<void> _refreshOnChatTabSelected() async {
    await ref.read(chatRoomsProvider.notifier).refreshFirstPage();
  }

  /// 무한 스크롤 트리거
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 1) {
      _triggerLoadMore();
    }

    _scrollTimer?.cancel();
    _scrollTimer = Timer(_scrollDebounceDelay, () {});

    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  /// 다음 페이지 로드 (중복 방지, 실패 직후 재시도 대기, 실패 안내)
  Future<void> _triggerLoadMore() async {
    if (_pendingRequests.contains('loadMore')) return;
    final cur = ref.read(chatRoomsProvider).valueOrNull;
    if (cur == null || !cur.hasMore) return;
    final lastFailedAt = _loadMoreFailedAt;
    if (lastFailedAt != null && DateTime.now().difference(lastFailedAt) < _loadMoreRetryDelay) return;

    _pendingRequests.add('loadMore');
    setState(() => _pagingLoading = true);
    try {
      await ref.read(chatRoomsProvider.notifier).loadMore();
      _loadMoreFailedAt = null;
    } catch (e) {
      debugPrint('[ChatTab] next page load failed: $e');
      _loadMoreFailedAt = DateTime.now();
      _showLoadMoreFailedSnackBar();
    } finally {
      if (mounted) setState(() => _pagingLoading = false);
      _pendingRequests.remove('loadMore');
    }
  }

  /// 새로고침 (RefreshIndicator / 재연결 콜백)
  Future<void> _triggerReload() async {
    if (_pendingRequests.contains('reload')) return;
    _pendingRequests.add('reload');

    // 재연결 시 기존 WS 구독 해제 후 재구독
    final previous = Map<String, StreamSubscription<ChatMessage>>.from(_roomSubscriptions);
    _roomSubscriptions.clear();
    await Future.wait(
      previous.entries.map((e) async {
        await e.value.cancel();
        _wsService.unsubscribeFromChatRoom(e.key);
      }),
    );

    try {
      await ref.read(chatRoomsProvider.notifier).reload();
      if (!mounted) return;

      // 재조회 실패 + 기존 목록 있음 > 목록 유지 + 스낵바 (목록 없으면 에러 뷰가 대신 표시, 재구독은 계속)
      final reloaded = ref.read(chatRoomsProvider);
      if (reloaded.hasError && (reloaded.valueOrNull?.rooms.isNotEmpty ?? false)) {
        CommonSnackBar.show(context: context, type: SnackBarType.error, message: '채팅방을 불러오는 중 오류가 발생했습니다');
      }

      // 초기 로드와 마찬가지로 스크롤 가능해질 때까지 프리패치
      _autoPrefetchCount = 0;
      await _autoPrefetch();

      // 재조회 결과가 이전과 같아 상태 알림이 없어도 비운 구독 복구
      _subscribeToRoomsInState();
    } catch (e) {
      debugPrint('채팅방 목록 새로고침 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, type: SnackBarType.error, message: '채팅방을 불러오는 중 오류가 발생했습니다');
      }
    } finally {
      _pendingRequests.remove('reload');
    }
  }

  /// 에러 뷰 다시 시도: 진행 중이면 무시 > 전체 새로고침
  Future<void> _onRetryChatRoomsPressed() async {
    if (_isRetryingChatRooms) return;
    setState(() => _isRetryingChatRooms = true);
    try {
      await _triggerReload();
    } finally {
      if (mounted) setState(() => _isRetryingChatRooms = false);
    }
  }

  void _showLoadMoreFailedSnackBar() {
    if (!mounted) return;
    CommonSnackBar.show(context: context, type: SnackBarType.error, message: '채팅방을 더 불러오지 못했어요');
  }

  /// 다음 페이지 1회 프리패치 (실패 시 안내 후 false > 프리패치 중단)
  Future<bool> _prefetchNextPage() async {
    try {
      await ref.read(chatRoomsProvider.notifier).loadMore();
    } catch (e) {
      debugPrint('[ChatTab] prefetch failed: $e');
      _loadMoreFailedAt = DateTime.now();
      _showLoadMoreFailedSnackBar();
      return false;
    }
    return true;
  }

  /// 초기 로드 / 리프레시 / 필터 전환 후 스크롤 가능해질 때까지 자동 프리패치
  Future<void> _autoPrefetch() async {
    if (_isAutoPrefetching) return;
    _isAutoPrefetching = true;
    try {
      await _runAutoPrefetchLoop();
    } finally {
      _isAutoPrefetching = false;
    }
  }

  Future<void> _runAutoPrefetchLoop() async {
    while (true) {
      final cur = ref.read(chatRoomsProvider).valueOrNull;
      if (cur == null || !cur.hasMore) break;
      if (_autoPrefetchCount >= _autoPrefetchMax) break;

      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) break;

      // 스크롤 뷰 미부착이거나 스크롤할 만큼 목록이 없으면 다음 페이지
      final isScrollable = _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0;
      if (isScrollable) break;

      _autoPrefetchCount++;
      setState(() => _prefetchLoading = true);
      if (!await _prefetchNextPage()) break;
      if (!mounted) break;
    }

    if (mounted && _prefetchLoading) setState(() => _prefetchLoading = false);
  }

  /// 필터링된 채팅방 목록 반환
  List<ChatRoomDetailDto> _getFilteredChatRooms(List<ChatRoomDetailDto> rooms) {
    switch (_selectedTabIndex) {
      case 0:
        return rooms;
      case 1:
        return rooms.where((room) => room.chatRoomType == ChatRoomType.requested).toList();
      case 2:
        return rooms.where((room) => room.chatRoomType == ChatRoomType.received).toList();
      default:
        return rooms;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatRoomsProvider);

    // 최초 로드 완료 직후 자동 프리패치 (WS 구독은 initState 상태 구독이 처리)
    ref.listen<AsyncValue<ChatRoomsState>>(chatRoomsProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData<ChatRoomsState>) {
        _autoPrefetchCount = 0;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _autoPrefetch();
        });
      }
    });

    // 채팅 탭으로 전환될 때마다 첫 페이지 병합 재조회 (IndexedStack이라 initState 재실행 없음)
    ref.listen<int>(currentTabIndexProvider, (previousTabIndex, nextTabIndex) {
      if (nextTabIndex == NavigationTabItems.chat.index && previousTabIndex != nextTabIndex) {
        _refreshOnChatTabSelected();
      }
    });

    final rooms = chatAsync.valueOrNull?.rooms ?? const [];
    final hasMoreRooms = chatAsync.valueOrNull?.hasMore ?? false;
    final isInitialLoading = chatAsync is AsyncLoading && rooms.isEmpty;
    // 불러오기 실패 + 보여줄 목록 없음 > 에러 뷰 (목록 있으면 목록 유지)
    final hasLoadErrorWithoutRooms = chatAsync.hasError && rooms.isEmpty;
    final filteredRooms = _getFilteredChatRooms(rooms);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryYellow,
          backgroundColor: AppColors.transparent,
          displacement: MediaQuery.of(context).padding.top + 58.h + 62.h,
          onRefresh: _triggerReload,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: GlassHeaderDelegate(
                  headerTitle: '채팅',
                  toggle: TripleToggleSwitch(
                    animation: _toggleAnimation,
                    selectedIndex: _selectedTabIndex,
                    onFirstTap: () => _onTabChanged(0),
                    onSecondTap: () => _onTabChanged(1),
                    onThirdTap: () => _onTabChanged(2),
                    firstText: '전체',
                    secondText: '보낸 요청',
                    thirdText: '받은 요청',
                  ),
                  statusBarHeight: MediaQuery.of(context).padding.top,
                  toolbarHeight: 58.h,
                  toggleHeight: 62.h,
                  expandedExtra: 16.h,
                  enableBlur: _isScrolled,
                ),
              ),

              // 3상태: 초기 로딩 스켈레톤 / 에러 뷰 / 빈 상태 (필터 탭별 공통)
              if (isInitialLoading)
                const ChatRoomListSkeletonSliver(itemCount: 5)
              else if (hasLoadErrorWithoutRooms)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView.error(
                    centerText: '채팅을 불러오지 못했어요',
                    onRetry: _onRetryChatRoomsPressed,
                    isRetrying: _isRetryingChatRooms,
                  ),
                )
              else if (filteredRooms.isEmpty && hasMoreRooms)
                // 불러온 페이지에 필터 결과 없음 + 다음 페이지 있음 > 빈 상태 대신 이어 불러오기
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: AppIcons.chat,
                    centerText: '불러온 채팅에는 없어요',
                    descriptionText: '이전 채팅을 더 불러와 찾아볼게요',
                    buttonText: '더 불러오기',
                    onButtonTap: _triggerLoadMore,
                    isButtonLoading: _pagingLoading || _prefetchLoading,
                  ),
                )
              else if (filteredRooms.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(icon: AppIcons.chat, centerText: '아직 채팅이 없어요'),
                ),

              // 데이터 있을 때: 채팅방 리스트
              if (filteredRooms.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, listIndex) {
                    // 3번째 방 뒤 광고 1칸 (방 행과 같은 여백·아래 간격, 실패 시 간격째 접힘)
                    if (ListAdPlacement.chatRoomList.isAdAtListIndex(listIndex, filteredRooms.length)) {
                      return ListNativeAdCell(
                        horizontalPadding: 24.w,
                        bottomSeparator: SizedBox(height: 8.h),
                      );
                    }
                    final index = ListAdPlacement.chatRoomList.contentIndexAtListIndex(listIndex);
                    final chatRoomDetail = filteredRooms[index];

                    return AppFadeSlideIn(
                      delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
                      child: Column(
                        children: [
                          ChatRoomListItem(
                            accountStatus: chatRoomDetail.targetMember?.accountStatus,
                            profileImageUrl: chatRoomDetail.targetMember?.profileUrl ?? '',
                            memberId: chatRoomDetail.targetMember?.memberId,
                            nickname: chatRoomDetail.targetMember?.nickname ?? '',
                            location: chatRoomDetail.targetMemberEupMyeonDong ?? '',
                            lastMessageTimeLabel: formatListTimestamp(chatRoomDetail.lastMessageTime),
                            messagePreview: chatRoomDetail.lastMessageContent ?? '',
                            unreadCount: chatRoomDetail.unreadCount ?? 0,
                            targetItemImageUrl: chatRoomDetail.targetItemImageUrl,
                            myItemImageUrl: chatRoomDetail.myItemImageUrl,
                            isNew: chatRoomDetail.unreadCount != null && chatRoomDetail.unreadCount! > 0,
                            onProfileTap: () {
                              final targetMember = chatRoomDetail.targetMember;
                              if (targetMember?.memberId != null) {
                                context.navigateTo(screen: MemberProfileScreen(memberId: targetMember!.memberId!));
                              }
                            },
                            onTap: () async {
                              debugPrint('채팅방 클릭: ${chatRoomDetail.chatRoomId}');

                              final roomId = chatRoomDetail.chatRoomId;
                              if (roomId == null) return;

                              // 입장 시 unreadCount 즉시 0으로 초기화 (낙관적 업데이트)
                              ref.read(chatRoomsProvider.notifier).markRoomAsRead(roomId);

                              final refreshed = await context.navigateTo<bool>(
                                screen: ChatRoomScreen(
                                  chatRoomId: roomId,
                                  unreadCountAtEntry: chatRoomDetail.unreadCount,
                                ),
                              );

                              // pop(true) 신호: 목록에 영향 있는 변경 (차단 등) > 불러온 페이지 유지한 채 재조회
                              if (refreshed == true && mounted) {
                                unawaited(ref.read(chatRoomsProvider.notifier).refreshLoadedPages());
                              }
                            },
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    );
                  }, childCount: ListAdPlacement.chatRoomList.listItemCount(filteredRooms.length)),
                ),

              // 추가 페이지 로딩: 작은 인디케이터 (무한 스크롤)
              if ((_pagingLoading || _prefetchLoading) && rooms.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(child: CommonLoadingIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final entry in _roomSubscriptions.entries) {
      entry.value.cancel();
      _wsService.unsubscribeFromChatRoom(entry.key);
    }
    _roomSubscriptions.clear();
    _reconnectSubscription?.cancel();

    _scrollController.dispose();
    _scrollTimer?.cancel();
    _toggleAnimationController.dispose();
    super.dispose();
  }
}
