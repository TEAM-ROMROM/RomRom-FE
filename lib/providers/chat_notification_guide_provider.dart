import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 채팅 알림 꺼짐 안내 시트 이번 로그인 세션 노출 여부 (true: 이미 노출 > 다른 채팅방 진입에도 다시 안 띄움)
/// 채팅방 화면마다 기억하면 알림 끈 회원에게 매 진입 노출 > 세션 단위로 provider가 소유 (로그아웃 시 초기화)
class ChatNotificationGuideNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// 노출 기록 (시트 띄우기 직전 호출 > 동시 진입 중복 노출 방지)
  void markShown() => state = true;
}

final chatNotificationGuideProvider = NotifierProvider<ChatNotificationGuideNotifier, bool>(
  ChatNotificationGuideNotifier.new,
);
