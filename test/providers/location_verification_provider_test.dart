import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/enums/location_verification_method.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/models/gps_location_check_result.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/models/location_verification_record.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/location_verification_provider.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';
import 'package:romrom_fe/repositories/location_verification_repository.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 회원 repository 대역: 위치 저장 호출 기록, 저장 실패 조절
class _FakeMemberRepository implements MemberRepository {
  int saveLocationCallCount = 0;
  bool shouldFailSaveLocation = false;
  String? lastEupMyoenDong;
  double? lastLatitude;

  @override
  Future<MemberResponse> getMemberInfo() async => MemberResponse(member: Member(memberId: 'member-a'));

  @override
  Future<void> saveLocation({
    required double longitude,
    required double latitude,
    required String siDo,
    required String siGunGu,
    required String eupMyoenDong,
    String? ri,
  }) async {
    saveLocationCallCount++;
    if (shouldFailSaveLocation) throw Exception('save failed');
    lastEupMyoenDong = eupMyoenDong;
    lastLatitude = latitude;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _locatedResult = GpsLocationCheckResult.located(
  latitude: 37.55,
  longitude: 127.07,
  accuracyMeters: 12,
  address: LocationAddress(siDo: '서울특별시', siGunGu: '광진구', eupMyoenDong: '군자동'),
);

void main() {
  late _FakeMemberRepository memberRepository;
  late String? currentMemberId;
  late ProviderContainer container;

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      memberRepositoryProvider.overrideWithValue(memberRepository),
      locationVerificationRepositoryProvider.overrideWithValue(
        LocationVerificationRepository(readCurrentMemberId: () async => currentMemberId),
      ),
    ],
  );

  /// 저장소 초기값 변경 후 새 컨테이너 (이전 컨테이너 정리)
  void rebuildContainer() {
    container.dispose();
    container = createContainer();
  }

  /// 기기에 특정 회원 인증 기록 미리 저장
  void seedStoredRecord(String memberId) {
    final record = LocationVerificationRecord(
      memberId: memberId,
      verifiedAt: DateTime(2026, 11, 1),
      latitude: 37.5,
      longitude: 127.0,
    );
    SharedPreferences.setMockInitialValues({StorageKeys.locationVerificationRecord.key: jsonEncode(record.toJson())});
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    memberRepository = _FakeMemberRepository();
    currentMemberId = 'member-a';
    container = createContainer();
  });
  tearDown(() => container.dispose());

  group('isCurrentMemberVerified', () {
    test('기록 없음 (기존 핀 위치만 저장한 회원 포함) > 미인증', () async {
      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isFalse);
    });

    test('같은 회원 기록 > 인증됨', () async {
      seedStoredRecord('member-a');
      rebuildContainer();

      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isTrue);
    });

    test('다른 회원 기록 > 미인증', () async {
      seedStoredRecord('member-b');
      rebuildContainer();

      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isFalse);
    });

    test('비로그인 > 미인증', () async {
      seedStoredRecord('member-a');
      currentMemberId = null;
      rebuildContainer();

      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isFalse);
    });

    test('저장 형식 오류 > 미인증 (예외 없음)', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.locationVerificationRecord.key: '{broken'});
      rebuildContainer();

      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isFalse);
    });
  });

  group('verifyWithCurrentLocation', () {
    test('GPS 확인 위치 > 서버 위치 저장 + 회원별 기록 저장 > 인증됨', () async {
      final notifier = container.read(locationVerificationProvider.notifier);
      await container.read(locationVerificationProvider.future);

      await notifier.verifyWithCurrentLocation(_locatedResult);

      expect(memberRepository.saveLocationCallCount, 1);
      expect(memberRepository.lastEupMyoenDong, '군자동');
      expect(memberRepository.lastLatitude, 37.55);
      expect(await notifier.isCurrentMemberVerified(), isTrue);
      final storedRecord = await LocationVerificationRepository(readCurrentMemberId: () async => null).loadRecord();
      expect(storedRecord?.memberId, 'member-a');
      expect(storedRecord?.latitude, 37.55);
      expect(UserInfo().isMemberLocationSaved, isTrue);
    });

    test('서버 저장 실패 > 예외 전달, 기록 미저장', () async {
      memberRepository.shouldFailSaveLocation = true;
      final notifier = container.read(locationVerificationProvider.notifier);

      await expectLater(notifier.verifyWithCurrentLocation(_locatedResult), throwsException);
      expect(await notifier.isCurrentMemberVerified(), isFalse);
    });

    test('실패 결과(가상 위치) > 서버 저장 없이 거부', () async {
      final notifier = container.read(locationVerificationProvider.notifier);

      await expectLater(
        notifier.verifyWithCurrentLocation(
          const GpsLocationCheckResult.failed(LocationVerificationFailure.mockedLocation),
        ),
        throwsArgumentError,
      );
      expect(memberRepository.saveLocationCallCount, 0);
    });
  });

  group('verifyWithManualSelection (서비스 지역 밖)', () {
    const outsideServiceAreaResult = GpsLocationCheckResult.outsideServiceArea(
      latitude: 37.3349,
      longitude: -122.0090,
      accuracyMeters: 15,
    );

    test('해외 실제 GPS 결과 + 지도 선택 동네 > 선택 좌표로 서버 저장, 기록 방식 manualOutsideServiceArea', () async {
      final notifier = container.read(locationVerificationProvider.notifier);

      await notifier.verifyWithManualSelection(
        outsideServiceAreaResult: outsideServiceAreaResult,
        latitude: 37.55,
        longitude: 127.07,
        selectedAddress: LocationAddress(siDo: '서울특별시', siGunGu: '광진구', eupMyoenDong: '군자동'),
      );

      expect(memberRepository.lastLatitude, 37.55);
      expect(await notifier.isCurrentMemberVerified(), isTrue);
      final storedRecord = await LocationVerificationRepository(readCurrentMemberId: () async => null).loadRecord();
      expect(storedRecord?.method, LocationVerificationMethod.manualOutsideServiceArea);
    });

    test('국내 GPS 결과로 지도 선택 시도 > 거부 (국내는 GPS만)', () async {
      final notifier = container.read(locationVerificationProvider.notifier);

      await expectLater(
        notifier.verifyWithManualSelection(
          outsideServiceAreaResult: _locatedResult,
          latitude: 35.0,
          longitude: 129.0,
          selectedAddress: LocationAddress(siDo: '부산광역시', siGunGu: '해운대구', eupMyoenDong: '우동'),
        ),
        throwsArgumentError,
      );
      expect(memberRepository.saveLocationCallCount, 0);
    });

    test('GPS 인증 기록 방식 gps, 방식 없는 저장 값 > gps', () async {
      await container.read(locationVerificationProvider.notifier).verifyWithCurrentLocation(_locatedResult);
      final storedRecord = await LocationVerificationRepository(readCurrentMemberId: () async => null).loadRecord();
      expect(storedRecord?.method, LocationVerificationMethod.gps);

      final legacyRecord = LocationVerificationRecord.tryFromJson({
        'memberId': 'member-a',
        'verifiedAt': '2026-11-01T00:00:00.000',
        'latitude': 37.5,
        'longitude': 127.0,
      });
      expect(legacyRecord?.method, LocationVerificationMethod.gps);
    });
  });

  group('로그아웃', () {
    test('UserInfo 로그아웃 정리 > 기기 기록 삭제 + provider 초기화 > 미인증', () async {
      final notifier = container.read(locationVerificationProvider.notifier);
      await notifier.verifyWithCurrentLocation(_locatedResult);
      expect(await notifier.isCurrentMemberVerified(), isTrue);

      await UserInfo().clearUserInfoExceptIsCoachMarkShown();
      invalidateUserScopedProviders(container.invalidate);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(StorageKeys.locationVerificationRecord.key), isNull);
      expect(await container.read(locationVerificationProvider.notifier).isCurrentMemberVerified(), isFalse);
    });

    test('userScopedProviders 등록', () {
      expect(userScopedProviders, contains(locationVerificationProvider));
    });
  });
}
