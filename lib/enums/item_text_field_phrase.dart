/// 물건 등록 시 사용되는 텍스트 필드의 제목, 힌트 텍스트, 에러 메시지를 정의하는 enum
enum ItemTextFieldPhrase {
  title(label: '제목', hintText: '제목을 입력하세요', errorText: '제목을 입력해주세요'),
  category(label: '카테고리', hintText: '카테고리를 선택하세요', errorText: '카테고리를 선택해주세요'),
  discription(
      label: '물건 설명', hintText: '물건의 자세한 설명을 적어주세요', errorText: '설명을 적어주세요'),
  condition(label: '물건 상태', hintText: '', errorText: '물건 상태를 선택해주세요'),
  tradeOption(label: '거래 방식', hintText: '중복선택 가능', errorText: '거래방식을 선택해주세요'),
  price(
      label: '적정 가격',
      hintText: 'AI가 측정한 추천 가격이에요. 상황에 맞춰 조정해 최종 거래가는 직접 결정해 주세요',
      errorText: '가격을 입력해주세요'),
  location(
      label: '거래 희망 위치',
      hintText: '거래 희망 위치를 선택하세요',
      errorText: '거래 희망 위치를 입력해주세요');

  final String label;
  final String hintText;
  final String errorText;

  const ItemTextFieldPhrase({
    required this.label,
    required this.hintText,
    required this.errorText,
  });

  /// headingTitle 으로부터 enum 값으로 변환
  static ItemTextFieldPhrase returnEnumByHeadingtitle(String label) {
    return ItemTextFieldPhrase.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw ArgumentError('Invalid title: $label'),
    );
  }
}
