import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class NotificationSettingRepository {
  final MemberApi _api;

  NotificationSettingRepository(this._api);

  Future<void> update(NotificationSettingType type, bool value) async {
    await _api.updateNotificationSetting(
      isMarketingInfoAgreed: type == NotificationSettingType.marketing ? value : null,
      isActivityNotificationAgreed: type == NotificationSettingType.activity ? value : null,
      isChatNotificationAgreed: type == NotificationSettingType.chat ? value : null,
      isContentNotificationAgreed: type == NotificationSettingType.content ? value : null,
      isTradeNotificationAgreed: type == NotificationSettingType.transaction ? value : null,
    );
  }

  /// 여러 항목 일괄 변경: 요청 1회 (맵에 없는 항목은 null = 변경 없음)
  Future<void> updateAll(Map<NotificationSettingType, bool> values) async {
    await _api.updateNotificationSetting(
      isMarketingInfoAgreed: values[NotificationSettingType.marketing],
      isActivityNotificationAgreed: values[NotificationSettingType.activity],
      isChatNotificationAgreed: values[NotificationSettingType.chat],
      isContentNotificationAgreed: values[NotificationSettingType.content],
      isTradeNotificationAgreed: values[NotificationSettingType.transaction],
    );
  }
}
