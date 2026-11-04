import 'package:romrom_fe/enums/location_settings_destination.dart';

/// 동네 인증 실패 사유 8개 > 안내 문구 + 설정 이동 대상 (설정 불필요 > null)
enum LocationVerificationFailure {
  locationServiceDisabled(
    title: '위치 서비스가 꺼져 있어요',
    description: '기기 설정에서 위치 서비스를 켠 뒤\n다시 시도해 주세요.',
    settingsDestination: LocationSettingsDestination.locationSettings,
  ),
  permissionDenied(
    title: '위치 인증이 필요해요',
    description: '이웃끼리만 거래할 수 있도록\n지금 있는 위치로 동네를 확인해요.\n위치 권한을 허용하면 바로 인증할 수 있어요.',
    settingsDestination: LocationSettingsDestination.appSettings,
  ),
  permissionDeniedForever(
    title: '위치 인증이 필요해요',
    description: '위치 권한이 꺼져 있어요.\n설정에서 위치 권한을 "앱을 사용하는 동안"으로\n바꾼 뒤 다시 시도해 주세요.',
    settingsDestination: LocationSettingsDestination.appSettings,
  ),
  approximateLocationOnly(
    title: '정확한 위치가 필요해요',
    description: '대략적인 위치로는 동네를 확인할 수 없어요.\n설정에서 "정확한 위치"를 켠 뒤 다시 시도해 주세요.',
    settingsDestination: LocationSettingsDestination.appSettings,
  ),
  mockedLocation(title: '실제 위치를 확인할 수 없어요', description: '위치 변경 앱이나 가상 위치가 켜져 있어요.\n끈 뒤 지금 있는 곳에서 다시 시도해 주세요.'),
  lowAccuracy(title: '위치가 정확하지 않아요', description: '실내라면 창가나 바깥에서\n다시 시도해 주세요.'),
  positionUnavailable(title: '현재 위치를 찾지 못했어요', description: '신호가 잘 잡히는 곳에서\n잠시 후 다시 시도해 주세요.'),
  addressNotFound(title: '동네를 확인하지 못했어요', description: '네트워크 연결을 확인한 뒤\n다시 시도해 주세요.');

  final String title;
  final String description;
  final LocationSettingsDestination? settingsDestination;

  const LocationVerificationFailure({required this.title, required this.description, this.settingsDestination});

  /// 설정 이동이 주 해결책인지 (권한 영구 거부·위치 서비스 꺼짐·대략 위치 > 설정 열기 우선)
  bool get isSettingsPrimaryAction =>
      this == permissionDeniedForever || this == locationServiceDisabled || this == approximateLocationOnly;
}
