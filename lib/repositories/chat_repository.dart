// lib/repositories/chat_repository.dart
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';

/// 채팅 API 래핑: 방 목록·생성·삭제, 메시지·읽음 커서, 거래 완료 요청 흐름, 방별 알림·메시지 삭제·약속 (UI 모름)
class ChatRepository {
  final ChatApi _api;

  ChatRepository(this._api);

  /// 채팅방 목록 한 페이지 조회.
  /// [pageSize]는 기존 chat_tab_screen과 동일하게 10 고정.
  Future<PagedChatRoomDetail> getChatRooms({required int pageNumber, int pageSize = 10}) {
    return _api.getChatRooms(pageNumber: pageNumber, pageSize: pageSize);
  }

  /// 물품별 채팅방 목록 조회 (교환 상대 선택용, 기본 50건)
  Future<PagedChatRoomDetail> getChatRoomsByItemId({required String itemId, int pageSize = 50}) {
    return _api.getChatRoomsByItemId(itemId: itemId, pageSize: pageSize);
  }

  /// 채팅방 생성 (이미 있으면 기존 방 반환)
  Future<ChatRoom> createChatRoom({required String opponentMemberId, required String tradeRequestHistoryId}) {
    return _api.createChatRoom(opponentMemberId: opponentMemberId, tradeRequestHistoryId: tradeRequestHistoryId);
  }

  /// 채팅방 삭제(나가기)
  Future<void> deleteChatRoom({required String chatRoomId}) => _api.deleteChatRoom(chatRoomId: chatRoomId);

  /// 메시지 한 페이지 조회 (채팅방 정보 포함)
  Future<ChatRoomResponse> getChatMessages({required String chatRoomId, int pageNumber = 0, int pageSize = 30}) {
    return _api.getChatMessages(chatRoomId: chatRoomId, pageNumber: pageNumber, pageSize: pageSize);
  }

  /// 읽음 커서 갱신 (isEntered: true 입장, false 퇴장)
  Future<void> updateChatRoomReadCursor({required String chatRoomId, required bool isEntered}) {
    return _api.updateChatRoomReadCursor(chatRoomId: chatRoomId, isEntered: isEntered);
  }

  /// 상대방 읽음 상태 조회
  Future<ChatUserState?> getChatRoomReadStatus({required String chatRoomId}) {
    return _api.getChatRoomReadStatus(chatRoomId: chatRoomId);
  }

  /// 거래 완료 요청
  Future<void> requestTradeCompletion({required String chatRoomId}) {
    return _api.requestTradeCompletion(chatRoomId: chatRoomId);
  }

  /// 거래 완료 요청 취소 (요청자)
  Future<void> cancelTradeCompletionRequest({required String chatRoomId}) {
    return _api.cancelTradeCompletionRequest(chatRoomId: chatRoomId);
  }

  /// 거래 완료 요청 거절 (수신자)
  Future<void> rejectTradeCompletion({required String chatRoomId}) {
    return _api.rejectTradeCompletion(chatRoomId: chatRoomId);
  }

  /// 거래 완료 확정 (수신자)
  Future<void> confirmTradeCompletion({required String chatRoomId}) {
    return _api.confirmTradeCompletion(chatRoomId: chatRoomId);
  }

  /// 방별 알림 끄기·켜기 > 서버 확정 값
  Future<bool> updateNotificationMute({required String chatRoomId, required bool isNotificationMuted}) {
    return _api.updateNotificationMute(chatRoomId: chatRoomId, isNotificationMuted: isNotificationMuted);
  }

  /// 내 메시지 삭제 > 삭제 반영본 (응답에 없으면 null)
  Future<ChatMessage?> deleteMessage({required String chatRoomId, required String chatMessageId}) {
    return _api.deleteMessage(chatRoomId: chatRoomId, chatMessageId: chatMessageId);
  }

  /// 약속 제안 > 생성된 약속 메시지
  Future<ChatMessage?> proposeAppointment({
    required String chatRoomId,
    required DateTime appointmentAt,
    required String placeName,
    double? latitude,
    double? longitude,
  }) {
    return _api.proposeAppointment(
      chatRoomId: chatRoomId,
      appointmentAt: appointmentAt,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// 약속 수락 > 상태 반영본
  Future<ChatMessage?> acceptAppointment({required String chatRoomId, required String chatMessageId}) {
    return _api.acceptAppointment(chatRoomId: chatRoomId, chatMessageId: chatMessageId);
  }

  /// 약속 취소 > 상태 반영본
  Future<ChatMessage?> cancelAppointment({required String chatRoomId, required String chatMessageId}) {
    return _api.cancelAppointment(chatRoomId: chatRoomId, chatMessageId: chatMessageId);
  }
}
