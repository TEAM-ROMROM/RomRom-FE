import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';

/// 딥링크 게이트: 메인 진입 전 보관 > 메인 진입 시 1회 전달, 진입 후 즉시 전달, 세션 종료 시 닫힘
void main() {
  late DeepLinkGate gate;

  final sharedItemLink = PendingDeepLink(uri: Uri.parse('https://romrom-c4008.web.app/item?itemId=A'));
  final chatPushLink = PendingDeepLink(
    uri: Uri.parse('romrom://chat/room?chatRoomId=C'),
    notificationType: NotificationType.chatMessageReceived,
  );

  setUp(() => gate = DeepLinkGate());

  test('메인 진입 전 수신 > 보관 (바로 열지 않음)', () {
    expect(gate.receive(sharedItemLink), isNull);
    expect(gate.hasPendingDeepLink, isTrue);
  });

  test('메인 진입 > 보관 링크 1회 전달 후 비움', () {
    gate.receive(sharedItemLink);

    expect(gate.enterMainScreen(), sharedItemLink);
    expect(gate.hasPendingDeepLink, isFalse);
    expect(gate.enterMainScreen(), isNull);
  });

  test('메인 진입 후 수신 > 바로 열 링크로 반환', () {
    gate.enterMainScreen();

    expect(gate.receive(chatPushLink), chatPushLink);
    expect(gate.hasPendingDeepLink, isFalse);
  });

  test('세션 종료(로그아웃·만료·정지) > 다시 보관 모드', () {
    gate.enterMainScreen();
    gate.leaveMainScreen();

    expect(gate.isMainScreenEntered, isFalse);
    expect(gate.receive(chatPushLink), isNull);
  });

  test('메인 진입 전 세션 종료(온보딩 이탈·시작 실패 탈출) > 보관 링크 유지', () {
    gate.receive(sharedItemLink);
    gate.leaveMainScreen();

    expect(gate.enterMainScreen(), sharedItemLink);
  });

  test('알림 링크 보관 중 일반 링크 수신 > 알림 링크 유지', () {
    gate.receive(chatPushLink);
    gate.receive(sharedItemLink);

    expect(gate.enterMainScreen(), chatPushLink);
  });

  test('일반 링크 보관 중 알림 링크 수신 > 알림 링크로 교체', () {
    gate.receive(sharedItemLink);
    gate.receive(chatPushLink);

    expect(gate.enterMainScreen(), chatPushLink);
  });
}
