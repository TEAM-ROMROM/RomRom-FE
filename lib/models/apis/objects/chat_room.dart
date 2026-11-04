// lib/models/apis/objects/chat_room.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

part 'chat_room.g.dart';

/// 채팅방 모델 (백엔드 ChatRoom 엔티티)
@JsonSerializable(explicitToJson: true)
class ChatRoom extends BaseEntity {
  final String? chatRoomId;
  final Member? tradeReceiver; // 거래 요청 받은 사람
  final Member? tradeSender; // 거래 요청 보낸 사람
  final TradeRequestHistory? tradeRequestHistory;

  ChatRoom({
    super.createdDate,
    super.updatedDate,
    this.chatRoomId,
    this.tradeReceiver,
    this.tradeSender,
    this.tradeRequestHistory,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);

  /// UI 헬퍼: 상대방 Member 객체 반환
  Member? getOpponent(String myMemberId) {
    if (tradeReceiver?.memberId == myMemberId) {
      return tradeSender;
    } else {
      return tradeReceiver;
    }
  }

  /// UI 헬퍼: 상대방 닉네임
  String getOpponentNickname(String myMemberId) {
    final opponent = getOpponent(myMemberId);
    if (opponent == null) return '(탈퇴)';
    if (opponent.accountStatus == 'DELETE_ACCOUNT') return '(탈퇴) ${opponent.nickname}';
    return opponent.nickname ?? '알 수 없음';
  }
}
