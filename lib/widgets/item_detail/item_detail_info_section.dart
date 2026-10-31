// 물품 상세 본문: 카테고리·등록 시각, 제목, 사용감·거래 방식 태그, 가격(AI 배지), 설명
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';

class ItemDetailInfoSection extends StatelessWidget {
  final Item item;

  const ItemDetailInfoSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryAndCreatedTime(),
          SizedBox(height: 10.h),
          Text(item.itemName ?? '제목 없음', style: CustomTextStyles.h3),
          SizedBox(height: 16.h),
          _buildTags(),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                '${formatPrice(item.price ?? 0)}원',
                style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8.w),
              if (item.isAiPredictedPrice == true) const AiBadgeWidget(),
            ],
          ),
          SizedBox(height: 24.h),
          Text(item.itemDescription ?? '설명이 없습니다.', style: CustomTextStyles.p2.copyWith(height: 1.4)),
        ],
      ),
    );
  }

  /// 카테고리 · 등록 시각 한 줄
  Widget _buildCategoryAndCreatedTime() {
    return RichText(
      text: TextSpan(
        text: '${_toCategoryLabel(item.itemCategory)} · ',
        style: CustomTextStyles.p3.copyWith(color: AppColors.opacity50White, fontWeight: FontWeight.w400),
        children: [
          TextSpan(
            text: _toCreatedTimeLabel(item.createdDate),
            style: CustomTextStyles.p3.copyWith(color: AppColors.opacity50White, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// 사용감 태그 + 거래 방식 태그 목록
  Widget _buildTags() {
    return Row(
      children: [
        if (ItemCondition.fromServerName(item.itemCondition) case final condition?)
          ItemDetailConditionTag(condition: condition.label),
        SizedBox(width: 4.w),
        if (item.itemTradeOptions?.isNotEmpty == true)
          Expanded(
            child: Wrap(
              spacing: 4.w,
              children: [
                ...item.itemTradeOptions!.map(
                  (option) => ItemDetailTradeOptionTag(option: _toTradeOptionLabel(option)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 카테고리 서버 값 > 표시 이름 (없음·알 수 없음: '카테고리 없음')
  static String _toCategoryLabel(String? serverName) {
    return ItemCategories.fromServerName(serverName)?.label ?? '카테고리 없음';
  }

  /// 거래 방식 서버 값 > 표시 이름 (알 수 없으면 서버 값 그대로)
  static String _toTradeOptionLabel(String serverName) {
    return ItemTradeOption.fromServerName(serverName)?.label ?? serverName;
  }

  /// 등록 시각 > 상대 표기 (N일 전 / N시간 전 / N분 전 / 방금 전)
  static String _toCreatedTimeLabel(DateTime? dateTime) {
    if (dateTime == null) return '날짜 정보 없음';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
