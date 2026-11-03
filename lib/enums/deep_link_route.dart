/// 딥링크 이동 대상
enum DeepLinkRoute {
  itemDetail, // romrom://item/detail?itemId=
  chatRoom, // romrom://chat/room?chatRoomId=
  itemDeleted, // romrom://item/deleted (표시값은 extraData)
  sharedItem, // https://{공유 도메인}/item?itemId=
  notificationFallback, // 모르는 romrom 경로·필수 id 없음 > 알림함
  ignored, // 다른 도메인·스킴 > 이동 없음
}
