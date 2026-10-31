import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/widgets/register_input_form/register_category_field.dart';
import 'package:romrom_fe/widgets/register_input_form/register_image_picker_section.dart';
import 'package:romrom_fe/widgets/register_input_form/register_option_selector.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (기준 화면 크기·ScreenUtil 초기화 포함)
Future<void> pumpRegisterSection(WidgetTester tester, Widget registerSection) async {
  useDesignScreenView(tester);

  await tester.pumpWidget(buildDesignScreenApp(home: Scaffold(body: registerSection)));
}

/// 칩 선택 표시 여부 (라벨 기준)
bool isChipSelected(WidgetTester tester, String label) {
  return tester.widget<RegisterOptionChip>(find.widgetWithText(RegisterOptionChip, label)).isSelected;
}

void main() {
  group('RegisterOptionSelector', () {
    testWidgets('옵션 전부 칩 표시, 선택값만 선택 표시, 탭 > 해당 옵션 전달', (tester) async {
      final List<ItemTradeOption> tappedOptions = [];
      await pumpRegisterSection(
        tester,
        RegisterOptionSelector<ItemTradeOption>(
          options: ItemTradeOption.values,
          selectedOptions: const [ItemTradeOption.directTradeOnly],
          labelOf: (option) => option.label,
          onOptionTap: tappedOptions.add,
          shouldShowError: true,
          errorText: ItemTextFieldPhrase.tradeOption.errorText,
        ),
      );

      expect(find.byType(RegisterOptionChip), findsNWidgets(ItemTradeOption.values.length));
      expect(isChipSelected(tester, ItemTradeOption.directTradeOnly.label), isTrue);
      expect(isChipSelected(tester, ItemTradeOption.deliveryOnly.label), isFalse);
      // 선택값 있으면 오류 문구 없음
      expect(find.text(ItemTextFieldPhrase.tradeOption.errorText), findsNothing);

      await tester.tap(find.text(ItemTradeOption.deliveryOnly.label));
      expect(tappedOptions, [ItemTradeOption.deliveryOnly]);
    });

    testWidgets('미선택 + 오류 표시 조건 > 오류 문구, 조건 아니면 숨김', (tester) async {
      Widget buildConditionSelector({required bool shouldShowError}) => RegisterOptionSelector<ItemCondition>(
        options: ItemCondition.values,
        selectedOptions: const [],
        labelOf: (option) => option.label,
        onOptionTap: (_) {},
        shouldShowError: shouldShowError,
        errorText: ItemTextFieldPhrase.condition.errorText,
      );

      await pumpRegisterSection(tester, buildConditionSelector(shouldShowError: false));
      expect(find.text(ItemTextFieldPhrase.condition.errorText), findsNothing);

      await pumpRegisterSection(tester, buildConditionSelector(shouldShowError: true));
      expect(find.text(ItemTextFieldPhrase.condition.errorText), findsOneWidget);
    });
  });

  group('RegisterCategoryField', () {
    testWidgets('미선택 > 안내 문구·오류 문구, 선택 > 카테고리 이름, 탭 > 콜백', (tester) async {
      int tapCount = 0;
      await pumpRegisterSection(
        tester,
        RegisterCategoryField(selectedCategory: null, shouldShowError: true, onTap: () => tapCount++),
      );
      expect(find.text(ItemTextFieldPhrase.category.hintText), findsOneWidget);
      expect(find.text(ItemTextFieldPhrase.category.errorText), findsOneWidget);

      await tester.tap(find.text(ItemTextFieldPhrase.category.hintText));
      expect(tapCount, 1);

      final ItemCategories selectedCategory = ItemCategories.values.first;
      await pumpRegisterSection(
        tester,
        RegisterCategoryField(selectedCategory: selectedCategory, shouldShowError: true, onTap: () {}),
      );
      expect(find.text(selectedCategory.label), findsOneWidget);
      expect(find.text(ItemTextFieldPhrase.category.errorText), findsNothing);
    });
  });

  group('RegisterImagePickerSection', () {
    testWidgets('사진 0장 > 0/10·안내 문구, 추가 버튼 탭 > 콜백', (tester) async {
      int addTapCount = 0;
      await pumpRegisterSection(
        tester,
        RegisterImagePickerSection(
          existingImageUrls: const [],
          newImagePaths: const [],
          shouldShowEmptyImageError: true,
          onAddImageTap: () => addTapCount++,
          onImageTap: (_) {},
          onDeleteImageTap: (_) {},
        ),
      );

      expect(find.text('0/10'), findsOneWidget);
      expect(find.text('상품 사진을 최소 1장 이상 등록해주세요'), findsOneWidget);

      await tester.tap(find.text('0/10'));
      expect(addTapCount, 1);
    });
  });
}
