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
}
