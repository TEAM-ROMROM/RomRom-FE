import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class FakeNotificationSettingRepository implements NotificationSettingRepository {
  bool shouldThrow = false;
  int callCount = 0;
  int updateAllCallCount = 0;
  Map<NotificationSettingType, bool>? lastUpdateAllValues;

  @override
  Future<void> update(NotificationSettingType type, bool value) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
  }

  @override
  Future<void> updateAll(Map<NotificationSettingType, bool> values) async {
    updateAllCallCount++;
    lastUpdateAllValues = values;
    if (shouldThrow) throw Exception('boom');
  }
}

/// 회원 정보 조회 횟수만 세는 repository 대역 (API 미호출)
class CountingMemberRepository extends MemberRepository {
  int getMemberInfoCallCount = 0;

  CountingMemberRepository() : super(MemberApi());

  @override
  Future<MemberResponse> getMemberInfo() async {
    getMemberInfoCallCount++;
    return MemberResponse(member: Member(memberId: 'me'));
  }
}

void main() {
  // navigatorKey.currentContext(GlobalKey) 접근이 바인딩을 요구하므로 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  group('notificationSettingProvider', () {
    late FakeNotificationSettingRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeNotificationSettingRepository();
      container = ProviderContainer(overrides: [notificationSettingRepositoryProvider.overrideWithValue(fake)]);
    });

    tearDown(() => container.dispose());

    test('seed 후 setEnabled은 즉시 변경한다', () async {
      final n = container.read(notificationSettingProvider.notifier);
      n.seed({NotificationSettingType.marketing: false});

      final f = n.setEnabled(NotificationSettingType.marketing, true);
      expect(container.read(notificationSettingProvider)[NotificationSettingType.marketing], isTrue);
      await f;
      expect(fake.callCount, 1);
    });

    test('실패 시 prev로 롤백', () async {
      final n = container.read(notificationSettingProvider.notifier);
      n.seed({NotificationSettingType.activity: false});
      fake.shouldThrow = true;
      await n.setEnabled(NotificationSettingType.activity, true);
      expect(container.read(notificationSettingProvider)[NotificationSettingType.activity], isFalse);
    });

    test('in-flight 중 동일 type 재호출은 무시된다', () async {
      final n = container.read(notificationSettingProvider.notifier);
      n.seed({NotificationSettingType.chat: false});
      final f1 = n.setEnabled(NotificationSettingType.chat, true);
      final f2 = n.setEnabled(NotificationSettingType.chat, false);
      await Future.wait([f1, f2]);
      expect(fake.callCount, 1);
    });

    test('setAll은 repository updateAll 1회 호출 + 전체 즉시 반영 + true 반환', () async {
      final notifier = container.read(notificationSettingProvider.notifier);
      notifier.seed({for (final type in NotificationSettingType.values) type: true});
      final allDisabled = {for (final type in NotificationSettingType.values) type: false};

      final isUpdateSucceeded = await notifier.setAll(allDisabled, isSilent: true);

      expect(isUpdateSucceeded, isTrue);
      expect(fake.updateAllCallCount, 1);
      expect(fake.callCount, 0);
      expect(fake.lastUpdateAllValues, allDisabled);
      expect(container.read(notificationSettingProvider).values.every((isEnabled) => !isEnabled), isTrue);
    });

    test('setAll 실패 시 전체 롤백 + false 반환', () async {
      final notifier = container.read(notificationSettingProvider.notifier);
      notifier.seed({for (final type in NotificationSettingType.values) type: true});
      fake.shouldThrow = true;

      final isUpdateSucceeded = await notifier.setAll({
        for (final type in NotificationSettingType.values) type: false,
      }, isSilent: true);

      expect(isUpdateSucceeded, isFalse);
      expect(fake.updateAllCallCount, 1);
      expect(container.read(notificationSettingProvider).values.every((isEnabled) => isEnabled), isTrue);
    });

    test('세션 초기화(invalidate) 후 > 첫 시드(force=false) 다시 적용', () {
      final notifier = container.read(notificationSettingProvider.notifier);
      notifier.seed({NotificationSettingType.marketing: true});

      container.invalidate(notificationSettingProvider);
      expect(container.read(notificationSettingProvider)[NotificationSettingType.marketing], isFalse);

      container.read(notificationSettingProvider.notifier).seed({NotificationSettingType.marketing: true});
      expect(container.read(notificationSettingProvider)[NotificationSettingType.marketing], isTrue);
    });
  });

  group('notificationSettingProvider > memberProfileProvider 갱신', () {
    late FakeNotificationSettingRepository fakeSetting;
    late CountingMemberRepository fakeMember;
    late ProviderContainer container;

    setUp(() {
      fakeSetting = FakeNotificationSettingRepository();
      fakeMember = CountingMemberRepository();
      container = ProviderContainer(
        overrides: [
          notificationSettingRepositoryProvider.overrideWithValue(fakeSetting),
          memberRepositoryProvider.overrideWithValue(fakeMember),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('setEnabled 성공 시 회원 프로필 재조회 (알림 동의값 공유)', () async {
      await container.read(memberProfileProvider.future);
      await container.read(notificationSettingProvider.notifier).setEnabled(NotificationSettingType.chat, true);
      await container.read(memberProfileProvider.future);
      expect(fakeMember.getMemberInfoCallCount, 2);
    });

    test('setAll 성공 시 회원 프로필 재조회', () async {
      await container.read(memberProfileProvider.future);
      await container.read(notificationSettingProvider.notifier).setAll({
        NotificationSettingType.chat: false,
      }, isSilent: true);
      await container.read(memberProfileProvider.future);
      expect(fakeMember.getMemberInfoCallCount, 2);
    });

    test('실패 시 회원 프로필 재조회 없음', () async {
      await container.read(memberProfileProvider.future);
      fakeSetting.shouldThrow = true;
      await container.read(notificationSettingProvider.notifier).setEnabled(NotificationSettingType.chat, true);
      await container.read(memberProfileProvider.future);
      expect(fakeMember.getMemberInfoCallCount, 1);
    });

    test('프로필 미조회 상태면 추가 조회 없음', () async {
      await container.read(notificationSettingProvider.notifier).setEnabled(NotificationSettingType.chat, true);
      expect(fakeMember.getMemberInfoCallCount, 0);
    });
  });
}
