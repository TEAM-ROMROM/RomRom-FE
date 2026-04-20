/// 게시글 삭제 제재 알림 예외
/// api_client.dart에서 ITEM_DELETED_NOTICE 에러코드 감지 시 발생
class ItemDeletedException implements Exception {
  final String itemTitle;
  final String deleteReason;

  ItemDeletedException({required this.itemTitle, required this.deleteReason});

  @override
  String toString() => 'ItemDeletedException: title=$itemTitle, reason=$deleteReason';
}
