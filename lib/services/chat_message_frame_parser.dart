import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 채팅방 STOMP 프레임 수신 로그 > 메시지 변환 (본문 없음·파싱 실패 > 로그 후 null)
ChatMessage? decodeChatRoomMessageFrame(StompFrame frame, {required String destination}) {
  debugPrint('[WebSocket] 📨 Frame 수신 from $destination');
  if (kDebugMode) {
    debugPrint('[WebSocket]   headers(keys): ${frame.headers.keys.toList()}');
    debugPrint('[WebSocket]   bodyLength: ${frame.body?.length ?? 0}');
  }

  if (frame.body == null) {
    debugPrint('[WebSocket]   ⚠️ body가 null → 무시');
    return null;
  }

  try {
    final message = parseChatRoomMessageFrame(frame);
    if (kDebugMode) {
      debugPrint('[WebSocket]   → 파싱 완료: type=${message.type}, hasId=${message.chatMessageId != null}');
    }
    return message;
  } catch (e, st) {
    debugPrint('[WebSocket]   ❌ 파싱 실패: $e');
    if (kDebugMode) {
      debugPrint('[WebSocket]   rawBodyLength: ${frame.body?.length ?? 0}');
      debugPrint('[WebSocket]   $st');
    }
    return null;
  }
}

/// 채팅방 STOMP 프레임 > 메시지: 본문 JSON > 시각 확정 (헤더 timestamp > 페이로드 createdDate·clientSentAt)
/// 본문 없음·JSON 오류 > 예외
@visibleForTesting
ChatMessage parseChatRoomMessageFrame(StompFrame frame) {
  final jsonBody = jsonDecode(frame.body!);
  debugPrint('[WebSocket]   type 필드: ${jsonBody["type"]}');

  // 1) STOMP 헤더 timestamp(ms) → DateTime
  DateTime? headerTs;
  final tsHdr = frame.headers['timestamp'];
  if (tsHdr != null) {
    final ms = int.tryParse(tsHdr);
    if (ms != null) {
      headerTs = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
  }

  // 2) 페이로드 시간 파싱(createdDate/clientSentAt)
  DateTime? payloadTs;
  final createdDate = jsonBody['createdDate'];
  if (createdDate is int) {
    payloadTs = DateTime.fromMillisecondsSinceEpoch(createdDate, isUtc: true).toLocal();
  } else if (createdDate is String) {
    final parsed = DateTime.tryParse(createdDate);
    if (parsed != null) payloadTs = parsed.toLocal();
  } else if (jsonBody['clientSentAt'] is int) {
    payloadTs = DateTime.fromMillisecondsSinceEpoch(jsonBody['clientSentAt'], isUtc: true).toLocal();
  }

  // 3) 최종 시간 확정: 헤더 → 페이로드 (둘 다 없으면 null 유지)
  // DateTime.now() 폴백을 쓰면 지연 수신 메시지가 '수신 시각'으로 밀려 표시되므로 제거.
  // 시각 출처가 없으면 null로 두고, 재연결 동기화 시 서버 createdDate로 교정된다.
  final finalCreated = headerTs ?? payloadTs;

  // 모델로 변환
  return ChatMessage.fromJson(jsonBody).copyWith(createdDate: finalCreated);
}
