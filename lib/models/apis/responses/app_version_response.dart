class AppVersionResponse {
  final String minimumVersion;
  // 공통 최신 버전 (구버전 앱용, 두 스토어 모두 출시된 버전)
  final String latestVersion;
  // 플랫폼별 최신 버전 (스토어 출시 기준, 구버전 서버·미설정 > 빈 문자열 > latestVersion 사용)
  final String latestVersionIos;
  final String latestVersionAndroid;
  final String androidStoreUrl;
  final String iosStoreUrl;

  const AppVersionResponse({
    required this.minimumVersion,
    required this.latestVersion,
    this.latestVersionIos = '',
    this.latestVersionAndroid = '',
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  /// 서버 응답 > 버전 정보 (미설정 null > 빈 문자열, 형식 판정은 resolveUpdateType 담당)
  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      minimumVersion: json['minimumVersion'] as String? ?? '',
      latestVersion: json['latestVersion'] as String? ?? '',
      latestVersionIos: json['latestVersionIos'] as String? ?? '',
      latestVersionAndroid: json['latestVersionAndroid'] as String? ?? '',
      androidStoreUrl: json['androidStoreUrl'] as String? ?? '',
      iosStoreUrl: json['iosStoreUrl'] as String? ?? '',
    );
  }

  /// 실행 플랫폼 최신 버전 ([isIos] true > iOS, false > Android, 플랫폼 값 비어 있음 > 공통 최신 버전)
  String latestVersionFor({required bool isIos}) {
    final platformLatestVersion = isIos ? latestVersionIos : latestVersionAndroid;
    return platformLatestVersion.isEmpty ? latestVersion : platformLatestVersion;
  }
}
