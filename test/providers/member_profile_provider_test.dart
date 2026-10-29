import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_item_category.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/repositories/member_repository.dart';

/// 회원 repository 대역: 호출 횟수·마지막 인자 기록, 실패·결과값 조절
class FakeMemberRepository implements MemberRepository {
  int getMemberInfoCallCount = 0;
  int savePreferredCategoriesCallCount = 0;
  int saveLocationCallCount = 0;
  int saveSearchRadiusCallCount = 0;
  int saveTermsAgreementCallCount = 0;

  bool shouldThrowOnGet = false;
  bool shouldThrowOnMutation = false;
  bool mutationResult = true;

  List<int>? lastPreferredCategories;
  double? lastSearchRadiusInMeters;
  bool? lastIsMarketingInfoAgreed;
  String? lastSiGunGu;

  @override
  Future<MemberResponse> getMemberInfo() async {
    getMemberInfoCallCount++;
    if (shouldThrowOnGet) throw Exception('get failed');
    return MemberResponse(
      member: Member(memberId: 'me', searchRadiusInMeters: 5000.0 + getMemberInfoCallCount),
      memberItemCategories: [MemberItemCategory(itemCategory: 'FOOD')],
    );
  }

  @override
  Future<void> updateProfile({required String nickname, required String profileUrl}) async {}

  @override
  Future<bool> savePreferredCategories(List<int> preferredCategories) async {
    savePreferredCategoriesCallCount++;
    lastPreferredCategories = preferredCategories;
    if (shouldThrowOnMutation) throw Exception('mutation failed');
    return mutationResult;
  }

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
    lastSiGunGu = siGunGu;
    if (shouldThrowOnMutation) throw Exception('mutation failed');
  }

  @override
  Future<bool> saveSearchRadius(double searchRadiusInMeters) async {
    saveSearchRadiusCallCount++;
    lastSearchRadiusInMeters = searchRadiusInMeters;
    if (shouldThrowOnMutation) throw Exception('mutation failed');
    return mutationResult;
  }

  @override
  Future<bool> saveTermsAgreement({required bool isMarketingInfoAgreed}) async {
    saveTermsAgreementCallCount++;
    lastIsMarketingInfoAgreed = isMarketingInfoAgreed;
    if (shouldThrowOnMutation) throw Exception('mutation failed');
    return mutationResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('memberProfileProvider', () {
    late FakeMemberRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeMemberRepository();
      container = ProviderContainer(overrides: [memberRepositoryProvider.overrideWithValue(fake)]);
    });

    tearDown(() => container.dispose());

    /// 첫 조회 완료 후 호출 횟수 초기화 (변경 메서드의 재조회만 세기 위함)
    Future<MemberProfileNotifier> loadInitialProfile() async {
      await container.read(memberProfileProvider.future);
      fake.getMemberInfoCallCount = 0;
      return container.read(memberProfileProvider.notifier);
    }

    test('조회 결과의 선호 카테고리를 상태에 담는다', () async {
      final profile = await container.read(memberProfileProvider.future);
      expect(profile.itemCategories?.single.itemCategory, 'FOOD');
    });

    test('savePreferredCategories: repository 1회 + 재조회 1회, 결과 반환', () async {
      final notifier = await loadInitialProfile();
      final isSaved = await notifier.savePreferredCategories([1, 2]);
      expect(isSaved, isTrue);
      expect(fake.savePreferredCategoriesCallCount, 1);
      expect(fake.lastPreferredCategories, [1, 2]);
      expect(fake.getMemberInfoCallCount, 1);
    });

    test('savePreferredCategories: 서버 거부(false)면 재조회 없음', () async {
      final notifier = await loadInitialProfile();
      fake.mutationResult = false;
      final isSaved = await notifier.savePreferredCategories([1]);
      expect(isSaved, isFalse);
      expect(fake.getMemberInfoCallCount, 0);
    });

    test('saveLocation: repository 1회 + 재조회 1회', () async {
      final notifier = await loadInitialProfile();
      await notifier.saveLocation(
        longitude: 127.0,
        latitude: 37.5,
        siDo: '서울특별시',
        siGunGu: '중구',
        eupMyoenDong: '태평로1가',
      );
      expect(fake.saveLocationCallCount, 1);
      expect(fake.lastSiGunGu, '중구');
      expect(fake.getMemberInfoCallCount, 1);
    });

    test('saveLocation: 저장 실패 시 예외 전달 + 재조회 없음', () async {
      final notifier = await loadInitialProfile();
      fake.shouldThrowOnMutation = true;
      await expectLater(
        notifier.saveLocation(longitude: 0, latitude: 0, siDo: 'a', siGunGu: 'b', eupMyoenDong: 'c'),
        throwsException,
      );
      expect(fake.getMemberInfoCallCount, 0);
    });

    test('saveSearchRadius: repository 1회 + 재조회로 최신 반경 반영', () async {
      final notifier = await loadInitialProfile();
      final isSaved = await notifier.saveSearchRadius(7500.0);
      expect(isSaved, isTrue);
      expect(fake.saveSearchRadiusCallCount, 1);
      expect(fake.lastSearchRadiusInMeters, 7500.0);
      expect(fake.getMemberInfoCallCount, 1);
      expect(container.read(memberProfileProvider).valueOrNull?.member?.searchRadiusInMeters, 5001.0);
    });

    test('saveTermsAgreement: repository 1회 + 재조회 1회', () async {
      final notifier = await loadInitialProfile();
      final isSaved = await notifier.saveTermsAgreement(isMarketingInfoAgreed: true);
      expect(isSaved, isTrue);
      expect(fake.saveTermsAgreementCallCount, 1);
      expect(fake.lastIsMarketingInfoAgreed, isTrue);
      expect(fake.getMemberInfoCallCount, 1);
    });

    test('미조회 상태(온보딩)에서도 변경 메서드 동작', () async {
      final notifier = container.read(memberProfileProvider.notifier);
      final isSaved = await notifier.saveTermsAgreement(isMarketingInfoAgreed: false);
      expect(isSaved, isTrue);
      expect(fake.saveTermsAgreementCallCount, 1);
      expect(container.read(memberProfileProvider).valueOrNull?.member?.memberId, 'me');
    });

    test('fetchLatest: 매번 서버 재조회 후 최신값 반환', () async {
      final notifier = await loadInitialProfile();
      final profile = await notifier.fetchLatest();
      expect(fake.getMemberInfoCallCount, 1);
      expect(profile.member?.searchRadiusInMeters, 5001.0);
    });

    test('fetchLatest: 재조회 실패 시 예외 전달 + 이전 값 유지', () async {
      final notifier = await loadInitialProfile();
      fake.shouldThrowOnGet = true;
      await expectLater(notifier.fetchLatest(), throwsException);
      expect(container.read(memberProfileProvider).valueOrNull?.member?.memberId, 'me');
    });

    test('fetchCachedOrReload: 정상 캐시가 있으면 재조회 없이 반환', () async {
      final notifier = await loadInitialProfile();
      final profile = await notifier.fetchCachedOrReload();
      expect(fake.getMemberInfoCallCount, 0);
      expect(profile.member?.memberId, 'me');
    });

    test('fetchCachedOrReload: 조회 실패 상태면 재조회', () async {
      fake.shouldThrowOnGet = true;
      await expectLater(container.read(memberProfileProvider.future), throwsException);
      fake.shouldThrowOnGet = false;
      final profile = await container.read(memberProfileProvider.notifier).fetchCachedOrReload();
      expect(profile.member?.memberId, 'me');
    });
  });
}
