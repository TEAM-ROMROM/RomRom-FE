/// 동네 인증 방식 2개 > 기기 저장 값·서버 값: 실제 GPS 위치, 서비스 지역 밖 지도 직접 선택
enum LocationVerificationMethod {
  gps('gps', 'GPS'),
  // 실제 GPS가 대한민국 밖(해외 심사 등) > 지도에서 동네 선택
  manualOutsideServiceArea('manualOutsideServiceArea', 'MANUAL_OUTSIDE_SERVICE_AREA');

  final String storageValue;
  // 서버 위치 저장 API locationVerificationMethod 값
  final String serverName;

  const LocationVerificationMethod(this.storageValue, this.serverName);

  /// 저장 값 > 방식 (없음·모르는 값 > gps)
  static LocationVerificationMethod fromStorageValue(String? storageValue) => LocationVerificationMethod.values
      .firstWhere((method) => method.storageValue == storageValue, orElse: () => LocationVerificationMethod.gps);
}
