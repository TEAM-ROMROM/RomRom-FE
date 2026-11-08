// lib/models/apis/objects/chat_message.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/chat_appointment.dart';

part 'chat_message.g.dart';

/// 채팅 메시지 모델 (MongoDB)
@JsonSerializable(explicitToJson: true)
class ChatMessage extends BaseEntity {
  final String? chatMessageId;
  final String? chatRoomId;
  final String? senderId;
  final String? recipientId;
  final String? content;
  final List<String>? imageUrls;
  final MessageType? type;
  final bool? isProfanityDetected;
  final double? latitude;
  final double? longitude;
  // 보낸 사람이 삭제한 메시지 (서버가 본문을 안내 문구로 바꿔 내려줌)
  final bool? isDeleted;
  // 약속 카드 정보 (약속 메시지만, 그 외 null)
  final ChatAppointment? appointment;

  ChatMessage({
    super.createdDate,
    super.updatedDate,
    this.chatMessageId,
    this.chatRoomId,
    this.senderId,
    this.recipientId,
    this.content,
    this.imageUrls,
    this.type,
    this.isProfanityDetected,
    this.latitude,
    this.longitude,
    this.isDeleted,
    this.appointment,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

/// ChatMessage 복사 및 수정용 확장 메서드
extension ChatMessageCopy on ChatMessage {
  ChatMessage copyWith({
    String? chatMessageId,
    String? chatRoomId,
    String? senderId,
    String? recipientId,
    String? content,
    List<String>? imageUrls,
    MessageType? type,
    bool? isProfanityDetected,
    DateTime? createdDate,
    DateTime? updatedDate,
    double? latitude,
    double? longitude,
    bool? isDeleted,
    ChatAppointment? appointment,
  }) => ChatMessage(
    chatMessageId: chatMessageId ?? this.chatMessageId,
    chatRoomId: chatRoomId ?? this.chatRoomId,
    senderId: senderId ?? this.senderId,
    recipientId: recipientId ?? this.recipientId,
    content: content ?? this.content,
    imageUrls: imageUrls ?? this.imageUrls,
    type: type ?? this.type,
    isProfanityDetected: isProfanityDetected ?? this.isProfanityDetected,
    createdDate: createdDate ?? this.createdDate,
    updatedDate: updatedDate ?? this.updatedDate,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isDeleted: isDeleted ?? this.isDeleted,
    appointment: appointment ?? this.appointment,
  );
}
