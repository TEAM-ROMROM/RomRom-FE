// lib/models/apis/requests/chat_request.dart
import 'package:json_annotation/json_annotation.dart';

part 'chat_request.g.dart';

/// 채팅방 요청 DTO
@JsonSerializable()
class ChatRoomRequest {
  final String? opponentMemberId; // 상대방 회원 ID
  final String? chatRoomId; // 채팅방 ID
  final String? tradeRequestHistoryId; // 거래 요청 ID
  final int pageNumber; // 페이지 번호
  final int pageSize; // 페이지 크기

  ChatRoomRequest({
    this.opponentMemberId,
    this.chatRoomId,
    this.tradeRequestHistoryId,
    this.pageNumber = 0,
    this.pageSize = 20,
  });

  factory ChatRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomRequestToJson(this);
}
