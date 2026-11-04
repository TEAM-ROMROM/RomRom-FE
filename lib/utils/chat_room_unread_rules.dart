// 채팅방 진입 시 안 읽은 첫 메시지 판정 순수 함수 (목록은 reverse 정렬: index 0 = 최신)
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';

// 안 읽은 첫 메시지 찾기 위해 진입 시 더 불러올 이전 페이지 최대 수 (초과 시 맨 아래로)
const int maximumUnreadSearchOlderPageCount = 3;

/// 채팅 목록 상태의 방 안 읽음 수 (목록에 없으면 null > 구분선 없이 맨 아래)
int? findUnreadCountOfRoom({required List<ChatRoomDetailDto> rooms, required String chatRoomId}) =>
    rooms.where((room) => room.chatRoomId == chatRoomId).firstOrNull?.unreadCount;

/// 안 읽은 첫 메시지 ID: 최신부터 상대 메시지 [unreadCount]번째 (내 메시지·로컬 메시지 제외)
/// 안 읽음 0 이하·회원 ID 없음·불러온 범위에 없음 > null
String? findFirstUnreadMessageId({
  required List<ChatMessage> messages,
  required String? myMemberId,
  required int unreadCount,
}) {
  if (unreadCount <= 0 || myMemberId == null) return null;
  var remainingUnreadCount = unreadCount;
  for (final message in messages) {
    final messageId = message.chatMessageId;
    if (messageId == null || isLocalOptimisticMessageId(messageId) || message.senderId == myMemberId) continue;
    remainingUnreadCount--;
    if (remainingUnreadCount == 0) return messageId;
  }
  return null;
}

/// 안 읽은 첫 메시지 찾으려 이전 페이지 더 불러올지 (못 찾음·남은 페이지 있음·한도 안)
bool shouldLoadOlderPageForUnread({
  required bool isFirstUnreadFound,
  required int unreadCount,
  required bool hasMoreOlderMessages,
  required int loadedOlderPageCount,
}) =>
    !isFirstUnreadFound &&
    unreadCount > 0 &&
    hasMoreOlderMessages &&
    loadedOlderPageCount < maximumUnreadSearchOlderPageCount;
