import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';

import '../helpers/pump_design_screen.dart';

/// 물품 상세 조회 항상 실패 (호출 횟수 기록)
class _FailingItemDetailRepository implements ItemRepository {
  int getItemDetailCallCount = 0;

  @override
  Future<ItemResponse> getItemDetail(String? itemId) async {
    getItemDetailCallCount++;
    throw Exception('network down');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ItemModificationScreen 불러오기 실패', () {
    testWidgets('빈 폼·수정 완료 버튼 대신 에러 뷰 + 다시 시도 > 탭 시 재조회', (tester) async {
      useDesignScreenView(tester);
      final itemRepository = _FailingItemDetailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [itemRepositoryProvider.overrideWithValue(itemRepository)],
          child: buildDesignScreenApp(home: const ItemModificationScreen(itemId: 'item-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('물품을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('수정 완료'), findsNothing);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(itemRepository.getItemDetailCallCount, 2);
    });
  });
}
