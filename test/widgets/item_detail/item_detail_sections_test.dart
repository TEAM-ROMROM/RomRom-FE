import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_info_section.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_seller_section.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함, 세로 넘침 방지 스크롤)
Future<void> pumpItemDetailWidget(WidgetTester tester, Widget itemDetailWidget) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: SingleChildScrollView(child: itemDetailWidget)),
    ),
  );
}

/// RichText 내용 포함 검색 (카테고리 · 등록 시각 한 줄)
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains(text));
}

void main() {
  group('ItemDetailInfoSection', () {
    testWidgets('서버 값 > 표시 이름 변환: 카테고리·등록 시각·사용감·거래 방식·가격·AI 배지', (tester) async {
      final item = Item(
        createdDate: DateTime.now().subtract(const Duration(days: 3, minutes: 1)),
        itemName: '나이키 운동화',
        itemDescription: '한 번 신었어요',
        itemCategory: 'SHOES',
        itemCondition: 'SLIGHTLY_USED',
        itemTradeOptions: const ['DIRECT_ONLY', 'DELIVERY_ONLY', 'UNKNOWN_OPTION'],
        price: 12000,
        isAiPredictedPrice: true,
      );

      await pumpItemDetailWidget(tester, ItemDetailInfoSection(item: item));

      expect(findRichTextContaining('신발 · 3일 전'), findsOneWidget);
      expect(find.text('나이키 운동화'), findsOneWidget);
      expect(find.text('한 번 신었어요'), findsOneWidget);
      expect(find.text('12,000원'), findsOneWidget);
      expect(find.widgetWithText(ItemDetailConditionTag, '사용감 적음'), findsOneWidget);
      expect(find.widgetWithText(ItemDetailTradeOptionTag, '직거래'), findsOneWidget);
      expect(find.widgetWithText(ItemDetailTradeOptionTag, '택배'), findsOneWidget);
      // 알 수 없는 거래 방식은 서버 값 그대로
      expect(find.widgetWithText(ItemDetailTradeOptionTag, 'UNKNOWN_OPTION'), findsOneWidget);
      expect(find.byType(AiBadgeWidget), findsOneWidget);
    });

    testWidgets('값 없음 > 기본 문구, 태그·AI 배지 생략', (tester) async {
      await pumpItemDetailWidget(tester, ItemDetailInfoSection(item: Item()));

      expect(findRichTextContaining('카테고리 없음 · 날짜 정보 없음'), findsOneWidget);
      expect(find.text('제목 없음'), findsOneWidget);
      expect(find.text('설명이 없습니다.'), findsOneWidget);
      expect(find.text('0원'), findsOneWidget);
      expect(find.byType(ItemDetailConditionTag), findsNothing);
      expect(find.byType(ItemDetailTradeOptionTag), findsNothing);
      expect(find.byType(AiBadgeWidget), findsNothing);
    });

    testWidgets('1분 미만 등록 > 방금 전', (tester) async {
      await pumpItemDetailWidget(tester, ItemDetailInfoSection(item: Item(createdDate: DateTime.now())));

      expect(findRichTextContaining('· 방금 전'), findsOneWidget);
    });
  });

  group('ItemDetailSellerSection', () {
    testWidgets('닉네임 없음 > 알 수 없음, 위치·좋아요 수 표시, 탭 콜백 전달', (tester) async {
      var profileTapCount = 0;
      var likeTapCount = 0;

      await pumpItemDetailWidget(
        tester,
        ItemDetailSellerSection(
          profileUrl: null,
          isDeletedAccount: false,
          nickname: null,
          memberLocationName: '서울 강남구',
          shouldLimitNicknameWidth: false,
          isLiked: true,
          likeCount: 7,
          onProfileTap: () => profileTapCount++,
          onLikeTap: () => likeTapCount++,
        ),
      );

      expect(find.text('알 수 없음'), findsOneWidget);
      expect(find.text('서울 강남구'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      await tester.tap(find.text('알 수 없음'));
      await tester.tap(find.byType(InkResponse));
      await tester.pump();

      expect(profileTapCount, 1);
      expect(likeTapCount, 1);
    });
  });
}
