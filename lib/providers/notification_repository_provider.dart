import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/notification_repository.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';

/// NotificationRepository 주입용 Provider (테스트 override 지점)
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(NotificationApi()),
);
