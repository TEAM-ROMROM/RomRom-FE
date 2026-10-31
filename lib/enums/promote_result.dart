import 'package:romrom_fe/enums/snack_bar_type.dart';

/// 우선노출(롬업) 시도 결과 > 토스트 문구·종류 (문구 null > 토스트 없음)
/// notifier는 결과만 반환, 화면은 이 값으로 토스트 표시 (notifier의 UI 의존 차단)
enum PromoteResult {
  // 광고 보상 + 서버 활성화 성공
  success('내 물건이 우선 노출돼요 ⚡', SnackBarType.success),
  // 광고 시청 중 이탈 (보상 미적립)
  adNotEarned('광고를 끝까지 시청해야 적립돼요', SnackBarType.info),
  // 광고 단위 미설정·로드 실패·표시 실패
  adUnavailable('지금은 광고를 불러올 수 없어요. 잠시 후 다시 시도해주세요', SnackBarType.error),
  // 409 ITEM_PROMOTION_ALREADY_ACTIVE (같은 물품 24시간 내 재요청)
  alreadyPromoted('이미 노출 중인 물품이에요', SnackBarType.info),
  // 429 ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED (회원당 하루 3회, KST)
  dailyLimitExceeded('오늘은 우선 노출을 모두 사용했어요 (하루 3회)', SnackBarType.info),
  // 400 ITEM_NOT_PROMOTABLE (교환 불가·차단 물품)
  notPromotable('교환 가능한 물품만 노출할 수 있어요', SnackBarType.error),
  // 그 외 실패 (404·403·네트워크 등)
  failed('잠시 후 다시 시도해주세요', SnackBarType.error),
  // 동일 itemId 처리 중 > 중복 무시
  alreadyInFlight(null, null);

  const PromoteResult(this.toastMessage, this.toastType);

  final String? toastMessage;
  final SnackBarType? toastType;
}
