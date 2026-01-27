import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/utils/item_card_scale_utils.dart';
import 'package:romrom_fe/widgets/item_card_option_chip.dart';

/// 물품 카드 위젯
class ItemCard extends ConsumerWidget {
  final String itemId; // 각 물품의 고유 ID
  final String itemCategoryLabel; // 카테고리 라벨
  final String itemName; // 물품 이름
  final String itemCardImageUrl; // 이미지 URL
  final List<ItemTradeOption> itemOptions;
  final bool isSmall; // 작은 카드 여부
  final Function(ItemTradeOption)? onOptionSelected; // 선택된 옵션 반환 콜백 추가

  const ItemCard({
    super.key,
    required this.itemId,
    this.itemCategoryLabel = '물품 카테고리',
    this.itemName = '물품 이름',
    this.itemCardImageUrl = 'https://picsum.photos/400/300',
    this.itemOptions = const [ItemTradeOption.additionalPrice, ItemTradeOption.directTradeOnly, ItemTradeOption.deliveryOnly],
    this.isSmall = false,
    this.onOptionSelected, // 콜백 초기화
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = itemCardProvider(itemId);
    final asyncState = ref.watch(provider);

    return asyncState.when(
      data: (state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // constraints를 기반으로 로컬 스케일 계산
            final cs = ItemCardScale(constraints.maxWidth / 310.0);

            final imageHeight = cs.s(350);
            final cardRadius = isSmall ? cs.radius(4) : cs.radius(10);
            final borderWidth = cs.s(4);
            final itemNameLabelPadding = cs.padding(14, 12);
            final optionPadding = cs.padding(14, 10);
            final optionRadius = cs.radius(6);
            final boxMargin = cs.margin(t: 3, b: 4, r: 4, l: 4);

            final Color optionChipColor = isSmall ? AppColors.textColorBlack : AppColors.itemCardOptionChip;
            final Color optionChipSelectedColor = isSmall ? AppColors.textColorBlack : AppColors.primaryYellow;
            final Color optionChipTextColor = isSmall ? AppColors.textColorWhite : AppColors.textColorWhite;
            final Color optionChipSelectedTextColor = isSmall ? AppColors.textColorWhite : AppColors.textColorBlack;

            // 텍스트 스타일 (작은 카드에서는 축소)
            final double smallTextScale = isSmall ? 0.9 : 1.0;
            final categoryTextStyle = CustomTextStyles.p3.copyWith(fontSize: cs.fontSize(CustomTextStyles.p3.fontSize! * smallTextScale), color: AppColors.itemCardNameText.withValues(alpha: 0.5));

            final nameTextStyle = CustomTextStyles.p1.copyWith(fontSize: cs.fontSize(CustomTextStyles.p1.fontSize! * (isSmall ? 0.8 : 1.0)), color: AppColors.itemCardNameText);

            final optionTextStyle = CustomTextStyles.p3.copyWith(fontSize: cs.fontSize(CustomTextStyles.p3.fontSize! * smallTextScale), color: AppColors.itemCardNameText.withValues(alpha: 0.5));

            return AspectRatio(
              aspectRatio: 310 / 496,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: cs.s(30), sigmaY: cs.s(30)),
                  child: Container(
                    width: constraints.maxWidth,
                    decoration: buildBoxDecoration(AppColors.itemCardBackground, cardRadius).copyWith(
                      border: Border.all(color: AppColors.itemCardBorder, width: borderWidth),
                      boxShadow: const [BoxShadow(color: AppColors.itemCardShadow, offset: Offset(4, 4), blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 이미지 영역
                        SizedBox(
                          height: imageHeight,
                          child: AspectRatio(
                            aspectRatio: 31 / 35,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(topLeft: cardRadius.topLeft, topRight: cardRadius.topRight),
                              child: _buildImage(itemCardImageUrl, cs),
                            ),
                          ),
                        ),
                        // 정보 및 옵션 영역
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카테고리, 이름
                            Padding(
                              padding: itemNameLabelPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemCategoryLabel, style: categoryTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  cs.sizedBoxH(8),
                                  Text(itemName, style: nameTextStyle, maxLines: isSmall ? 1 : 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            // 옵션 선택 영역
                            Container(
                              width: double.infinity,
                              margin: boxMargin,
                              constraints: BoxConstraints(minHeight: cs.s(60), maxHeight: cs.s(75)),
                              decoration: buildBoxDecoration(Colors.white.withValues(alpha: 0.3), optionRadius),
                              child: Padding(
                                padding: optionPadding,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('요청 옵션', style: optionTextStyle),
                                    cs.sizedBoxH(8),
                                    Flexible(
                                      child: Wrap(
                                        spacing: cs.s(8),
                                        runSpacing: cs.s(4),
                                        children: itemOptions
                                            .map(
                                              (option) => ItemCardOptionChip(
                                                itemId: itemId,
                                                itemOption: option,
                                                chipColor: optionChipColor,
                                                chipSelectedColor: optionChipSelectedColor,
                                                chipTextColor: optionChipTextColor,
                                                chipSelectedTextColor: optionChipSelectedTextColor,
                                                externalScale: cs,
                                                onTap: () {
                                                  if (onOptionSelected != null) {
                                                    onOptionSelected!(option); // 선택된 옵션 반환
                                                  }
                                                },
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('에러 발생: $err')),
    );
  }

  /// 이미지 로더: 네트워크 이미지 실패 시 경고 아이콘 포함 그레이 배경 플레이스홀더 표시
  Widget _buildImage(String url, ItemCardScale cs) {
    const placeholder = ErrorImagePlaceholder();

    if (url.trim().isEmpty) {
      return placeholder;
    }

    return CachedImage(
      imageUrl: url.trim(),
      fit: BoxFit.cover,
      errorWidget: placeholder,
    );
  }
}
