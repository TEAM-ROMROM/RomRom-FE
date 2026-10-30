import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/screens/item_price_input_screen.dart';
import 'package:romrom_fe/widgets/register_input_form/ai_price_analyzing_field.dart';
import '../../helpers/pump_design_screen.dart';

// 가격 필드 대역 키 (높이 비교용)
const Key priceFieldKey = Key('priceField');

// 페이드 전환 완료 대기 (전환 시간 + 여유 1프레임)
const Duration fadeSettleDuration = Duration(milliseconds: 350);

/// AI 가격 예측: [pendingPrice] 완료까지 대기 (로딩 상태 재현)
class _PendingPriceItemRepository implements ItemRepository {
  final Completer<int> pendingPrice = Completer<int>();

  @override
  Future<int> predictPrice({required String itemName, required String itemDescription, String? itemCondition}) {
    return pendingPrice.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 분석 상태별 테스트 앱 (가격 필드 대역: 고정 높이 박스)
Widget buildAnalyzingFieldApp({required bool isAnalyzing}) {
  return buildDesignScreenApp(
    home: Scaffold(
      body: Column(
        children: [
          AiPriceAnalyzingField(
            isAnalyzing: isAnalyzing,
            priceField: const SizedBox(key: priceFieldKey, height: 50, child: TextField()),
          ),
        ],
      ),
    ),
  );
}

/// 가격 필드를 감싼 페이드 투명도
double priceFieldOpacity(WidgetTester tester) {
  final Finder fieldFadeFinder = find.descendant(
    of: find.byType(AiPriceAnalyzingField),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(fieldFadeFinder.first).opacity;
}

/// 가격 필드 입력 차단 여부
bool isPriceFieldIgnoringPointer(WidgetTester tester) {
  return tester
      .widget<IgnorePointer>(find.ancestor(of: find.byKey(priceFieldKey), matching: find.byType(IgnorePointer)).first)
      .ignoring;
}

void main() {
  group('AiPriceAnalyzingField', () {
    testWidgets('분석 중 > 분석 문구 표시, 필드 숨김·입력 차단, 높이는 필드와 동일', (tester) async {
      useDesignScreenView(tester);
      await tester.pumpWidget(buildAnalyzingFieldApp(isAnalyzing: true));
      await tester.pump(fadeSettleDuration);

      expect(find.text(AiPriceAnalyzingField.analyzingMessage), findsOneWidget);
      expect(priceFieldOpacity(tester), 0);
      expect(isPriceFieldIgnoringPointer(tester), isTrue);
      expect(
        tester.getSize(find.byType(AiPriceAnalyzingField)).height,
        tester.getSize(find.byKey(priceFieldKey)).height,
      );
      // 분석 중 반복 애니메이션 동작
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('분석 끝 > 분석 문구 제거, 필드 표시, 반복 애니메이션 정지', (tester) async {
      useDesignScreenView(tester);
      await tester.pumpWidget(buildAnalyzingFieldApp(isAnalyzing: true));
      await tester.pump(fadeSettleDuration);

      await tester.pumpWidget(buildAnalyzingFieldApp(isAnalyzing: false));
      await tester.pump(fadeSettleDuration);

      expect(find.text(AiPriceAnalyzingField.analyzingMessage), findsNothing);
      expect(priceFieldOpacity(tester), 1);
      expect(isPriceFieldIgnoringPointer(tester), isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('분석 아님 > 처음부터 애니메이션 없음', (tester) async {
      useDesignScreenView(tester);
      await tester.pumpWidget(buildAnalyzingFieldApp(isAnalyzing: false));

      expect(find.text(AiPriceAnalyzingField.analyzingMessage), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('ItemPriceInputScreen AI 가격 분석', () {
    testWidgets('토글 켬 > 분석 중 표시·필드 읽기 전용, 예측 완료 > 추천 가격 필드 입력', (tester) async {
      useDesignScreenView(tester);
      final repository = _PendingPriceItemRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [itemRepositoryProvider.overrideWithValue(repository)],
          child: buildDesignScreenApp(
            home: ItemPriceInputScreen(
              initialPrice: 0,
              initialUseAiPrice: false,
              canUseAiPrice: true,
              itemName: '아이폰',
              itemDescription: '깨끗해요',
              itemCondition: 'SLIGHTLY_USED',
              onPriceSelected: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // 토글 켬 > 분석 시작
      await tester.tap(find.byType(AnimatedToggleSwitch<bool>));
      await tester.pump(fadeSettleDuration);

      expect(find.text(AiPriceAnalyzingField.analyzingMessage), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(priceFieldOpacity(tester), 0);

      // 예측 완료 > 플레이스홀더 페이드 아웃, 추천 가격 반영
      repository.pendingPrice.complete(15000);
      await tester.pump();
      await tester.pump(fadeSettleDuration);

      expect(find.text(AiPriceAnalyzingField.analyzingMessage), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '15,000');
      expect(priceFieldOpacity(tester), 1);

      // 완료 토스트 타이머 소진
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
