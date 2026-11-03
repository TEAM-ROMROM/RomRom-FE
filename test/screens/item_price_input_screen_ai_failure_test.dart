import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/screens/item_price_input_screen.dart';

import '../helpers/pump_design_screen.dart';

/// AI 가격 예측: 실패 모드면 throw, 아니면 [predictedPrice] 반환
class _PricePredictingItemRepository implements ItemRepository {
  bool isFailing = true;
  int predictedPrice = 30000;
  int predictPriceCallCount = 0;

  @override
  Future<int> predictPrice({required String itemName, required String itemDescription, String? itemCondition}) async {
    predictPriceCallCount++;
    if (isFailing) throw Exception('network down');
    return predictedPrice;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 가격 입력 화면을 버튼으로 띄움 (완료 시 pop 대상 확보), 선택 결과 기록
Future<List<(int, bool)>> pumpPriceInputScreen(WidgetTester tester, ItemRepository itemRepository) async {
  useDesignScreenView(tester);
  final selectedPrices = <(int, bool)>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [itemRepositoryProvider.overrideWithValue(itemRepository)],
      child: buildDesignScreenApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ItemPriceInputScreen(
                    initialPrice: 5000,
                    initialUseAiPrice: false,
                    canUseAiPrice: true,
                    itemName: '의자',
                    itemDescription: '튼튼한 원목 의자입니다',
                    itemCondition: 'SLIGHTLY_USED',
                    onPriceSelected: (price, isAiPrice) => selectedPrices.add((price, isAiPrice)),
                  ),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return selectedPrices;
}

/// AI 토글 켜기 > 요청 완료까지 대기
Future<void> turnOnAiPriceToggle(WidgetTester tester) async {
  await tester.tap(find.byType(AnimatedToggleSwitch<bool>));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  group('ItemPriceInputScreen AI 가격 실패', () {
    testWidgets('예측 실패 > 토글 꺼짐, 완료 시 직접 입력 가격으로 전달 (AI 아님)', (tester) async {
      final itemRepository = _PricePredictingItemRepository();
      final selectedPrices = await pumpPriceInputScreen(tester, itemRepository);

      await turnOnAiPriceToggle(tester);
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();

      expect(itemRepository.predictPriceCallCount, 1);
      expect(selectedPrices, [(5000, false)]);
    });

    testWidgets('예측 실패 후 다시 켜면 재요청 (진행 중 표시 해제)', (tester) async {
      final itemRepository = _PricePredictingItemRepository();
      final selectedPrices = await pumpPriceInputScreen(tester, itemRepository);

      await turnOnAiPriceToggle(tester);
      itemRepository.isFailing = false;
      await turnOnAiPriceToggle(tester);
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();

      expect(itemRepository.predictPriceCallCount, 2);
      expect(selectedPrices, [(30000, true)]);
    });
  });
}
