// lib/models/apis/objects/chat_room.dart
import 'package:flutter/material.dart';
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
    if (opponent.accountStatus == 'DELETE_ACCOUNT') return '(탈퇴)';
    return opponent.nickname ?? '알 수 없음';
  }

  /// UI 헬퍼: 상대방 프로필 이미지 URL
  String? getOpponentProfileUrl(String myMemberId) {
    final opponent = getOpponent(myMemberId);
    return opponent?.profileUrl;
  }

  /// UI 헬퍼: 상대방 위치 정보
  String getOpponentLocation(String myMemberId) {
    // FIXME: 백엔드 수정 대기 - MemberLocation 정보 없음
    // 임시: 하드코딩 또는 "위치 정보 없음" 반환
    final opponent = getOpponent(myMemberId);

    // 임시 더미 데이터 (개발용)
    final dummyLocations = {
      // memberId: location
      // 실제 테스트 시 백엔드에서 받은 memberId로 매핑
    };

    return dummyLocations[opponent?.memberId] ?? '위치 정보 없음';
  }

  /// UI 헬퍼: 메시지 미리보기 (최근 메시지)
  String getMessagePreview() {
    // FIXME: 백엔드 수정 대기 - 최근 메시지 정보 없음
    // 임시: 거래 상품명 기반 문구 생성
    final itemName = tradeRequestHistory?.takeItem.itemName ?? '상품';
    return '$itemName 거래에 대해 대화해보세요';
  }

  /// UI 헬퍼: 마지막 활동 시간
  DateTime getLastActivityTime(Member member) {
    DateTime? opponentLastActivityTime = member.lastActiveAt;
    debugPrint('⏰ ${member.nickname} : ${opponentLastActivityTime ?? DateTime.now()}');
    return opponentLastActivityTime ?? updatedDate ?? DateTime.now();
  }

  /// UI 헬퍼: 활동 중인지 상태 반환
  bool getOnlineStatus(Member member) {
    bool? onlineStatus = member.online;
    debugPrint('📳 ${member.nickname} : $onlineStatus');
    return onlineStatus ?? false;
  }

  /// UI 헬퍼: 읽지 않은 메시지 수
  int getUnreadCount() {
    // FIXME: 백엔드 수정 대기 - 읽음 처리 로직 없음
    // 임시: 항상 0 반환
    return 0;
  }

  /// UI 헬퍼: 신규 여부
  bool isNewChat() {
    return tradeRequestHistory?.isNew ?? false;
  }

  /// 엔티티 메서드 대응: 주어진 memberId가 이 채팅방의 참여자인지 검사
  /// (Java 엔티티의 isMember(UUID) 대응)
  bool isMember(String memberId) {
    return tradeReceiver?.memberId == memberId || tradeSender?.memberId == memberId;
  }
}
