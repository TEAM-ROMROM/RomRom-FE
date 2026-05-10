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
}
