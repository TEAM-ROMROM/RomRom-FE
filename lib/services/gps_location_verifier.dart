import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:romrom_fe/enums/location_settings_destination.dart';
import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/models/geographic_bounds.dart';
import 'package:romrom_fe/models/gps_location_check_result.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';

/// 동네 인증용 실제 GPS 확인: 위치 서비스 > 권한 > 정확한 위치 > 현재 좌표 > 가상 위치 > 정확도 > 서비스 지역 > 동네 주소
/// 권한 요청은 [checkCurrentLocation] 호출 시에만 (호출 전 앱 안내 필수), 지도 선택은 서비스 지역 밖 결과일 때만
class GpsLocationVerifier {
  // 서비스 지역(대한민국) 대략 범위: 위도 33.0~38.7, 경도 124.5~131.9 (네이버 역지오코딩 지원 범위, 해외 심사 대응)
  // 서버 RomRom-BE KoreaServiceArea 와 같은 값 (지도 직접 선택 인증 검증, 함께 변경)
  static const GeographicBounds koreaServiceAreaBounds = GeographicBounds(
    minimumLatitude: 33.0,
    maximumLatitude: 38.7,
    minimumLongitude: 124.5,
    maximumLongitude: 131.9,
  );

  // 인증 허용 수평 오차 상한 (100m, 넘으면 실내 등 > 재시도 안내)
  static const double maximumAccuracyMeters = 100;

  // 현재 좌표 조회 대기 상한 (15초, 실내 GPS 지연 고려)
  static const Duration positionTimeLimit = Duration(seconds: 15);

  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<LocationAccuracyStatus> Function() _getLocationAccuracy;
  final Future<Position> Function(LocationSettings locationSettings) _getCurrentPosition;
  final Future<LocationAddress?> Function(double latitude, double longitude) _lookupAddress;
  final Future<bool> Function() _openAppSettings;
  final Future<bool> Function() _openLocationSettings;

  GpsLocationVerifier({
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<LocationAccuracyStatus> Function()? getLocationAccuracy,
    Future<Position> Function(LocationSettings locationSettings)? getCurrentPosition,
    Future<LocationAddress?> Function(double latitude, double longitude)? lookupAddress,
    Future<bool> Function()? openAppSettings,
    Future<bool> Function()? openLocationSettings,
  }) : _isLocationServiceEnabled = isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _requestPermission = requestPermission ?? Geolocator.requestPermission,
       _getLocationAccuracy = getLocationAccuracy ?? Geolocator.getLocationAccuracy,
       _getCurrentPosition =
           getCurrentPosition ??
           ((locationSettings) => Geolocator.getCurrentPosition(locationSettings: locationSettings)),
       _lookupAddress =
           lookupAddress ??
           ((latitude, longitude) => LocationService().getAddressFromCoordinates(NLatLng(latitude, longitude))),
       _openAppSettings = openAppSettings ?? Geolocator.openAppSettings,
       _openLocationSettings = openLocationSettings ?? Geolocator.openLocationSettings;

  /// 권한 상태 확인 (시스템 팝업 없음, 앱 안내 노출 여부 판단용)
  Future<LocationPermission> checkPermission() => _checkPermission();

  /// 현재 GPS 위치 확인 1회 (권한 미허용 + [shouldRequestPermission] > 시스템 권한 요청 1회, 영구 거부면 요청 없이 실패)
  /// 설정 복귀 재확인 등 사용자 탭이 아닌 호출은 [shouldRequestPermission] false
  Future<GpsLocationCheckResult> checkCurrentLocation({bool shouldRequestPermission = true}) async {
    // 위치 서비스·권한·정확한 위치 (좌표 조회 전 차단)
    final accessFailure = await _findLocationAccessFailure(shouldRequestPermission: shouldRequestPermission);
    if (accessFailure != null) return GpsLocationCheckResult.failed(accessFailure);

    // 현재 좌표 (고정밀, 시간 제한)
    final Position position;
    try {
      position = await _getCurrentPosition(
        const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: positionTimeLimit),
      );
    } catch (error) {
      debugPrint('[location verification] position failed : $error');
      return const GpsLocationCheckResult.failed(LocationVerificationFailure.positionUnavailable);
    }

    // 좌표 신뢰도 (가상 위치 > 오차)
    final positionFailure = findPositionFailure(position);
    if (positionFailure != null) return GpsLocationCheckResult.failed(positionFailure);

    // 서비스 지역 밖 실제 위치 > 지도 직접 선택 (역지오코딩 결과 없음)
    if (!koreaServiceAreaBounds.contains(position.latitude, position.longitude)) {
      return GpsLocationCheckResult.outsideServiceArea(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    }

    // 동네 주소 (역지오코딩)
    final address = await lookupAddress(position.latitude, position.longitude);
    if (address == null) return const GpsLocationCheckResult.failed(LocationVerificationFailure.addressNotFound);

    return GpsLocationCheckResult.located(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      address: address,
    );
  }

  /// 좌표 > 동네 주소 (역지오코딩, 실패 > null)
  Future<LocationAddress?> lookupAddress(double latitude, double longitude) => _lookupAddress(latitude, longitude);

  /// 좌표 신뢰도 판정: 가상 위치(Android 모의 위치·iOS 15+ 소프트웨어 시뮬레이션) > 오차 상한 초과 > 통과(null)
  static LocationVerificationFailure? findPositionFailure(Position position) {
    if (position.isMocked) return LocationVerificationFailure.mockedLocation;
    // 오차 0 이하 = 기기가 오차 미제공 > 신뢰 불가
    if (position.accuracy <= 0 || position.accuracy > maximumAccuracyMeters) {
      return LocationVerificationFailure.lowAccuracy;
    }
    return null;
  }

  /// 실패 사유에 맞는 시스템 설정 열기 (설정 대상 없음 > false)
  Future<bool> openSettingsFor(LocationVerificationFailure failure) {
    switch (failure.settingsDestination) {
      case LocationSettingsDestination.appSettings:
        return _openAppSettings();
      case LocationSettingsDestination.locationSettings:
        return _openLocationSettings();
      case null:
        return Future.value(false);
    }
  }

  /// 위치 접근 차단 사유 (위치 서비스 꺼짐 > 권한 거부 > 대략 위치만 허용, 통과 > null)
  Future<LocationVerificationFailure?> _findLocationAccessFailure({required bool shouldRequestPermission}) async {
    if (!await _isLocationServiceEnabled()) return LocationVerificationFailure.locationServiceDisabled;

    var permission = await _checkPermission();
    if (permission == LocationPermission.deniedForever) return LocationVerificationFailure.permissionDeniedForever;
    if (permission == LocationPermission.denied && shouldRequestPermission) permission = await _requestPermission();
    if (permission == LocationPermission.deniedForever) return LocationVerificationFailure.permissionDeniedForever;
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return LocationVerificationFailure.permissionDenied;
    }

    // iOS 14+ 대략적 위치·Android 대략 위치 권한만 허용 > 동네 판정 불가
    if (await _isReducedAccuracyOnly()) return LocationVerificationFailure.approximateLocationOnly;
    return null;
  }

  /// 대략적 위치만 허용됐는지 (조회 실패 > false, 이후 오차 판정이 대신 거름)
  Future<bool> _isReducedAccuracyOnly() async {
    try {
      return await _getLocationAccuracy() == LocationAccuracyStatus.reduced;
    } catch (error) {
      debugPrint('[location verification] accuracy status failed : $error');
      return false;
    }
  }
}
