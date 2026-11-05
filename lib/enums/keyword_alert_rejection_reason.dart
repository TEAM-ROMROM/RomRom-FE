import 'package:romrom_fe/utils/keyword_alert_rules.dart';

/// 키워드 알림 등록 거부 사유 4개: 짧음, 김, 이미 등록, 개수 초과 (서버 정책과 동일, BE #873)
enum KeywordAlertRejectionReason {
  tooShort,
  tooLong,
  alreadyRegistered,
  limitReached;

  /// 사유 > 안내 문구 (개수 초과는 서버가 준 최대 개수 사용)
  String buildMessage({required int maximumKeywordAlertCount}) {
    switch (this) {
      case KeywordAlertRejectionReason.tooShort:
        return '키워드는 $minimumKeywordAlertLength자 이상 입력해 주세요';
      case KeywordAlertRejectionReason.tooLong:
        return '키워드는 $maximumKeywordAlertLength자까지 입력할 수 있어요';
      case KeywordAlertRejectionReason.alreadyRegistered:
        return '이미 등록한 키워드예요';
      case KeywordAlertRejectionReason.limitReached:
        return '키워드는 최대 $maximumKeywordAlertCount개까지 등록할 수 있어요';
    }
  }
}
