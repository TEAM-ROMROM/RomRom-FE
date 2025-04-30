import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/goods_card_option_chip.dart';

// 물품 카드 위젯
class GoodsCard extends StatelessWidget {
  final String goodsCategoryLabel;
  final String goodsName;
  final List<String> goodsOptions;
  final String goodsCardImageUrl;

  final int width; // 카드 가로 길이
  const GoodsCard(
      {super.key,
      this.goodsCategoryLabel = '물품 카테고리',
      this.goodsName = '물품 이름',
      this.goodsOptions = const ['옵션1', '옵션2', '옵션3'],
      this.goodsCardImageUrl = 'https://picsum.photos/400/300', // 매번 다른 랜덤 이미지

      this.width = 310});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: 310 / 496,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.goodsCardBackground,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.goodsCardBorder,
              style: BorderStyle.solid,
              strokeAlign: BorderSide.strokeAlignOutside,
              width: 4.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goodsCardShadow,
                offset: Offset(0, 4.h),
                blurRadius: 4.r,
              ),
            ],
          ),
          child: Column(
            children: [
              Flexible(
                flex: 350,
                fit: FlexFit.tight,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    topRight: Radius.circular(10.r),
                  ),
                  child: Image.network(
                    goodsCardImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250.h,
                  ),
                ),
              ),
              Flexible(
                flex: 146,
                fit: FlexFit.tight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            goodsCategoryLabel,
                            style: CustomTextStyles.p2.copyWith(
                              color: AppColors.goodsCardText
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            goodsName,
                            style: CustomTextStyles.p1.copyWith(
                              color: AppColors.goodsCardText,
                              fontFamily: FontFamily.nexonLv2Gothic.fontName,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                          top: 3.0, bottom: 4.0, right: 4.0, left: 4.0),
                      height: 75.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '요청 옵션',
                              style: CustomTextStyles.p3.copyWith(
                                color: AppColors.goodsCardText
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  spacing: 10, // 가로 간격
                                  runSpacing: 8, // 줄바꿈 시 간격 (필요한 경우)
                                  children: goodsOptions
                                      .map((option) => GoodsCardOptionChip(
                                          goodsOption: option))
                                      .toList(),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
