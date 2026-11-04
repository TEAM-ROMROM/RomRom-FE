import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/gps_location_verifier.dart';

/// 테스트용 좌표 (기본 서울, 오차·가상 위치·위경도 지정)
Position buildPosition({
  double accuracy = 10,
  bool isMocked = false,
  double latitude = 37.5,
  double longitude = 127.0,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026, 11, 4),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: isMocked,
);

/// 플랫폼 응답 대역: 위치 서비스·권한·정확도·좌표·주소 지정, 권한 요청·설정 열기 횟수 기록
class FakeLocationPlatform {
  bool isServiceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  LocationAccuracyStatus accuracyStatus = LocationAccuracyStatus.precise;
  Position? position = buildPosition();
  Object? positionError;
  LocationAddress? address = LocationAddress(siDo: '서울특별시', siGunGu: '광진구', eupMyoenDong: '군자동');
  int lookupAddressCount = 0;

  int requestPermissionCount = 0;
  int getCurrentPositionCount = 0;
  int openAppSettingsCount = 0;
  int openLocationSettingsCount = 0;
  LocationSettings? lastLocationSettings;

  GpsLocationVerifier buildVerifier() => GpsLocationVerifier(
    isLocationServiceEnabled: () async => isServiceEnabled,
    checkPermission: () async => permission,
    requestPermission: () async {
      requestPermissionCount++;
      permission = permissionAfterRequest;
      return permission;
    },
    getLocationAccuracy: () async => accuracyStatus,
    getCurrentPosition: (locationSettings) async {
      getCurrentPositionCount++;
      lastLocationSettings = locationSettings;
      if (positionError != null) throw positionError!;
      return position!;
    },
    lookupAddress: (latitude, longitude) async {
      lookupAddressCount++;
      return address;
    },
    openAppSettings: () async {
      openAppSettingsCount++;
      return true;
    },
    openLocationSettings: () async {
      openLocationSettingsCount++;
      return true;
    },
  );
}

void main() {
  late FakeLocationPlatform platform;

  setUp(() => platform = FakeLocationPlatform());

  group('GpsLocationVerifier.checkCurrentLocation', () {
    test('허용 + 정확한 실제 위치 > 좌표·동네 반환, 고정밀·시간 제한 조회', () async {
      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.isLocated, isTrue);
      expect(result.address?.eupMyoenDong, '군자동');
      expect(result.latitude, 37.5);
      expect(platform.lastLocationSettings?.accuracy, LocationAccuracy.high);
      expect(platform.lastLocationSettings?.timeLimit, GpsLocationVerifier.positionTimeLimit);
      expect(platform.requestPermissionCount, 0);
    });

    test('위치 서비스 꺼짐 > 권한 요청·좌표 조회 없이 실패', () async {
      platform.isServiceEnabled = false;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.locationServiceDisabled);
      expect(platform.requestPermissionCount, 0);
      expect(platform.getCurrentPositionCount, 0);
    });

    test('권한 미결정 > 요청 1회 > 거부 > 권한 거부 실패 (재요청 반복 없음)', () async {
      platform.permission = LocationPermission.denied;
      platform.permissionAfterRequest = LocationPermission.denied;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.permissionDenied);
      expect(platform.requestPermissionCount, 1);
      expect(platform.getCurrentPositionCount, 0);
    });

    test('권한 미결정 + 요청 금지(설정 복귀 재확인) > 요청 없이 권한 거부 실패', () async {
      platform.permission = LocationPermission.denied;

      final result = await platform.buildVerifier().checkCurrentLocation(shouldRequestPermission: false);

      expect(result.failure, LocationVerificationFailure.permissionDenied);
      expect(platform.requestPermissionCount, 0);
    });

    test('권한 미결정 > 요청 후 허용 > 인증 위치 확인 진행', () async {
      platform.permission = LocationPermission.denied;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.isLocated, isTrue);
      expect(platform.requestPermissionCount, 1);
    });

    test('영구 거부 > 시스템 요청 없이 설정 안내 실패', () async {
      platform.permission = LocationPermission.deniedForever;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.permissionDeniedForever);
      expect(result.failure?.isSettingsPrimaryAction, isTrue);
      expect(platform.requestPermissionCount, 0);
    });

    test('대략적 위치만 허용 > 정확한 위치 필요 실패', () async {
      platform.accuracyStatus = LocationAccuracyStatus.reduced;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.approximateLocationOnly);
      expect(platform.getCurrentPositionCount, 0);
    });

    test('가상 위치(모의 위치·시뮬레이션) > 주소 조회 없이 거부', () async {
      platform.position = buildPosition(isMocked: true);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.mockedLocation);
      expect(result.isLocated, isFalse);
    });

    test('오차 100m 초과 > 낮은 정확도 실패 (창가 재시도 안내)', () async {
      platform.position = buildPosition(accuracy: 150);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.lowAccuracy);
      expect(result.failure?.description, contains('창가'));
    });

    test('오차 정확히 100m > 통과', () async {
      platform.position = buildPosition(accuracy: GpsLocationVerifier.maximumAccuracyMeters);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.isLocated, isTrue);
    });

    test('좌표 조회 시간 초과 > 현재 위치 없음 실패', () async {
      platform.positionError = TimeoutException('timeout');

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.positionUnavailable);
    });

    test('역지오코딩 실패 > 동네 확인 실패', () async {
      platform.address = null;

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.addressNotFound);
    });
  });

  group('GpsLocationVerifier 서비스 지역 (대한민국)', () {
    test('국내 실제 위치 > GPS 동네 인증 (지도 선택 아님)', () async {
      platform.position = buildPosition(latitude: 35.1796, longitude: 129.0756);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.isLocated, isTrue);
      expect(result.isOutsideServiceArea, isFalse);
    });

    test('해외 실제 위치 > 서비스 지역 밖 결과 (실패 아님, 역지오코딩 생략)', () async {
      platform.position = buildPosition(latitude: 37.3349, longitude: -122.0090);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, isNull);
      expect(result.isOutsideServiceArea, isTrue);
      expect(result.isLocated, isFalse);
      expect(result.latitude, 37.3349);
      expect(platform.lookupAddressCount, 0);
    });

    test('해외 + 가상 위치 > 서비스 지역 밖이어도 가상 위치 거부', () async {
      platform.position = buildPosition(latitude: 37.3349, longitude: -122.0090, isMocked: true);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.mockedLocation);
      expect(result.isOutsideServiceArea, isFalse);
    });

    test('해외 + 오차 100m 초과 > 낮은 정확도 거부', () async {
      platform.position = buildPosition(latitude: 51.5, longitude: -0.12, accuracy: 300);

      final result = await platform.buildVerifier().checkCurrentLocation();

      expect(result.failure, LocationVerificationFailure.lowAccuracy);
    });

    test('범위 경계 > 제주 남단·독도 포함, 대마도 동쪽 밖', () {
      const bounds = GpsLocationVerifier.koreaServiceAreaBounds;
      expect(bounds.contains(33.11, 126.27), isTrue);
      expect(bounds.contains(37.24, 131.86), isTrue);
      expect(bounds.contains(35.68, 139.69), isFalse);
    });
  });

  group('GpsLocationVerifier.openSettingsFor', () {
    test('권한 거부 > 앱 설정, 위치 서비스 꺼짐 > 위치 설정, 가상 위치 > 설정 없음', () async {
      final verifier = platform.buildVerifier();

      expect(await verifier.openSettingsFor(LocationVerificationFailure.permissionDeniedForever), isTrue);
      expect(await verifier.openSettingsFor(LocationVerificationFailure.locationServiceDisabled), isTrue);
      expect(await verifier.openSettingsFor(LocationVerificationFailure.mockedLocation), isFalse);
      expect(platform.openAppSettingsCount, 1);
      expect(platform.openLocationSettingsCount, 1);
    });
  });
}
