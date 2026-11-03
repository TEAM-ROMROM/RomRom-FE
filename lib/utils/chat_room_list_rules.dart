// 채팅방 목록 판정 순수 함수
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';

/// 첫 페이지 재조회 결과 병합: 같은 방은 새 값으로 교체, 새 방 추가, 첫 페이지에 없는 기존 방(이후 페이지)은 유지
/// (정렬은 ChatRoomsState 생성자가 담당)
List<ChatRoomDetailDto> mergeFirstPageRooms({
  required List<ChatRoomDetailDto> currentRooms,
  required List<ChatRoomDetailDto> firstPageRooms,
}) {
  final firstPageRoomIds = {
    for (final room in firstPageRooms)
      if (room.chatRoomId != null) room.chatRoomId!,
  };
  final keptRooms = currentRooms.where((room) => !firstPageRoomIds.contains(room.chatRoomId));
  return [...firstPageRooms, ...keptRooms];
}
