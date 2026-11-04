import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/providers/do_not_disturb_setting_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/states/do_not_disturb_setting_state.dart';

/// 방해금지 저장 대역: 저장 값 기록, 실패·지연 지정
class _RecordingDoNotDisturbRepository implements NotificationSettingRepository {
  final List<DoNotDisturbSettingState> savedSettings = [];
  bool shouldThrow = false;
  Completer<void>? saveGate;

  @override
  Future<void> updateDoNotDisturb(DoNotDisturbSettingState setting) async {
    savedSettings.add(setting);
    final gate = saveGate;
    if (gate != null) await gate.future;
    if (shouldThrow) throw Exception('save failed');
  }

  @override
  Future<void> update(NotificationSettingType type, bool value) async {}

  @override
  Future<void> updateAll(Map<NotificationSettingType, bool> values) async {}
}

void main() {
  // navigatorKey.currentContext(GlobalKey) 접근이 바인딩을 요구하므로 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingDoNotDisturbRepository repository;
  late ProviderContainer container;
  const enabledSetting = DoNotDisturbSettingState(isEnabled: true);

  setUp(() {
    repository = _RecordingDoNotDisturbRepository();
    container = ProviderContainer(overrides: [notificationSettingRepositoryProvider.overrideWithValue(repository)]);
  });

  tearDown(() => container.dispose());

  group('DoNotDisturbSettingState', () {
    test('회원 정보 > 설정: "HH:mm"·"HH:mm:ss" 파싱, 누락·형식 오류는 기본값(꺼짐 22:00~08:00)', () {
      final parsed = DoNotDisturbSettingState.fromMember(
        Member(isDoNotDisturbEnabled: true, doNotDisturbStartTime: '23:30', doNotDisturbEndTime: '07:00:00'),
      );
      expect(
        parsed,
        const DoNotDisturbSettingState(
          isEnabled: true,
          startTime: TimeOfDay(hour: 23, minute: 30),
          endTime: TimeOfDay(hour: 7, minute: 0),
        ),
      );
      expect(parsed.isOvernight, isTrue);

      final fallback = DoNotDisturbSettingState.fromMember(Member(doNotDisturbStartTime: '25:00'));
      expect(fallback, const DoNotDisturbSettingState());
      expect(fallback.startTimeText, '22:00');
      expect(fallback.endTimeText, '08:00');
    });
  });

  group('doNotDisturbSettingProvider.save', () {
    test('즉시 반영 > 서버 저장 1회 > true', () async {
      final isSaved = await container.read(doNotDisturbSettingProvider.notifier).save(enabledSetting);

      expect(isSaved, isTrue);
      expect(container.read(doNotDisturbSettingProvider), enabledSetting);
      expect(repository.savedSettings, [enabledSetting]);
    });

    test('실패 > 이전 값 롤백 + false', () async {
      repository.shouldThrow = true;

      final isSaved = await container.read(doNotDisturbSettingProvider.notifier).save(enabledSetting);

      expect(isSaved, isFalse);
      expect(container.read(doNotDisturbSettingProvider), const DoNotDisturbSettingState());
    });

    test('저장 중 재호출·시작=종료·같은 값 > 요청 없이 false', () async {
      final notifier = container.read(doNotDisturbSettingProvider.notifier);
      repository.saveGate = Completer<void>();

      final firstSave = notifier.save(enabledSetting);
      expect(await notifier.save(const DoNotDisturbSettingState()), isFalse, reason: '진행 중 중복');
      repository.saveGate!.complete();
      expect(await firstSave, isTrue);

      const sameStartAndEnd = DoNotDisturbSettingState(
        isEnabled: true,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 9, minute: 0),
      );
      expect(await notifier.save(sameStartAndEnd), isFalse);
      expect(await notifier.save(enabledSetting), isFalse, reason: '같은 값');
      expect(repository.savedSettings, [enabledSetting]);
    });
  });
}
