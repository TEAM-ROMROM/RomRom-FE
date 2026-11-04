import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/open_chat_room_registry.dart';

/// 열린 채팅방 화면 목록 (#984): 같은 방 푸시 탭 중복 열기 방지, 같은 방 다른 화면 생존 판정
void main() {
  late OpenChatRoomRegistry registry;
  final Object lowerScreen = Object();
  final Object upperScreen = Object();

  setUp(() => registry = OpenChatRoomRegistry());

  test('같은 방이 맨 위에 보이면 isShowingOnTop true, 다른 화면에 가려지면 false', () {
    var isRoomRouteCurrent = true;
    registry.register(owner: lowerScreen, chatRoomId: 'room-a', isRouteCurrent: () => isRoomRouteCurrent);

    expect(registry.isShowingOnTop('room-a'), isTrue);
    expect(registry.isShowingOnTop('room-b'), isFalse);

    isRoomRouteCurrent = false;
    expect(registry.isShowingOnTop('room-a'), isFalse);
  });

  test('닫힌 화면 해제 > 더 이상 맨 위 아님', () {
    registry.register(owner: lowerScreen, chatRoomId: 'room-a', isRouteCurrent: () => true);
    registry.unregister(owner: lowerScreen);

    expect(registry.isShowingOnTop('room-a'), isFalse);
  });

  test('같은 방 화면 2개 > 서로 다른 화면 열림으로 판정, 하나 닫히면 해제', () {
    registry.register(owner: lowerScreen, chatRoomId: 'room-a', isRouteCurrent: () => false);
    registry.register(owner: upperScreen, chatRoomId: 'room-a', isRouteCurrent: () => true);

    expect(registry.hasOtherOpenScreen(chatRoomId: 'room-a', owner: upperScreen), isTrue);

    registry.unregister(owner: lowerScreen);
    expect(registry.hasOtherOpenScreen(chatRoomId: 'room-a', owner: upperScreen), isFalse);
  });
}
