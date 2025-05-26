/// 가격 관련 태그
enum PriceTag {
  aiAnalyzed(name: 'AI 분석 적정가'),
  userInput(name: '직접 입력');

  final String name;

  const PriceTag({required this.name});
}
