// 채팅방 상단(앱바·거래 카드): 입력이 같으면 이전 인스턴스 재사용 > 메시지 수신·입력마다 재빌드 생략
part of '../chat_room_screen.dart';

mixin _ChatRoomHeader on _ChatRoomScreenStateFields, _ChatRoomExitActions {
  final WidgetInstanceCache<PreferredSizeWidget> _appBarCache = WidgetInstanceCache<PreferredSizeWidget>();
  final WidgetInstanceCache<Widget> _tradeInfoCardCache = WidgetInstanceCache<Widget>();

  /// 앱바: 상대 닉네임·ID·접속 상태가 바뀔 때만 새로 생성 (콜백은 이 화면 메서드라 고정)
  PreferredSizeWidget _buildCachedAppBar() {
    return _appBarCache.resolve(
      [_opponentNickname, _opponentId, _isOpponentOnline, _opponentLastActiveAt],
      () => buildChatRoomAppBar(
        context: context,
        opponentNickname: _opponentNickname,
        opponentId: _opponentId,
        isOpponentOnline: _isOpponentOnline,
        opponentLastActiveAt: _opponentLastActiveAt,
        onBackPressed: () => _leaveRoom(shouldPop: true),
        onBlockConfirm: _blockOpponentAndLeave,
        onLeaveChatRoomConfirm: _deleteRoomAndLeave,
      ),
    );
  }

  /// 거래 카드: 채팅방 정보(재조회 시 새 객체)·내 ID가 바뀔 때만 새로 생성
  Widget _buildCachedTradeInfoCard() {
    return _tradeInfoCardCache.resolve([
      chatRoom,
      _myId,
    ], () => ChatTradeInfoCard(chatRoom: chatRoom, myMemberId: _myId));
  }
}
