import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';

/// 채팅 탭 화면
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // 스크롤 상태
  bool _isScrolled = false;

  // 토글 상태 (0: 전체, 1: 보낸 요청, 2: 받은 요청)
  int _selectedTabIndex = 0;

  // 토글 애니메이션
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 채팅방 목록
  List<ChatRoom> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 애니메이션 컨트롤러 (0.0 ~ 2.0)
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      upperBound: 2.0, // 3개 탭이므로 2.0
    );
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadDummyData();
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
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

  void _loadDummyData() {
    _chatRooms = [
      ChatRoom(
        chatRoomId: '1',
        otherUserNickname: '닉네임',
        otherUserProfileUrl: null,
        otherUserLocation: '화양동',
        lastMessage: '저 진짜 최송한데 그럼 택배비만 네고 안될까요...',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 1,
        isNew: true,
      ),
      ChatRoom(
        chatRoomId: '2',
        otherUserNickname: '닉네임이 진짜 길나 길면 어떡...',
        otherUserProfileUrl: null,
        otherUserLocation: '화양동',
        lastMessage: 'abcdefghijklmnopqrstuvwxyzabcdefghij...',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 2,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '3',
        otherUserNickname: '닉네임',
        otherUserProfileUrl: null,
        otherUserLocation: '화양동',
        lastMessage: '채팅내용',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '4',
        otherUserNickname: '닉네임',
        otherUserProfileUrl: null,
        otherUserLocation: '화양동',
        lastMessage: '채팅내용',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isNew: false,
      ),
    ];
    setState(() {});
  }

  List<ChatRoom> _getFilteredChatRooms() {
    // TODO: API 연동 시 필터링 로직 구현
    // switch (_selectedTabIndex) {
    //   case 0: // 전체
    //     return _chatRooms;
    //   case 1: // 보낸 요청
    //     return _chatRooms.where((room) => room.isSentRequest).toList();
    //   case 2: // 받은 요청
    //     return _chatRooms.where((room) => room.isReceivedRequest).toList();
    //   default:
    //     return _chatRooms;
    // }
    return _chatRooms;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 헤더 (토글 포함)
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
                toggleHeight: 70.h,
                expandedExtra: 32.h,
                enableBlur: _isScrolled,
              ),
            ),

            // 채팅방 리스트
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chatRoom = _getFilteredChatRooms()[index];
                  return Column(
                    children: [
                      ChatRoomListItem(
                        profileImageUrl: chatRoom.otherUserProfileUrl,
                        nickname: chatRoom.otherUserNickname,
                        location: chatRoom.otherUserLocation,
                        timeAgo: CommonUtils.getTimeAgo(chatRoom.lastMessageTime),
                        messagePreview: chatRoom.lastMessage,
                        unreadCount: chatRoom.unreadCount,
                        isNew: chatRoom.isNew,
                        onTap: () {
                          // TODO: 채팅방 상세 화면으로 이동
                          debugPrint('채팅방 클릭: ${chatRoom.chatRoomId}');
                        },
                      ),
                      Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color: AppColors.opacity10White,
                      ),
                    ],
                  );
                },
                childCount: _getFilteredChatRooms().length,
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
