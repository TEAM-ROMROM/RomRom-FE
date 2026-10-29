// lib/utils/chat_room_message_rules.dart
// 채팅방 메시지 목록 판정 순수 함수 (목록은 reverse 정렬: index 0 = 최신)
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';

// 서버 에코 <-> 낙관적 로컬 메시지 매칭 허용 시각 차 (초)
const int pendingLocalMessageMatchToleranceSeconds = 10;

/// 재연결 동기화용 메시지 병합 (순수 함수, 테스트 대상).
///
/// [current]는 화면의 현재 목록(reverse 정렬: index 0 = 최신).
/// [serverMessages]는 getChatMessages 재조회 결과.
///
/// 규칙:
/// - 서버 메시지 중 [current]에 chatMessageId가 없는 것만 추가
/// - 이미 있으면 서버 버전으로 교체 (시각 등 교정)
/// - 낙관적 로컬 메시지(id가 'local_'/'uploading_'/'ws_img_'/'local_trade_request_' 접두)는 서버에 없어도 보존
/// - 결과는 createdDate 내림차순(최신 먼저), null은 맨 뒤
List<ChatMessage> mergeServerMessages({required List<ChatMessage> current, required List<ChatMessage> serverMessages}) {
  bool isLocalOptimistic(String? id) =>
      id != null &&
      (id.startsWith('local_') ||
          id.startsWith('uploading_') ||
          id.startsWith('ws_img_') ||
          id.startsWith('local_trade_request_'));

  final serverById = <String, ChatMessage>{
    for (final m in serverMessages)
      if (m.chatMessageId != null) m.chatMessageId!: m,
  };

  final merged = <ChatMessage>[];

  // 1) 현재 목록 순회: 서버에 있으면 서버 버전으로 교체, 낙관적 로컬은 보존, 그 외 유지
  final keptIds = <String>{};
  for (final m in current) {
    final id = m.chatMessageId;
    if (id != null && serverById.containsKey(id)) {
      merged.add(serverById[id]!);
      keptIds.add(id);
    } else if (isLocalOptimistic(id)) {
      merged.add(m);
    } else if (id != null) {
      merged.add(m);
      keptIds.add(id);
    } else {
      merged.add(m);
    }
  }

  // 2) 서버 메시지 중 아직 추가되지 않은 것 추가
  for (final m in serverMessages) {
    final id = m.chatMessageId;
    if (id != null && !keptIds.contains(id)) {
      merged.add(m);
      keptIds.add(id);
    }
  }

  // 3) createdDate 내림차순 정렬, null은 맨 뒤
  merged.sort((a, b) {
    final da = a.createdDate;
    final db = b.createdDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });

  return merged;
}

/// [index]의 교환 완료 요청 활성 여부 (더 최신 메시지에 취소·거절·완료 없으면 활성, 거래 완료 방은 항상 비활성)
bool isActiveTradeRequestAt({required List<ChatMessage> messages, required int index, required bool isTradeCompleted}) {
  if (isTradeCompleted) return false;
  for (int newerIndex = 0; newerIndex < index; newerIndex++) {
    final newerType = messages[newerIndex].type;
    if (newerType == MessageType.tradeCompleteRequestCanceled ||
        newerType == MessageType.tradeCompleteRequestRejected ||
        newerType == MessageType.tradeCompleted) {
      return false;
    }
  }
  return true;
}

/// 가장 최근 교환 완료 요청이 아직 활성인지 여부
bool hasActiveTradeRequest({required List<ChatMessage> messages, required bool isTradeCompleted}) {
  final latestRequestIndex = messages.indexWhere((m) => m.type == MessageType.tradeCompleteRequest);
  return latestRequestIndex != -1 &&
      isActiveTradeRequestAt(messages: messages, index: latestRequestIndex, isTradeCompleted: isTradeCompleted);
}

/// 상대방이 읽은 내 메시지 중 가장 최근 메시지 ID (읽음 상태 없으면 null)
/// 판정 2개: 상대 재실(isPresent) > 최신 내 메시지, 퇴장 > 퇴장 시각 이전에 보낸 최신 내 메시지
String? findLastReadMyMessageId({
  required List<ChatMessage> messages,
  required String? myMemberId,
  required ChatUserState? opponentState,
}) {
  if (opponentState == null || myMemberId == null) return null;
  for (final message in messages) {
    if (message.senderId != myMemberId) continue;
    if (message.chatMessageId == null) continue;
    // WS 실시간 이벤트로 isPresent가 즉시 갱신되므로 그대로 신뢰
    // 잠금/백그라운드는 lifecycle observer가 isPresent=false로 갱신
    if (opponentState.isPresent) return message.chatMessageId;
    final sentAt = message.createdDate;
    final leftAt = opponentState.leftAt;
    if (sentAt != null && leftAt != null && !sentAt.isAfter(leftAt)) return message.chatMessageId;
  }
  return null;
}

/// [index] 메시지가 바로 이전(더 오래된) 메시지와 같은 발신자·같은 종류인지 (true면 좁은 간격)
bool isGroupedWithOlderMessage({required List<ChatMessage> messages, required int index}) {
  return index < messages.length - 1 &&
      messages[index].senderId == messages[index + 1].senderId &&
      messages[index].type == messages[index + 1].type;
}

/// [index] 메시지 시각 표시 여부 (최신 메시지, 또는 다음 메시지와 발신자·분 단위 시각이 다를 때)
bool shouldShowMessageTime({required List<ChatMessage> messages, required int index}) {
  return (index == 0) ||
      (index > 0 &&
          (messages[index].senderId != messages[index - 1].senderId ||
              !isSameMinute(messages[index].createdDate, messages[index - 1].createdDate)));
}

/// 내 서버 에코와 짝인 낙관적 로컬 메시지 ID 찾기 (내용 동일 + 시각 차 10초 이내, 없으면 null)
String? findMatchingPendingLocalMessageId({
  required Map<String, ChatMessage> pendingLocalMessages,
  required ChatMessage incomingMessage,
  required String? myMemberId,
}) {
  if (incomingMessage.senderId != myMemberId) return null;
  for (final entry in pendingLocalMessages.entries) {
    final localMessage = entry.value;
    if (localMessage.senderId != myMemberId) continue;
    if ((localMessage.content ?? '') != (incomingMessage.content ?? '')) continue;
    final localSentAt = localMessage.createdDate ?? DateTime.now();
    final serverSentAt = incomingMessage.createdDate ?? DateTime.now();
    if (serverSentAt.difference(localSentAt).inSeconds.abs() <= pendingLocalMessageMatchToleranceSeconds) {
      return entry.key;
    }
  }
  return null;
}

/// 서버 에코 + 낙관적 로컬 메시지 > 확정 메시지 (서버 값 우선, 빈 내용·빈 이미지는 로컬 값 유지)
ChatMessage mergeServerEchoIntoLocalMessage({required ChatMessage localMessage, required ChatMessage serverMessage}) {
  return ChatMessage(
    chatRoomId: serverMessage.chatRoomId ?? localMessage.chatRoomId,
    chatMessageId: serverMessage.chatMessageId,
    senderId: serverMessage.senderId ?? localMessage.senderId,
    content: (serverMessage.content != null && serverMessage.content!.trim().isNotEmpty)
        ? serverMessage.content
        : localMessage.content,
    createdDate: serverMessage.createdDate ?? localMessage.createdDate,
    type: serverMessage.type ?? localMessage.type,
    imageUrls: (serverMessage.imageUrls != null && serverMessage.imageUrls!.isNotEmpty)
        ? serverMessage.imageUrls
        : localMessage.imageUrls,
    isProfanityDetected: serverMessage.isProfanityDetected,
  );
}

/// 이미지 주소 없는 WS 임시 메시지 > 서버 이미지 메시지 교체 목록 (발신자별 순서대로 짝지음)
/// 결과: (임시 ID, 목록 index, 교체할 서버 메시지)
List<(String placeholderId, int index, ChatMessage replacement)> matchWebSocketImagePlaceholders({
  required List<ChatMessage> messages,
  required Set<String> placeholderIds,
  required List<ChatMessage> serverMessages,
}) {
  // 발신자별 서버 이미지 메시지 (이미지 주소 있는 것만)
  final serverImagesBySender = <String, List<ChatMessage>>{};
  for (final message in serverMessages) {
    if (message.type != MessageType.image || message.imageUrls == null || message.imageUrls!.isEmpty) continue;
    serverImagesBySender.putIfAbsent(message.senderId ?? '', () => []).add(message);
  }

  // 발신자별 임시 메시지 위치
  final placeholdersBySender = <String, List<(String, int)>>{};
  for (int index = 0; index < messages.length; index++) {
    final id = messages[index].chatMessageId;
    if (id != null && placeholderIds.contains(id)) {
      placeholdersBySender.putIfAbsent(messages[index].senderId ?? '', () => []).add((id, index));
    }
  }

  // 같은 발신자 안에서 순서대로 짝지음 (개수 적은 쪽까지)
  final replacements = <(String, int, ChatMessage)>[];
  for (final entry in placeholdersBySender.entries) {
    final placeholders = entry.value;
    final serverImages = serverImagesBySender[entry.key] ?? [];
    for (int order = 0; order < placeholders.length && order < serverImages.length; order++) {
      final (placeholderId, index) = placeholders[order];
      replacements.add((placeholderId, index, serverImages[order]));
    }
  }
  return replacements;
}
