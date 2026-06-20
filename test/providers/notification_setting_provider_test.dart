import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';

class FakeNotificationSettingRepository implements NotificationSettingRepository {
  bool shouldThrow = false;
  int callCount = 0;

  @override
  Future<void> update(NotificationSettingType type, bool value) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
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
  });
}
