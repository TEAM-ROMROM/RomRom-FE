import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
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

    // 애니메이션 컨트롤러 (0.0 ~ 2.0)
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      upperBound: 2.0, // 3개 탭이므로 2.0
    );
    // 컨트롤러를 직접 사용 (CurvedAnimation은 0~1 범위만 지원)
    _toggleAnimation = _toggleAnimationController;

    _loadDummyData();
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
      ChatRoom(
        chatRoomId: '5',
        otherUserNickname: '김철수',
        otherUserProfileUrl: null,
        otherUserLocation: '성동구',
        lastMessage: '네 감사합니다~',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '6',
        otherUserNickname: '이영희',
        otherUserProfileUrl: null,
        otherUserLocation: '강남구',
        lastMessage: '직거래 가능한가요?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        unreadCount: 3,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '7',
        otherUserNickname: '박민수',
        otherUserProfileUrl: null,
        otherUserLocation: '송파구',
        lastMessage: '상품 상태 좋네요',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 8)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '8',
        otherUserNickname: '최지훈',
        otherUserProfileUrl: null,
        otherUserLocation: '마포구',
        lastMessage: '내일 오후에 만날 수 있을까요?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 1,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '9',
        otherUserNickname: '정수진',
        otherUserProfileUrl: null,
        otherUserLocation: '용산구',
        lastMessage: '좋아요! 거래할게요',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '10',
        otherUserNickname: '강동원',
        otherUserProfileUrl: null,
        otherUserLocation: '광진구',
        lastMessage: '혹시 다른 상품도 있나요?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '11',
        otherUserNickname: '윤서아',
        otherUserProfileUrl: null,
        otherUserLocation: '서초구',
        lastMessage: '가격 조정 가능할까요?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
        unreadCount: 0,
        isNew: false,
      ),
      ChatRoom(
        chatRoomId: '12',
        otherUserNickname: '한지민',
        otherUserProfileUrl: null,
        otherUserLocation: '강동구',
        lastMessage: '사진 더 보내주실 수 있나요?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 5)),
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
            // 정적 제목
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                child: Text(
                  '채팅',
                  style: CustomTextStyles.h1,
                ),
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
                        timeAgo: getTimeAgo(chatRoom.lastMessageTime),
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
