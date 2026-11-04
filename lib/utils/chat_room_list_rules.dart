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

/// 목록 상태에 있는데 아직 소켓 구독 안 한 방 ID (상태 변경마다 차이만 구독, 목록에서 빠진 방 구독은 유지 > 새 메시지로 목록 복귀)
Set<String> findChatRoomIdsToSubscribe({
  required List<ChatRoomDetailDto> rooms,
  required Set<String> subscribedChatRoomIds,
}) => {
  for (final room in rooms)
    if (room.chatRoomId != null && !subscribedChatRoomIds.contains(room.chatRoomId)) room.chatRoomId!,
};
