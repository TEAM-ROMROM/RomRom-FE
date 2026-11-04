import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/chat_notification_guide_provider.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';

/// 채팅 알림 안내 시트 세션 1회 노출 (#984): 채팅방 화면이 바뀌어도 유지, 로그아웃 초기화 시 리셋
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('처음엔 미노출 > markShown 후 노출 기록 유지 (다른 채팅방 화면도 같은 값)', () {
    expect(container.read(chatNotificationGuideProvider), isFalse);

    container.read(chatNotificationGuideProvider.notifier).markShown();

    expect(container.read(chatNotificationGuideProvider), isTrue);
  });

  test('세션 종료 초기화 > 다음 로그인 세션에서 다시 1회 노출', () {
    container.read(chatNotificationGuideProvider.notifier).markShown();

    invalidateUserScopedProviders(container.invalidate);

    expect(container.read(chatNotificationGuideProvider), isFalse);
  });
}
