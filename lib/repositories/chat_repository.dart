// lib/repositories/chat_repository.dart
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';

class ChatRepository {
  final ChatApi _api;

  ChatRepository(this._api);

  /// 채팅방 목록 한 페이지 조회.
  /// [pageSize]는 기존 chat_tab_screen과 동일하게 10 고정.
  Future<PagedChatRoomDetail> getChatRooms({required int pageNumber, int pageSize = 10}) {
    return _api.getChatRooms(pageNumber: pageNumber, pageSize: pageSize);
  }
}
