import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';
import '../../helpers/pump_design_screen.dart';

/// 태그 1개 렌더 (디자인 기준 화면: .w·.h·.r·.sp 배율 1.0)
Future<void> pumpTag(WidgetTester tester, Widget tag) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: Center(child: tag)),
    ),
  );
}

/// AppTag 안 배경 박스
Container findTagBox(WidgetTester tester) {
  return tester.widget<Container>(find.descendant(of: find.byType(AppTag), matching: find.byType(Container)));
}

BoxDecoration findTagDecoration(WidgetTester tester) => findTagBox(tester).decoration! as BoxDecoration;

TextStyle findTagTextStyle(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style!;

void main() {
  // 기존 4종 태그의 크기·패딩·색·모서리·글자 스타일 고정 (AppTag 공통화 전 값 그대로)
  group('AppTag 기존 태그 4종 외형 유지', () {
    testWidgets('사용감 태그: 최소 50x23, 패딩 8/6, 사용감 배경, 반경 100, 10 w600 검정', (tester) async {
      await pumpTag(tester, const ItemDetailConditionTag(condition: '새 것 같음'));

      final tagBox = findTagBox(tester);
      expect(tagBox.constraints, const BoxConstraints(minWidth: 50, minHeight: 23));
      expect(tagBox.padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 6));
      expect(tagBox.alignment, isNull);
      expect(findTagDecoration(tester).color, AppColors.conditionTagBackground);
      expect(findTagDecoration(tester).borderRadius, BorderRadius.circular(100));

      final textStyle = findTagTextStyle(tester, '새 것 같음');
      expect(textStyle.fontSize, 10);
      expect(textStyle.fontWeight, FontWeight.w600);
      expect(textStyle.color, AppColors.primaryBlack);
      expect(textStyle.height, 1.0);
      expect(tester.widget<Text>(find.text('새 것 같음')).textAlign, TextAlign.center);

      final tagSize = tester.getSize(find.byType(ItemDetailConditionTag));
      expect(tagSize.width, greaterThanOrEqualTo(50));
      expect(tagSize.height, greaterThanOrEqualTo(23));
    });

    testWidgets('물품 상세 거래 옵션 태그: 고정 50x23, 가운데 정렬, 거래 배경, 반경 100, 10 w600 검정', (tester) async {
      await pumpTag(tester, const ItemDetailTradeOptionTag(option: '택배'));

      final tagBox = findTagBox(tester);
      expect(tagBox.constraints, const BoxConstraints.tightFor(width: 50, height: 23));
      expect(tagBox.padding, isNull);
      expect(tagBox.alignment, Alignment.center);
      expect(findTagDecoration(tester).color, AppColors.transactionTagBackground);
      expect(findTagDecoration(tester).borderRadius, BorderRadius.circular(100));

      final textStyle = findTagTextStyle(tester, '택배');
      expect(textStyle.fontSize, 10);
      expect(textStyle.fontWeight, FontWeight.w600);
      expect(textStyle.color, AppColors.primaryBlack);
      expect(textStyle.height, 1.0);
      expect(tester.getSize(find.byType(ItemDetailTradeOptionTag)), const Size(50, 23));
    });

    testWidgets('요청 관리 거래 옵션 태그: 너비 62, 패딩 18/6/18/7, 회색 배경, 반경 100, 10 흰색', (tester) async {
      await pumpTag(tester, const RequestManagementTradeOptionTag(option: ItemTradeOption.deliveryOnly));

      final tagBox = findTagBox(tester);
      expect(tagBox.constraints, const BoxConstraints.tightFor(width: 62));
      expect(tagBox.padding, const EdgeInsets.fromLTRB(18, 6, 18, 7));
      expect(tagBox.alignment, Alignment.center);
      expect(findTagDecoration(tester).color, AppColors.secondaryBlack2);
      expect(findTagDecoration(tester).borderRadius, BorderRadius.circular(100));

      final textStyle = findTagTextStyle(tester, ItemTradeOption.deliveryOnly.label);
      expect(textStyle.fontSize, 10);
      expect(textStyle.fontWeight, FontWeight.w600);
      expect(textStyle.color, AppColors.textColorWhite);
      expect(tester.widget<Text>(find.text(ItemTradeOption.deliveryOnly.label)).textAlign, isNull);
      expect(tester.getSize(find.byType(RequestManagementTradeOptionTag)).width, 62);
    });

    testWidgets('거래 상태 태그(채팅 중): 고정 60x23, 채팅 배경, 반경 4, 10 흰색', (tester) async {
      await pumpTag(tester, const TradeStatusTagWidget(status: TradeStatus.chatting));

      final tagBox = findTagBox(tester);
      expect(tagBox.constraints, const BoxConstraints.tightFor(width: 60, height: 23));
      expect(tagBox.alignment, Alignment.center);
      expect(findTagDecoration(tester).color, AppColors.tradeStatusIsChatting);
      expect(findTagDecoration(tester).borderRadius, BorderRadius.circular(4));

      final textStyle = findTagTextStyle(tester, '채팅 중');
      expect(textStyle.fontSize, 10);
      expect(textStyle.color, AppColors.textColorWhite);
      expect(tester.getSize(find.byType(TradeStatusTagWidget)), const Size(60, 23));
    });

    testWidgets('거래 상태 태그(교환 완료): 교환완료 문구·완료 배경', (tester) async {
      await pumpTag(tester, const TradeStatusTagWidget(status: TradeStatus.traded));

      expect(find.text('교환완료'), findsOneWidget);
      expect(findTagDecoration(tester).color, AppColors.tradeStatusIsCompleted);
    });

    testWidgets('거래 상태 태그(대기): 태그 없음', (tester) async {
      await pumpTag(tester, const TradeStatusTagWidget(status: TradeStatus.pending));

      expect(find.byType(AppTag), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });
}
