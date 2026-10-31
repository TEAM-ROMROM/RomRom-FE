// 홈 피드 카드 하단 물품 요약: 이름, 위치·등록일, 사용감·거래 방식 태그, 가격·AI 가격 배지
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_card_layout.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';

/// 홈 피드 물품 요약: 피드 물품 값 표시 전용 (블러는 상위에서 감쌈)
class HomeFeedItemSummary extends StatelessWidget {
  final HomeFeedItem item;
  // 상세 조회 결과 AI 추천 가격이면 배지 표시
  final bool isAiPrice;

  const HomeFeedItemSummary({super.key, required this.item, required this.isAiPrice});

  // 글자 스타일 3개: 이름, 위치·등록일, 가격 (네이티브 광고 카드도 같은 값 사용)
  static TextStyle get titleTextStyle => CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get metaTextStyle => CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get priceTextStyle => CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final String formattedPrice = formatPrice(item.price);
    final String formattedDate = formatDate(item.date);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 물품 이름
        Text(item.name.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: titleTextStyle),

        SizedBox(height: HomeFeedCardLayout.titleToMetaGap),

        // 위치 및 날짜 정보
        Row(
          children: [
            Icon(AppIcons.location, color: AppColors.opacity80White, size: 13.sp),
            SizedBox(width: 4.w),
            Text('${item.location} • $formattedDate', style: metaTextStyle),
          ],
        ),

        SizedBox(height: HomeFeedCardLayout.metaToTagGap),

        Row(
          children: [
            // 사용감 태그 - ItemDetail과 동일한 위젯 사용
            ItemDetailConditionTag(condition: item.itemCondition.label),
            SizedBox(width: 4.w),
            // 거래 방식 태그들 - ItemDetail과 동일한 위젯 사용
            Wrap(
              spacing: 4.w,
              children: item.transactionTypes.map((type) => ItemDetailTradeOptionTag(option: type.label)).toList(),
            ),
          ],
        ),

        SizedBox(height: HomeFeedCardLayout.tagToPriceGap),

        Row(
          children: [
            // 물품 가격
            Text("$formattedPrice원", style: priceTextStyle),

            SizedBox(width: 8.w),

            isAiPrice ? const AiBadgeWidget() : const SizedBox(),
          ],
        ),
      ],
    );
  }
}
