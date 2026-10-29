import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';

/// 로그인 회원별 상태를 가진 provider 목록 (세션 종료 시 전부 초기화, 새 provider는 여기에 추가)
/// repository provider는 상태 없음 > 제외
final List<ProviderOrFamily> userScopedProviders = [
  myItemsProvider,
  memberProfileProvider,
  chatRoomsProvider,
  notificationListProvider,
  notificationSettingProvider,
  itemLikeProvider,
  memberBlockProvider,
  tradeRequestsProvider,
  homeFeedProvider,
  currentTabIndexProvider,
  coachMarkTriggerProvider,
];

/// 사용자 범위 provider 전부 무효화 (WidgetRef·ProviderContainer의 invalidate 전달)
void invalidateUserScopedProviders(void Function(ProviderOrFamily provider) invalidate) {
  for (final provider in userScopedProviders) {
    invalidate(provider);
  }
}
