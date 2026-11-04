import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/services/notification_permission_prompt_service.dart';

/// NotificationPermissionPromptService 주입 (안내 진행 중 상태 공유, 테스트 override)
final notificationPermissionPromptServiceProvider = Provider<NotificationPermissionPromptService>(
  (ref) => NotificationPermissionPromptService(),
);
