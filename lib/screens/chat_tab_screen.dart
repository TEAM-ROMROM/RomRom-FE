import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
import 'package:romrom_fe/widgets/skeletons/chat_room_list_skeleton.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';

/// 채팅 탭 화면
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ChatApi _chatApi = ChatApi();
  final ChatWebSocketService _wsService = ChatWebSocketService();

  // 토글 상태 (0: 전체, 1: 보낸 요청, 2: 받은 요청)
  int _selectedTabIndex = 0;

  // 토글 애니메이션
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 채팅방 목록
  final List<ChatRoomDetailDto> _chatRoomsDetail = [];

  // 페이지네이션 상태
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  // Slice 기반 페이지네이션: 한 번에 8개씩 요청
  final int _pageSize = 8;

  // WebSocket 구독 관리
  final Map<String, StreamSubscription<ChatMessage>> _roomSubscriptions = {};
  String? _myMemberId;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 (0.0 ~ 2.0)
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      upperBound: 2.0, // 3개 탭이므로 2.0
    );
    // 컨트롤러를 직접 사용 (CurvedAnimation은 0~1 범위만 지원)
    _toggleAnimation = _toggleAnimationController;

    // 현재 사용자 ID 가져오기
    _initializeWebSocket();

    // API 호출로 채팅방 목록 로드
    _loadChatRooms();

    // 무한 스크롤 리스너 추가
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

      // WebSocket 연결
      await _wsService.connect();

      // 채팅방 목록이 로드되면 각 채팅방을 구독
      // _loadChatRooms 완료 후 _subscribeToAllRooms 호출
    } catch (e) {
      debugPrint('채팅방 목록 WebSocket 초기화 실패: $e');
    }
  }

  /// 모든 채팅방에 대해 WebSocket 구독
  void _subscribeToAllRooms() {
    if (_myMemberId == null) return;

    for (final room in _chatRoomsDetail) {
      if (room.chatRoomId == null) continue;

      // 이미 구독 중이면 스킵
      if (_roomSubscriptions.containsKey(room.chatRoomId)) continue;

      final subscription = _wsService
          .subscribeToChatRoom(room.chatRoomId!)
          .listen((message) {
            _onMessageReceived(message);
          });

      _roomSubscriptions[room.chatRoomId!] = subscription;
    }
  }

  /// 메시지 수신 시 채팅방 목록 업데이트
  void _onMessageReceived(ChatMessage message) {
    if (!mounted || message.chatRoomId == null) return;

    final roomId = message.chatRoomId!;
    final roomIndex = _chatRoomsDetail.indexWhere(
      (room) => room.chatRoomId == roomId,
    );

    if (roomIndex == -1) {
      // 채팅방이 목록에 없으면 무시 (또는 새로고침)
      debugPrint('채팅방 목록에 없는 메시지 수신: $roomId');
      return;
    }

    setState(() {
      final room = _chatRoomsDetail[roomIndex];

      // 최근 메시지 정보 업데이트
      final updatedRoom = ChatRoomDetailDto(
        chatRoomId: room.chatRoomId,
        targetMember: room.targetMember,
        targetMemberEupMyeonDong: room.targetMemberEupMyeonDong,
        lastMessageContent: message.content ?? '',
        lastMessageTime: message.createdDate ?? DateTime.now(),
        unreadCount: _calculateUnreadCount(room, message),
        chatRoomType: room.chatRoomType,
      );

      // 목록에서 제거 후 맨 앞에 추가 (최신 메시지가 있는 채팅방이 위로)
      _chatRoomsDetail.removeAt(roomIndex);
      _chatRoomsDetail.insert(0, updatedRoom);
    });
  }

  /// 읽지 않은 메시지 수 계산
  int _calculateUnreadCount(ChatRoomDetailDto room, ChatMessage message) {
    // 내가 보낸 메시지면 unreadCount 증가하지 않음
    if (message.senderId == _myMemberId) {
      return room.unreadCount ?? 0;
    }

    // 상대방이 보낸 메시지면 unreadCount 증가
    return (room.unreadCount ?? 0) + 1;
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _toggleAnimationController.animateTo(
      index.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// API 호출: 채팅방 목록 로드
  Future<void> _loadChatRooms({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 0;
        _chatRoomsDetail.clear();
          _hasMore = true;
      }
    });

    try {
      final pagedChatRoomsDetail = await _chatApi.getChatRooms(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        if (isRefresh) {
          // 새로고침 시 기존 구독 모두 해제
          final previousSubscriptions = Map<String, StreamSubscription<ChatMessage>>.from(
            _roomSubscriptions,
          );
          _roomSubscriptions.clear();
          for(final entry in previousSubscriptions.entries) {
            entry.value.cancel();
            _wsService.unsubscribeFromChatRoom(entry.key);
          }
        }

        _chatRoomsDetail.addAll(pagedChatRoomsDetail.content);

        // Slice: last == true면 더 이상 요청하지 않음
        _hasMore = !(pagedChatRoomsDetail.last);

        if (_hasMore) {
          _currentPage++;
        }
        _isLoading = false;
      });

      // 새로 로드된 채팅방들에 대해 WebSocket 구독
      _subscribeToAllRooms();
    } catch (e) {
      debugPrint('채팅방 목록 로드 실패: $e');
      setState(() => _isLoading = false);
      // FIXME: 에러 스낵바 표시 추가 필요
      // CommonSnackBar.show(context, '채팅방을 불러오는 중 오류가 발생했습니다');
    }
  }

  /// 무한 스크롤 리스너
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadChatRooms();
    }
  }

  /// 필터링된 채팅방 목록 반환
  List<ChatRoomDetailDto> _getFilteredChatRooms() {
    switch (_selectedTabIndex) {
      case 0: // 전체
        return _chatRoomsDetail;
      case 1: // 보낸 요청 (내가 tradeSender)
        return _chatRoomsDetail
            .where((room) => room.chatRoomType == ChatRoomType.requested)
            .toList();
      case 2: // 받은 요청 (내가 tradeReceiver)
        return _chatRoomsDetail
            .where((room) => room.chatRoomType == ChatRoomType.received)
            .toList();
      default:
        return _chatRoomsDetail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 정적 제목
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                child: Text('채팅', style: CustomTextStyles.h1),
              ),
            ),

            // 토글 스위치
            SliverToBoxAdapter(
              child: TripleToggleSwitch(
                animation: _toggleAnimation,
                selectedIndex: _selectedTabIndex,
                onFirstTap: () => _onTabChanged(0),
                onSecondTap: () => _onTabChanged(1),
                onThirdTap: () => _onTabChanged(2),
                firstText: '전체',
                secondText: '보낸 요청',
                thirdText: '받은 요청',
              ),
            ),

            // 초기 로딩: 스켈레톤 표시
            if (_isLoading && _chatRoomsDetail.isEmpty)
              const ChatRoomListSkeletonSliver(itemCount: 5),

            // 데이터 있을 때: 채팅방 리스트
            if (_chatRoomsDetail.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final chatRoomDetail = _getFilteredChatRooms()[index];

                  return Column(
                    children: [
                      ChatRoomListItem(
                        profileImageUrl:
                            chatRoomDetail.targetMember?.profileUrl ?? '',
                        memberId: chatRoomDetail.targetMember?.memberId,
                        nickname: chatRoomDetail.targetMember?.nickname ?? '',
                        location: chatRoomDetail.targetMemberEupMyeonDong ?? '',
                        timeAgo: getTimeAgo(
                          chatRoomDetail.lastMessageTime ?? DateTime.now(),
                        ),
                        messagePreview: chatRoomDetail.lastMessageContent ?? '',
                        unreadCount: chatRoomDetail.unreadCount ?? 0,
                        isNew:
                            chatRoomDetail.unreadCount != null &&
                            chatRoomDetail.unreadCount! > 0,
                        onProfileTap: () {
                          final targetMember = chatRoomDetail.targetMember;
                          if (targetMember?.memberId != null) {
                            context.navigateTo(
                              screen: ProfileScreen(
                                memberId: targetMember!.memberId!,
                              ),
                            );
                          }
                        },
                        onTap: () async {
                          debugPrint('채팅방 클릭: ${chatRoomDetail.chatRoomId}');

                          // 채팅방 입장 시 unreadCount 초기화를 위해 목록 업데이트
                          final roomId = chatRoomDetail.chatRoomId!;
                          final roomIndex = _chatRoomsDetail.indexWhere(
                            (r) => r.chatRoomId == roomId,
                          );

                          if (roomIndex != -1) {
                            setState(() {
                              final room = _chatRoomsDetail[roomIndex];
                              _chatRoomsDetail[roomIndex] = ChatRoomDetailDto(
                                chatRoomId: room.chatRoomId,
                                targetMember: room.targetMember,
                                targetMemberEupMyeonDong:
                                    room.targetMemberEupMyeonDong,
                                lastMessageContent: room.lastMessageContent,
                                lastMessageTime: room.lastMessageTime,
                                unreadCount: 0, // 읽음 처리
                                chatRoomType: room.chatRoomType,
                              );
                            });
                          }

                          final refreshed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatRoomScreen(chatRoomId: roomId),
                                ),
                              );

                          // 엄격히 true일 때만 새로고침
                          if (refreshed == true) {
                            _loadChatRooms(isRefresh: true);
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                    ],
                  );
                }, childCount: _getFilteredChatRooms().length),
              ),

            // 추가 페이지 로딩: 작은 인디케이터 (무한 스크롤)
            if (_isLoading && _chatRoomsDetail.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 모든 채팅방 구독 해제 (참조 카운팅으로 다른 화면의 구독은 유지됨)
    for (final entry in _roomSubscriptions.entries) {
      entry.value.cancel();
      _wsService.unsubscribeFromChatRoom(entry.key);
    }
    _roomSubscriptions.clear();

    // WebSocket은 싱글톤이므로 여기서 disconnect하지 않음
    // (다른 화면에서도 사용 중일 수 있음)

    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }
}
