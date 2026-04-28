class AppVersionResponse {
  final String minimumVersion;
  final String latestVersion;
  final String androidStoreUrl;
  final String iosStoreUrl;

  const AppVersionResponse({
    required this.minimumVersion,
    required this.latestVersion,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      minimumVersion: json['minimumVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      androidStoreUrl: json['androidStoreUrl'] as String,
      iosStoreUrl: json['iosStoreUrl'] as String,
    );
  }
}
