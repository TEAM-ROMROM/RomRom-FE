import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 채팅방별 보내지 않은 입력 글 (채팅방 ID > 입력 글, 메모리 보관 > 로그아웃 시 초기화)
/// 같은 방 재진입 시 복원, 빈 글은 저장하지 않음 (기기 저장 안 함: 개인 대화 내용 잔존 방지)
class ChatInputDraftNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  /// 방의 임시 저장 글 (없으면 빈 문자열)
  String draftOf(String chatRoomId) => state[chatRoomId] ?? '';

  /// 입력 글 저장 (공백뿐이면 삭제, 같은 값이면 상태 유지)
  void saveDraft({required String chatRoomId, required String text}) {
    final hasDraftText = text.trim().isNotEmpty;
    if (!hasDraftText) {
      if (!state.containsKey(chatRoomId)) return;
      state = {...state}..remove(chatRoomId);
      return;
    }
    if (state[chatRoomId] == text) return;
    state = {...state, chatRoomId: text};
  }
}

final chatInputDraftProvider = NotifierProvider<ChatInputDraftNotifier, Map<String, String>>(
  ChatInputDraftNotifier.new,
);
