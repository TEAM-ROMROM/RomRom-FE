/// 물품 목록 정렬 기준 enum (프론트 ↔︎ 백엔드 매핑)
///
/// label      : 클라이언트 표시용 한글 이름
/// serverName : 백엔드 enum 이름
///
/// 백엔드 enum 참고:
/// CREATED_DATE (최신순), DISTANCE (거리순),
/// PREFERRED_CATEGORY (선호 카테고리순), RECOMMENDED (추천순)
///
/// 사용 예시
///   final serverValue = selectedSortField.serverName; // API 전송용
enum ItemSortField {
  createdDate(label: '최신순', serverName: 'CREATED_DATE'),
  distance(label: '거리순', serverName: 'DISTANCE'),
  preferredCategory(label: '선호 카테고리순', serverName: 'PREFERRED_CATEGORY'),
  recommended(label: '추천순', serverName: 'RECOMMENDED');

  final String label;
  final String serverName;

  const ItemSortField({required this.label, required this.serverName});

  /// serverName으로부터 ItemSortField를 찾는 헬퍼 메서드
  static ItemSortField? fromServerName(String serverName) {
    try {
      return ItemSortField.values.firstWhere((e) => e.serverName == serverName);
    } catch (e) {
      return null;
    }
  }
}
