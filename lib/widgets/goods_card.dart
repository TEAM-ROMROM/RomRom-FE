import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/goods_card_scale_utils.dart';
import 'package:romrom_fe/widgets/goods_card_option_chip.dart';

class GoodsCard extends StatelessWidget {
  final String goodsCategoryLabel;
  final String goodsName;
  final List<String> goodsOptions;
  final String goodsCardImageUrl;

  const GoodsCard({
    super.key,
    this.goodsCategoryLabel = '물품 카테고리',
    this.goodsName = '물품 이름',
    this.goodsOptions = const ['추가금', '직거래', '택배'],
    this.goodsCardImageUrl = 'https://picsum.photos/400/300',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<GoodsCardScaleProvider>().setScale(310.0, cardWidth);
        });
        // 비율 설정
        final cs = context.watch<GoodsCardScaleProvider>().scale;

        return ClipRRect(
          borderRadius: cs.radius(10),
          child: Padding(
            padding: cs.padding(4, 4),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: cs.s(30),
                sigmaY: cs.s(30),
              ),
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: AppColors.goodsCardBackground,
                  borderRadius: cs.radius(10),
                  border: Border.all(
                    color: AppColors.goodsCardBorder,
                    width: cs.s(4),
                    style: BorderStyle.solid,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.goodsCardShadow,
                      offset: Offset(4, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: cs.s(350),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(cs.s(10)),
                          topRight: Radius.circular(cs.s(10)),
                        ),
                        child: Image.network(
                          goodsCardImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: cs.s(146),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: cs.padding(18, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  goodsCategoryLabel,
                                  style: CustomTextStyles.p2.copyWith(
                                    fontSize: cs.fontSize(
                                        CustomTextStyles.p2.fontSize!),
                                    color: AppColors.goodsCardText
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                cs.sizedBoxH(8),
                                Text(
                                  goodsName,
                                  style: CustomTextStyles.p1.copyWith(
                                    fontSize: cs.fontSize(
                                        CustomTextStyles.p1.fontSize!),
                                    color: AppColors.goodsCardText,
                                    fontFamily:
                                        FontFamily.nexonLv2Gothic.fontName,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(
                                top: cs.s(3),
                                bottom: cs.s(4),
                                right: cs.s(4),
                                left: cs.s(4)),
                            height: cs.s(75),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF)
                                  .withValues(alpha: 0.3),
                              borderRadius: cs.radius(6),
                            ),
                            child: Padding(
                              padding: cs.padding(14, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '요청 옵션',
                                    style: CustomTextStyles.p3.copyWith(
                                      fontSize: cs.fontSize(
                                          CustomTextStyles.p3.fontSize!),
                                      color: AppColors.goodsCardText
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  cs.sizedBoxH(10),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Wrap(
                                      spacing: cs.s(10), // 가로 간격
                                      children: goodsOptions
                                          .map((option) => GoodsCardOptionChip(
                                              goodsOption: option))
                                          .toList(),
                                    ),
                                  ),
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
          ),
        );
      },
    );
  }
}
