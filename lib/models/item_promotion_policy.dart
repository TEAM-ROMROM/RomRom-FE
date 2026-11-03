/// 우선노출(롬업) 정책 값 단일 원본: 안내 문구·결과 토스트 공용
class ItemPromotionPolicy {
  const ItemPromotionPolicy._();

  // 회원당 하루 우선노출 가능 횟수 (KST 기준, 서버 ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED)
  static const int dailyLimitCount = 3;
}
