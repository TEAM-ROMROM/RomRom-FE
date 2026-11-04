import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/services/open_chat_room_registry.dart';

/// 열린 채팅방 화면 목록 주입 (딥링크 라우터·채팅방 화면 공용, 화면이 닫히며 스스로 비움 > 세션 초기화 불필요)
final openChatRoomRegistryProvider = Provider<OpenChatRoomRegistry>((ref) => OpenChatRoomRegistry());
