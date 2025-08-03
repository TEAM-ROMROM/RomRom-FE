class LocationAddress {
  final String siDo;
  final String siGunGu;
  final String eupMyoenDong;
  final String? ri;
  final String currentAddress;
  final double? longitude;
  final double? latitude;

  LocationAddress({
    required this.siDo,
    required this.siGunGu,
    required this.eupMyoenDong,
    required this.longitude,
    required this.latitude,
    this.ri,
    String? currentAddress,
  }) : currentAddress = currentAddress ?? eupMyoenDong;
}
