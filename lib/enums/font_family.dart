/// 폰트 이름 저장
enum FontFamily {
  pretendard(fontName: 'Pretendard'),
  nexonLv2Gothic(fontName: 'NEXON-Lv2-Gothic');

  final String fontName;

  const FontFamily({required this.fontName});
}
