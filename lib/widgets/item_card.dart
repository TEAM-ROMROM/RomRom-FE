import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/utils/item_card_scale_utils.dart';
import 'package:romrom_fe/widgets/item_card_option_chip.dart';

/// 물품 카드 위젯
class ItemCard extends ConsumerWidget {
  final String itemId; // 각 물품의 고유 ID
  final String itemCategoryLabel; // 카테고리 라벨
  final String itemName; // 물품 이름
  final String itemCardImageUrl; // 이미지 URL
  final List<ItemTradeOption> itemOptions;

  const ItemCard({
    super.key,
    required this.itemId,
    this.itemCategoryLabel = '물품 카테고리',
    this.itemName = '물품 이름',
    this.itemCardImageUrl = 'https://picsum.photos/400/300',
    this.itemOptions = const [ItemTradeOption.extraCharge, ItemTradeOption.directOnly, ItemTradeOption.deliveryOnly],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = itemCardProvider(itemId);
    final asyncState = ref.watch(provider);

    return asyncState.when(
      data: (state) {
        final cs = state.scale;

        final imageHeight = cs.s(350);
        final cardRadius = cs.radius(10);
        final borderWidth = cs.s(4);
        final itemNameLabelPadding = cs.padding(18, 12);
        final optionPadding = cs.padding(14, 10);
        final optionHeight = cs.s(75);
        final optionRadius = cs.radius(6);
        final boxMargin = cs.margin(t: 3, b: 4, r: 4, l: 4);

        // 물품 카테고리 text 스타일
        final categoryTextStyle = CustomTextStyles.p2.copyWith(
          fontSize: cs.fontSize(CustomTextStyles.p2.fontSize!),
          color: AppColors.itemCardText.withValues(alpha: 0.5),
        );

        // 물품 이름 text 스타일
        final nameTextStyle = CustomTextStyles.p1.copyWith(
          fontSize: cs.fontSize(CustomTextStyles.p1.fontSize!),
          color: AppColors.itemCardText,
        );

        // 옵션 선택 text 스타일
        final optionTextStyle = CustomTextStyles.p3.copyWith(
          fontSize: cs.fontSize(CustomTextStyles.p3.fontSize!),
          color: AppColors.itemCardText.withValues(alpha: 0.5),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            // LayoutBuilder로 카드의 width 측정 후 scale 설정
            // 현재 값과 비교해서 바뀔 때만 호출
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final newScale = constraints.maxWidth / 310.0;
              if (cs.scale != newScale) {
                ref
                    .read(provider.notifier)
                    .setScale(310.0, constraints.maxWidth);
              }
            });

            return ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: cs.s(30),
                  sigmaY: cs.s(30),
                ),
                child: Container(
                  width: constraints.maxWidth,
                  decoration: buildBoxDecoration(
                          AppColors.itemCardBackground, cardRadius)
                      .copyWith(
                    border: Border.all(
                      color: AppColors.itemCardBorder,
                      width: borderWidth,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.itemCardShadow,
                        offset: Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 이미지 영역
                      SizedBox(
                        height: imageHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: cardRadius.topLeft,
                              topRight: cardRadius.topRight),
                          child: _buildImage(itemCardImageUrl, cs),
                        ),
                      ),
                      // 정보 및 옵션 영역
                      SizedBox(
                        height: cs.s(146),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카테고리, 이름
                            Padding(
                              padding: itemNameLabelPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemCategoryLabel,
                                      style: categoryTextStyle),
                                  cs.sizedBoxH(8),
                                  Text(itemName, style: nameTextStyle),
                                ],
                              ),
                            ),
                            // 옵션 선택 영역
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                margin: boxMargin,
                                height: optionHeight,
                                decoration: buildBoxDecoration(
                                    Colors.white.withValues(alpha: 0.3),
                                    optionRadius),
                                child: Padding(
                                  padding: optionPadding,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('요청 옵션', style: optionTextStyle),
                                      cs.sizedBoxH(10),
                                      Expanded(
                                        child: Wrap(
                                          spacing: cs.s(10),
                                          children: itemOptions
                                              .map((option) =>
                                                  ItemCardOptionChip(
                                                    itemId: itemId,
                                                    itemOption: option,
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
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

    final String finalUrl = url.trim();

    return Image.network(
      finalUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('ItemCard 이미지 로드 실패: $finalUrl, error: $error');
        return placeholder;
      },
    );
  }
}
