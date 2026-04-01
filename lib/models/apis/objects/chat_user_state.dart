// lib/models/apis/objects/chat_user_state.dart
import 'package:json_annotation/json_annotation.dart';

part 'chat_user_state.g.dart';

/// 채팅방 사용자 상태 (백엔드 ChatUserState 엔티티)
@JsonSerializable(explicitToJson: true)
class ChatUserState {
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final String? chatUserStateId;
  final String? chatRoomId;
  final String? memberId;
  final DateTime? leftAt;
  final DateTime? removedAt;
  final bool deleted;
  final bool isPresent;

  ChatUserState({
    this.createdDate,
    this.updatedDate,
    this.chatUserStateId,
    this.chatRoomId,
    this.memberId,
    this.leftAt,
    this.removedAt,
    this.deleted = false,
    this.isPresent = false,
  });

  factory ChatUserState.fromJson(Map<String, dynamic> json) => _$ChatUserStateFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserStateToJson(this);
}
