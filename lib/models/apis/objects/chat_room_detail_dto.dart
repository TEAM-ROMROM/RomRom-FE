import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'chat_room_detail_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatRoomDetailDto {
  final String? chatRoomId;
  final Member? targetMember;
  final String? targetMemberEupMyeonDong;
  final String? lastMessageContent;
  @JsonKey(fromJson: _fromIsoString, toJson: _toIsoString)
  final DateTime? lastMessageTime;
  final int? unreadCount;
  final ChatRoomType? chatRoomType;
  final String? targetItemImageUrl;
  final String? myItemImageUrl;
  final bool? blocked;

  ChatRoomDetailDto({
    this.chatRoomId,
    this.targetMember,
    this.targetMemberEupMyeonDong,
    this.lastMessageContent,
    this.lastMessageTime,
    this.unreadCount,
    this.chatRoomType,
    this.targetItemImageUrl,
    this.myItemImageUrl,
    this.blocked,
  });

  factory ChatRoomDetailDto.fromJson(Map<String, dynamic> json) => _$ChatRoomDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomDetailDtoToJson(this);

  static DateTime? _fromIsoString(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String? _toIsoString(DateTime? dt) => dt?.toIso8601String();
}

/// ChatRoomDetailDto 복사 및 수정용 확장 메서드
extension ChatRoomDetailDtoCopy on ChatRoomDetailDto {
  ChatRoomDetailDto copyWith({
    String? chatRoomId,
    Member? targetMember,
    String? targetMemberEupMyeonDong,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    int? unreadCount,
    ChatRoomType? chatRoomType,
    String? targetItemImageUrl,
    String? myItemImageUrl,
    bool? blocked,
  }) => ChatRoomDetailDto(
    chatRoomId: chatRoomId ?? this.chatRoomId,
    targetMember: targetMember ?? this.targetMember,
    targetMemberEupMyeonDong: targetMemberEupMyeonDong ?? this.targetMemberEupMyeonDong,
    lastMessageContent: lastMessageContent ?? this.lastMessageContent,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    unreadCount: unreadCount ?? this.unreadCount,
    chatRoomType: chatRoomType ?? this.chatRoomType,
    targetItemImageUrl: targetItemImageUrl ?? this.targetItemImageUrl,
    myItemImageUrl: myItemImageUrl ?? this.myItemImageUrl,
    blocked: blocked ?? this.blocked,
  );
}
