import 'package:json_annotation/json_annotation.dart';

/// 채팅 메시지 타입 (백엔드 MessageType Enum)
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('SYSTEM')
  system,
}
