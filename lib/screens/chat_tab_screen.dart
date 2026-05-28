import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
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
  int _autoPrefetchCount = 0;
  static const int _autoPrefetchMax = 5;

  // 중복 요청 방지
  final Set<String> _pendingRequests = {};

  // WebSocket 구독 관리
  final Map<String, StreamSubscription<ChatMessage>> _roomSubscriptions = {};
  String? _myMemberId;

  // 재연결 이벤트 구독
  StreamSubscription<void>? _reconnectSubscription;

  @override
  void initState() {
    super.initState();

    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      upperBound: 2.0,
    );
    _toggleAnimation = _toggleAnimationController;

    _initializeWebSocket();
    _scrollController.addListener(_onScroll);
  }

  /// WebSocket 초기화 및 연결
  Future<void> _initializeWebSocket() async {
    try {
      _myMemberId = await MemberManager.getCurrentMemberId();
      if (_myMemberId == null) {
        debugPrint('채팅방 목록: 사용자 ID를 가져올 수 없습니다');
        return;
      }

      await _wsService.connect();

      // 재연결 시 목록 갱신 (단절 동안 변경된 lastMessage/unreadCount 복구)
      _reconnectSubscription = _wsService.onReconnected.listen((_) {
        if (!mounted) return;
        ref.read(chatRoomsProvider.notifier).reload();
      });
    } catch (e) {
      debugPrint('채팅방 목록 WebSocket 초기화 실패: $e');
    }
  }

  /// 모든 채팅방에 대해 WebSocket 구독
  void _subscribeToRooms(List<ChatRoomDetailDto> rooms) {
    if (_myMemberId == null) return;

    for (final room in rooms) {
      if (room.chatRoomId == null) continue;
      if (_roomSubscriptions.containsKey(room.chatRoomId)) continue;

      final subscription = _wsService.subscribeToChatRoom(room.chatRoomId!).listen((message) {
        if (!mounted) return;
        ref.read(chatRoomsProvider.notifier).onMessageReceived(message: message, myMemberId: _myMemberId);
      });

      _roomSubscriptions[room.chatRoomId!] = subscription;
    }
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTabIndex = index);
    _toggleAnimationController.animateTo(
      index.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 무한 스크롤 트리거
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 1) {
      _triggerLoadMore();
    }

    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {});

    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  /// 다음 페이지 로드 (중복 방지)
  Future<void> _triggerLoadMore() async {
    if (_pendingRequests.contains('loadMore')) return;
    final cur = ref.read(chatRoomsProvider).value;
    if (cur == null || !cur.hasMore) return;

    _pendingRequests.add('loadMore');
    setState(() => _pagingLoading = true);
    try {
      await ref.read(chatRoomsProvider.notifier).loadMore();
      // 새로 로드된 방들 구독
      final updated = ref.read(chatRoomsProvider).value;
      if (updated != null) _subscribeToRooms(updated.rooms);
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

      // 초기 로드와 마찬가지로 스크롤 가능해질 때까지 프리패치
      _autoPrefetchCount = 0;
      await _autoPrefetch();

      final updated = ref.read(chatRoomsProvider).value;
      if (updated != null) _subscribeToRooms(updated.rooms);
    } catch (e) {
      debugPrint('채팅방 목록 새로고침 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, type: SnackBarType.error, message: '채팅방을 불러오는 중 오류가 발생했습니다');
      }
    } finally {
      _pendingRequests.remove('reload');
    }
  }

  /// 초기 로드 / 리프레시 후 스크롤 가능해질 때까지 자동 프리패치
  Future<void> _autoPrefetch() async {
    while (true) {
      final cur = ref.read(chatRoomsProvider).value;
      if (cur == null || !cur.hasMore) break;
      if (_autoPrefetchCount >= _autoPrefetchMax) break;

      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) break;

      if (!_scrollController.hasClients) {
        _autoPrefetchCount++;
        setState(() => _prefetchLoading = true);
        await ref.read(chatRoomsProvider.notifier).loadMore();
        final updated = ref.read(chatRoomsProvider).value;
        if (updated != null) _subscribeToRooms(updated.rooms);
        continue;
      }

      final isScrollable = _scrollController.position.maxScrollExtent > 0;
      if (isScrollable) break;

      setState(() => _prefetchLoading = true);
      _autoPrefetchCount++;
      await ref.read(chatRoomsProvider.notifier).loadMore();
      final updated = ref.read(chatRoomsProvider).value;
      if (updated != null) _subscribeToRooms(updated.rooms);
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

    // 최초 로드 완료 직후 WS 구독 + 자동 프리패치
    ref.listen<AsyncValue<ChatRoomsState>>(chatRoomsProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData<ChatRoomsState>) {
        _subscribeToRooms(next.value.rooms);
        _autoPrefetchCount = 0;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _autoPrefetch();
        });
      }
    });

    final rooms = chatAsync.value?.rooms ?? const [];
    final isInitialLoading = chatAsync is AsyncLoading && rooms.isEmpty;
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

              // 초기 로딩: 스켈레톤 표시
              if (isInitialLoading) const ChatRoomListSkeletonSliver(itemCount: 5),

              // 데이터 있을 때: 채팅방 리스트
              if (rooms.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                            timeAgo: getTimeAgo(chatRoomDetail.lastMessageTime ?? DateTime.now()),
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
                                screen: ChatRoomScreen(chatRoomId: roomId),
                              );

                              // pop(true) 신호: 채팅방에서 변경 발생 (나가기·삭제·거래완료 등)
                              if (refreshed == true) {
                                ref.read(chatRoomsProvider.notifier).reload();
                              }
                            },
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    );
                  }, childCount: filteredRooms.length),
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
