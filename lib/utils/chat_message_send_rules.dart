// 낙관적 전송 메시지 판정 순수 함수: 서버 에코 짝짓기, 재조회 확정, 텍스트 전송 잠금, 에코 처리 결정
// 시각 기준: 로컬 메시지 createdDate = 내 기기 전송 시각 <-> 에코 수신 시각 (서버 시계·시간대 무관)
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';

// 전송 후 에코를 짝지을 최대 대기 시간 (실패 표시 10초 이후 늦은 에코까지 흡수)
const Duration pendingLocalMessageEchoWindow = Duration(minutes: 1);

// 위치 좌표 동일 판정 허용 오차 (도, 직렬화 반올림 대비)
const double _coordinateTolerance = 0.000001;

/// 내 에코와 짝인 낙관적 로컬 메시지 ID (없으면 null)
/// 규칙: 값 일치(텍스트 내용·사진 주소 집합·위경도) 우선 > 사진·위치 값 비교 불가면 같은 종류 중 가장 오래된 것
/// [receivedAt] null이면 시간 제한 없음 (재조회 확정용)
String? findMatchingPendingLocalMessageId({
  required Map<String, ChatMessage> pendingLocalMessages,
  required ChatMessage incomingMessage,
  required String? myMemberId,
  required DateTime? receivedAt,
}) {
  if (incomingMessage.senderId != myMemberId) return null;
  String? sameTypeFallbackId;
  // Map 삽입 순서 = 전송 순서 > 오래된 것부터
  for (final entry in pendingLocalMessages.entries) {
    final localMessage = entry.value;
    if (localMessage.senderId != myMemberId) continue;
    if (!_isWithinEchoWindow(sentAt: localMessage.createdDate, receivedAt: receivedAt)) continue;
    final isSamePayload = _isSamePayload(localMessage, incomingMessage);
    if (isSamePayload == true) return entry.key;
    if (isSamePayload == null) sameTypeFallbackId ??= entry.key;
  }
  return sameTypeFallbackId;
}

/// 재조회 서버 목록에 이미 저장된 내 낙관적 로컬 메시지 ID
/// 이미 화면에 확정·표시된 서버 메시지 제외, 서버 메시지 1건당 로컬 1건, 오래된 서버 메시지부터
Set<String> findPendingLocalIdsConfirmedByServer({
  required Map<String, ChatMessage> pendingLocalMessages,
  required List<ChatMessage> serverMessages,
  required String? myMemberId,
  required Set<String> displayedMessageIds,
}) {
  final unmatchedLocalMessages = Map<String, ChatMessage>.of(pendingLocalMessages);
  final confirmedLocalIds = <String>{};
  // 서버 목록은 최신 먼저 > 뒤집어 전송 순서와 맞춤
  for (final serverMessage in serverMessages.reversed) {
    if (displayedMessageIds.contains(serverMessage.chatMessageId)) continue;
    final matchedLocalId = findMatchingPendingLocalMessageId(
      pendingLocalMessages: unmatchedLocalMessages,
      incomingMessage: serverMessage,
      myMemberId: myMemberId,
      receivedAt: null,
    );
    if (matchedLocalId == null) continue;
    unmatchedLocalMessages.remove(matchedLocalId);
    confirmedLocalIds.add(matchedLocalId);
  }
  return confirmedLocalIds;
}

/// 텍스트 전송 잠금 여부: 실패 아닌 대기 텍스트가 남았는지 (사진·위치·실패 텍스트는 잠그지 않음)
bool hasPendingTextAwaitingEcho({
  required Map<String, ChatMessage> pendingLocalMessages,
  required Set<String> failedLocalMessageIds,
}) {
  return pendingLocalMessages.entries.any(
    (entry) => entry.value.type == MessageType.text && !failedLocalMessageIds.contains(entry.key),
  );
}

/// 내 에코 처리 결정: 대기 로컬 확정 > 다시 보내기로 대체된 원래 메시지의 늦은 에코 흡수(표시 안 함) > 새 메시지(둘 다 null)
({String? confirmedLocalId, String? absorbedSupersededLocalId}) resolveIncomingEcho({
  required Map<String, ChatMessage> pendingLocalMessages,
  required Map<String, ChatMessage> supersededLocalMessages,
  required ChatMessage incomingMessage,
  required String? myMemberId,
  required DateTime receivedAt,
}) {
  final confirmedLocalId = findMatchingPendingLocalMessageId(
    pendingLocalMessages: pendingLocalMessages,
    incomingMessage: incomingMessage,
    myMemberId: myMemberId,
    receivedAt: receivedAt,
  );
  if (confirmedLocalId != null) return (confirmedLocalId: confirmedLocalId, absorbedSupersededLocalId: null);
  final absorbedSupersededLocalId = findMatchingPendingLocalMessageId(
    pendingLocalMessages: supersededLocalMessages,
    incomingMessage: incomingMessage,
    myMemberId: myMemberId,
    receivedAt: receivedAt,
  );
  return (confirmedLocalId: null, absorbedSupersededLocalId: absorbedSupersededLocalId);
}

/// 전송 시각 이후 대기 한도 안에 받았는지 (전송 시각·수신 시각 없으면 통과)
bool _isWithinEchoWindow({required DateTime? sentAt, required DateTime? receivedAt}) {
  if (sentAt == null || receivedAt == null) return true;
  return receivedAt.difference(sentAt).abs() <= pendingLocalMessageEchoWindow;
}

/// 로컬 <-> 에코 내용 일치 여부 (true 일치, false 불일치, null 사진·위치 값 없어 비교 불가)
bool? _isSamePayload(ChatMessage localMessage, ChatMessage incomingMessage) {
  final localType = localMessage.type;
  final incomingType = incomingMessage.type;
  if (localType != null && incomingType != null && localType != incomingType) return false;
  switch (localType) {
    case MessageType.image:
      final localUrls = localMessage.imageUrls ?? const <String>[];
      final incomingUrls = incomingMessage.imageUrls ?? const <String>[];
      if (localUrls.isEmpty || incomingUrls.isEmpty) return null;
      return setEquals(localUrls.toSet(), incomingUrls.toSet());
    case MessageType.location:
      final localLatitude = localMessage.latitude;
      final localLongitude = localMessage.longitude;
      final incomingLatitude = incomingMessage.latitude;
      final incomingLongitude = incomingMessage.longitude;
      if (localLatitude == null || localLongitude == null || incomingLatitude == null || incomingLongitude == null) {
        return null;
      }
      return (localLatitude - incomingLatitude).abs() <= _coordinateTolerance &&
          (localLongitude - incomingLongitude).abs() <= _coordinateTolerance;
    default:
      return (localMessage.content ?? '') == (incomingMessage.content ?? '');
  }
}
