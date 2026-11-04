// 채팅방 실시간(소켓) 수신 판정 순수 함수: 진입 조회 중 보관분 병합, 내 나가기 이벤트, 새 메시지 자동 스크롤·새 메시지 알림
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';

// 맨 아래(최신)로 간주하는 거리 (px, reverse 목록 offset 기준) > 이 안이면 새 메시지 수신 시 따라 내려감
const double nearBottomAutoScrollThresholdPixels = 120;

/// 진입 조회 중 소켓으로 받은 메시지 > 조회 결과에 없는 것만 (도착 순서 유지, ID 중복 제거, ID 없는 메시지는 유지)
List<ChatMessage> findUnseenLiveMessages({
  required List<ChatMessage> liveMessages,
  required List<ChatMessage> displayedMessages,
}) {
  final seenMessageIds = {
    for (final message in displayedMessages)
      if (message.chatMessageId != null) message.chatMessageId!,
  };
  final unseenMessages = <ChatMessage>[];
  for (final message in liveMessages) {
    final id = message.chatMessageId;
    if (id != null && !seenMessageIds.add(id)) continue;
    unseenMessages.add(message);
  }
  return unseenMessages;
}

/// 내가 보낸 나가기(system) 메시지인지 (방 삭제 시 서버 방송 > 내 화면에 '상대방이 나갔습니다' 표시 방지)
bool isOwnLeaveMessage({required ChatMessage message, required String? myMemberId}) =>
    message.type == MessageType.system && myMemberId != null && message.senderId == myMemberId;

// 새 메시지 알림 표시 최대 개수 (초과 시 '99+')
const int maximumDisplayedNewMessageCount = 99;

/// 맨 아래(최신) 근처인지 (자동 스크롤·맨 아래로 버튼 공통 기준)
bool isNearBottom({required double distanceFromBottomPixels}) =>
    distanceFromBottomPixels <= nearBottomAutoScrollThresholdPixels;

/// 새 메시지 수신 시 맨 아래 자동 스크롤 여부 (내 메시지 > 항상, 상대 메시지 > 맨 아래 근처일 때만 > 이전 메시지 읽는 중 유지)
bool shouldAutoScrollOnIncomingMessage({required bool isMyMessage, required double distanceFromBottomPixels}) =>
    isMyMessage || isNearBottom(distanceFromBottomPixels: distanceFromBottomPixels);

/// 위로 올려 보는 중 쌓인 상대 새 메시지 수 (내 메시지·자동 스크롤된 메시지 > 그대로)
int countUnseenIncomingMessages({required int currentCount, required bool isMyMessage, required bool isAutoScrolled}) =>
    (isMyMessage || isAutoScrolled) ? currentCount : currentCount + 1;

/// 새 메시지 알림 문구 (예: 새 메시지 3, 100개 이상 > 새 메시지 99+)
String formatNewMessageCountLabel(int unseenMessageCount) => unseenMessageCount > maximumDisplayedNewMessageCount
    ? '새 메시지 $maximumDisplayedNewMessageCount+'
    : '새 메시지 $unseenMessageCount';
