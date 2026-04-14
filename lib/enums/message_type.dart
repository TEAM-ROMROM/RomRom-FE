import 'package:json_annotation/json_annotation.dart';

/// 채팅 메시지 타입 (백엔드 MessageType Enum)
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('SYSTEM')
  system,
  @JsonValue('LOCATION')
  location,
  @JsonValue('TRADE_COMPLETE_REQUEST')
  tradeCompleteRequest,
  @JsonValue('TRADE_COMPLETE_REQUEST_CANCELED')
  tradeCompleteRequestCanceled,
  @JsonValue('TRADE_COMPLETE_REQUEST_REJECTED')
  tradeCompleteRequestRejected,
  @JsonValue('TRADE_COMPLETED')
  tradeCompleted,
}
