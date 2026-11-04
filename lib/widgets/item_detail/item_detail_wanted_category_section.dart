// 물품 상세 희망 교환 카테고리: 제목 + 카테고리 태그 목록 (없으면 표시 안 함)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/item_wanted_category_policy.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

class ItemDetailWantedCategorySection extends StatelessWidget {
  // 서버 이름 목록 (모르는 값 제외 후 표시)
  final List<String>? wantedCategoryServerNames;

  const ItemDetailWantedCategorySection({super.key, required this.wantedCategoryServerNames});

  @override
  Widget build(BuildContext context) {
    final wantedCategories = ItemCategories.fromServerNamesSkippingUnknown(wantedCategoryServerNames);
    if (wantedCategories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wantedItemCategoryTitle, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final wantedCategory in wantedCategories)
                AppTag(
                  label: wantedCategory.label,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppColors.opacity10White,
                  borderRadius: 100.r,
                  textStyle: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
