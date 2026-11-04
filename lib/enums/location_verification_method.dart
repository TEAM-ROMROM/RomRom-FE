/// 동네 인증 방식 2개 > 저장 값: 실제 GPS 위치, 서비스 지역 밖 지도 직접 선택
enum LocationVerificationMethod {
  gps('gps'),
  // 실제 GPS가 대한민국 밖(해외 심사 등) > 지도에서 동네 선택
  manualOutsideServiceArea('manualOutsideServiceArea');

  final String storageValue;

  const LocationVerificationMethod(this.storageValue);

  /// 저장 값 > 방식 (없음·모르는 값 > gps)
  static LocationVerificationMethod fromStorageValue(String? storageValue) => LocationVerificationMethod.values
      .firstWhere((method) => method.storageValue == storageValue, orElse: () => LocationVerificationMethod.gps);
}
