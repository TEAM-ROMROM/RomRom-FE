import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/chat_input_draft_provider.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';

/// 채팅방별 입력 임시 저장 (#987): 방마다 따로 보관, 빈 글 삭제, 로그아웃 초기화
void main() {
  late ProviderContainer container;
  ChatInputDraftNotifier draftNotifier() => container.read(chatInputDraftProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('방마다 따로 저장 > 같은 방 재진입 시 그 방 글만 복원', () {
    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '내일 2시 어때요?');
    draftNotifier().saveDraft(chatRoomId: 'room-b', text: '사진 더 있나요');

    expect(draftNotifier().draftOf('room-a'), '내일 2시 어때요?');
    expect(draftNotifier().draftOf('room-b'), '사진 더 있나요');
    expect(draftNotifier().draftOf('room-c'), isEmpty);
  });

  test('보내서 입력창이 비면(공백 포함) 임시 저장 삭제', () {
    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '안녕하세요');
    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '   ');

    expect(container.read(chatInputDraftProvider).containsKey('room-a'), isFalse);
  });

  test('같은 글 다시 저장 > 상태 객체 유지 (구독자 불필요한 알림 없음)', () {
    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '안녕');
    final stateBefore = container.read(chatInputDraftProvider);

    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '안녕');

    expect(identical(container.read(chatInputDraftProvider), stateBefore), isTrue);
  });

  test('로그아웃(세션 초기화) > 모든 방 임시 저장 삭제 (다음 계정에 노출 방지)', () {
    draftNotifier().saveDraft(chatRoomId: 'room-a', text: '개인 대화');

    invalidateUserScopedProviders(container.invalidate);

    expect(container.read(chatInputDraftProvider), isEmpty);
    expect(draftNotifier().draftOf('room-a'), isEmpty);
  });
}
