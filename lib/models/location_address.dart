/// 행정구역 주소: 시도·시군구·읍면동·리 + 좌표
class LocationAddress {
  final String siDo;
  final String siGunGu;
  final String eupMyoenDong;
  final String? ri;
  final String currentAddress;
  final double? latitude;
  final double? longitude;

  LocationAddress({
    required this.siDo,
    required this.siGunGu,
    required this.eupMyoenDong,
    this.ri,
    String? currentAddress,
    this.latitude,
    this.longitude,
  }) : currentAddress = currentAddress ?? eupMyoenDong;

  /// '시도 시군구 읍면동' 표시 문자열 (공백 1칸 구분, 리 제외, 앞뒤 공백 정리 없음 — 필요한 호출부만 trim)
  String get siDoSiGunGuEupMyoenDongText => '$siDo $siGunGu $eupMyoenDong';
}
