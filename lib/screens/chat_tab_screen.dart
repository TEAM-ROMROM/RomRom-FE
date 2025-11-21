import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
import 'package:romrom_fe/widgets/skeletons/chat_room_list_skeleton.dart';

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
  final int _pageSize = 20;

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

    // API 호출로 채팅방 목록 로드
    _loadChatRooms();

    // 무한 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
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
        _chatRoomsDetail.addAll(pagedChatRoomsDetail.content);
        _hasMore =
            _currentPage < (pagedChatRoomsDetail.page?.totalPages ?? 1) - 1;
        _currentPage++;
        _isLoading = false;
      });
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
                        onTap: () async {
                          debugPrint('채팅방 클릭: ${chatRoomDetail.chatRoomId}');
                          final refreshed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    chatRoomId: chatRoomDetail.chatRoomId!,
                                  ),
                                ),
                              );

                          // 엄격히 true일 때만 새로고침
                          if (refreshed == true) {
                            _loadChatRooms(isRefresh: true);
                          }

                          // 혹시 결과 누락 대비 기본 새로고침을 원하면 아래처럼
                          // _loadChatRooms(isRefresh: refreshed ?? true);
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
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }
}
