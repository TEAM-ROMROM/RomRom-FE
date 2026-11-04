import 'package:romrom_fe/services/chat_member_status_poller.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';

/// 세션 종료 시 회원 단위 자원 정리 3개: 하트비트 중단 > 상대 접속 상태 폴러 중단 > 채팅 웹소켓 해제
/// 모두 멱등 (로그아웃·탈퇴의 기존 정리와 겹쳐도 안전)
Future<void> releaseUserSessionResources() async {
  HeartbeatManager.instance.stop();
  ChatMemberStatusPoller.instance.stopAll();
  await ChatWebSocketService().disconnect();
}
