import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/location_verification_method.dart';
import 'package:romrom_fe/models/gps_location_check_result.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/models/location_verification_record.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/repositories/location_verification_repository.dart';
import 'package:romrom_fe/services/gps_location_verifier.dart';
import 'package:romrom_fe/states/location_verification_state.dart';

final locationVerificationRepositoryProvider = Provider<LocationVerificationRepository>(
  (ref) => LocationVerificationRepository(),
);

final gpsLocationVerifierProvider = Provider<GpsLocationVerifier>((ref) => GpsLocationVerifier());

final locationVerificationProvider = AsyncNotifierProvider<LocationVerificationNotifier, LocationVerificationState>(
  LocationVerificationNotifier.new,
);

/// 동네 인증 단일 소유: 현재 회원 인증 여부(서버 회원 위치 isLocationVerified 우선, 구버전 서버 > 로컬 기록),
/// GPS·서비스 지역 밖 지도 선택 인증(서버 위치 저장 + 인증 방식 > 로컬 기록), 기록 삭제
class LocationVerificationNotifier extends AsyncNotifier<LocationVerificationState> {
  LocationVerificationRepository get _repository => ref.read(locationVerificationRepositoryProvider);

  @override
  Future<LocationVerificationState> build() async => LocationVerificationState(record: await _repository.loadRecord());

  /// 현재 로그인 회원 인증 여부: 서버 인증 상태 > 없으면(구버전 서버·위치 없음·조회 실패) 로컬 기록
  /// (로컬 기록 없음·다른 회원 기록·비로그인 > false)
  Future<bool> isCurrentMemberVerified() async {
    final serverVerification = await _readServerVerification();
    if (serverVerification != null) return serverVerification;
    final memberId = await _repository.readCurrentMemberId();
    final verificationState = await future;
    return verificationState.isVerifiedFor(memberId);
  }

  /// 서버 거부(LOCATION_NOT_VERIFIED) 후: 서버 상태 재조회 + 로컬 기록 삭제 (다음 확인에서 다시 인증)
  Future<void> resyncAfterServerRejection() async {
    await ref.read(memberProfileProvider.notifier).reload();
    await clear();
  }

  /// 서버 회원 위치 인증 여부 (캐시 프로필 사용, 필드 없음·조회 실패 > null)
  Future<bool?> _readServerVerification() async {
    try {
      final profile = await ref.read(memberProfileProvider.notifier).fetchCachedOrReload();
      return profile.location?.isLocationVerified;
    } catch (error) {
      debugPrint('[location verification] server state read failed : $error');
      return null;
    }
  }

  /// GPS 확인 위치로 인증: 서버 회원 위치 저장 > 로컬 인증 기록(gps) (실패 시 예외 전달, 기록 미저장)
  Future<void> verifyWithCurrentLocation(GpsLocationCheckResult locatedResult) async {
    final address = locatedResult.address;
    final latitude = locatedResult.latitude;
    final longitude = locatedResult.longitude;
    if (!locatedResult.isLocated || address == null || latitude == null || longitude == null) {
      throw ArgumentError('GPS 확인에 성공한 위치만 인증할 수 있습니다.');
    }
    await _saveVerifiedLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      method: LocationVerificationMethod.gps,
    );
  }

  /// 서비스 지역 밖 지도 선택 위치로 인증 (서비스 지역 밖 GPS 결과일 때만, 기록 방식 manualOutsideServiceArea)
  Future<void> verifyWithManualSelection({
    required GpsLocationCheckResult outsideServiceAreaResult,
    required double latitude,
    required double longitude,
    required LocationAddress selectedAddress,
  }) async {
    if (!outsideServiceAreaResult.isOutsideServiceArea) {
      throw ArgumentError('서비스 지역 밖에서만 지도에서 동네를 선택할 수 있습니다.');
    }
    await _saveVerifiedLocation(
      latitude: latitude,
      longitude: longitude,
      address: selectedAddress,
      method: LocationVerificationMethod.manualOutsideServiceArea,
      gpsLatitude: outsideServiceAreaResult.latitude,
      gpsLongitude: outsideServiceAreaResult.longitude,
    );
  }

  /// 인증 위치 저장: 회원 확인 > 서버 회원 위치 저장(인증 방식·지도 선택 시 실제 GPS 좌표) > 로컬 인증 기록 > 상태 갱신
  Future<void> _saveVerifiedLocation({
    required double latitude,
    required double longitude,
    required LocationAddress address,
    required LocationVerificationMethod method,
    double? gpsLatitude,
    double? gpsLongitude,
  }) async {
    final memberId = await _repository.readCurrentMemberId();
    if (memberId == null || memberId.isEmpty) throw StateError('로그인 정보를 찾을 수 없습니다.');

    await ref
        .read(memberProfileProvider.notifier)
        .saveLocation(
          longitude: longitude,
          latitude: latitude,
          siDo: address.siDo,
          siGunGu: address.siGunGu,
          eupMyoenDong: address.eupMyoenDong,
          ri: address.ri,
          verificationMethod: method,
          gpsLatitude: gpsLatitude,
          gpsLongitude: gpsLongitude,
        );

    final record = LocationVerificationRecord(
      memberId: memberId,
      verifiedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      method: method,
    );
    await _repository.saveRecord(record);
    state = AsyncData(LocationVerificationState(record: record));
  }

  /// 인증 기록 삭제 (다음 기능 사용 시 다시 인증)
  Future<void> clear() async {
    await _repository.clearRecord();
    state = const AsyncData(LocationVerificationState());
  }
}
