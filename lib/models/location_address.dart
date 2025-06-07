class LocationAddress {
  final String siDo;
  final String siGunGu;
  final String eupMyoenDong;
  final String? ri;
  final String currentAddress;

  LocationAddress({
    required this.siDo,
    required this.siGunGu,
    required this.eupMyoenDong,
    this.ri,
    String? currentAddress,
  }) : currentAddress = currentAddress ?? eupMyoenDong;
}
