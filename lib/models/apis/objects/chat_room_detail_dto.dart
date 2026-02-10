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
