/// 내 물건 탭 토글 상태 enum (빈 목록 문구 포함: 등록 탭·나의 등록된 물품 공용)
enum MyItemToggleStatus {
  all(
    id: 0,
    label: '전체',
    serverName: '',
    emptyItemsTitle: '등록된 물품이 없어요',
    emptyItemsDescription: '물품을 등록하고\n교환을 시작해 보세요',
  ),
  selling(
    id: 1,
    label: '등록 물품',
    serverName: 'AVAILABLE',
    emptyItemsTitle: '교환 가능한 물품이 없어요',
    emptyItemsDescription: '물품을 등록하고\n교환을 시작해 보세요',
  ),
  completed(
    id: 2,
    label: '교환 완료',
    serverName: 'EXCHANGED',
    emptyItemsTitle: '교환 완료된 물품이 없어요',
    emptyItemsDescription: '교환을 마친 물품을\n여기에서 모아 볼 수 있어요',
  );

  final int id;
  final String label;
  final String serverName;
  // 빈 목록 중앙 문구·설명
  final String emptyItemsTitle;
  final String emptyItemsDescription;

  const MyItemToggleStatus({
    required this.id,
    required this.label,
    required this.serverName,
    required this.emptyItemsTitle,
    required this.emptyItemsDescription,
  });

  /// 서버 이름 > 내 물건 토글 상태 (모르는 값·null > null)
  static MyItemToggleStatus? fromServerName(String? serverName) {
    return MyItemToggleStatus.values.where((s) => s.serverName == serverName).firstOrNull;
  }
}
