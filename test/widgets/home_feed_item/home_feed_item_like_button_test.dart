import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_image_indicator.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_item_like_button.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함)
Future<void> pumpHomeFeedWidget(WidgetTester tester, Widget homeFeedWidget) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: Center(child: homeFeedWidget)),
    ),
  );
}

void main() {
  group('HomeFeedItemLikeButton', () {
    testWidgets('좋아요 전: 라벨·수 표시 > 탭 시 콜백', (tester) async {
      int likeTapCount = 0;
      await pumpHomeFeedWidget(
        tester,
        HomeFeedItemLikeButton(isLiked: false, likeCount: 7, onTap: () => likeTapCount++),
      );

      expect(find.bySemanticsLabel('좋아요'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('좋아요'));
      await tester.pump();
      expect(likeTapCount, 1);
    });

    testWidgets('좋아요 후: 취소 라벨', (tester) async {
      await pumpHomeFeedWidget(tester, HomeFeedItemLikeButton(isLiked: true, likeCount: 8, onTap: () {}));
      expect(find.bySemanticsLabel('좋아요 취소'), findsOneWidget);
    });
  });

  group('HomeFeedImageIndicator', () {
    testWidgets('사진 수만큼 점', (tester) async {
      await pumpHomeFeedWidget(tester, const HomeFeedImageIndicator(imageCount: 3, currentImageIndex: 1));
      expect(
        find.descendant(of: find.byType(HomeFeedImageIndicator), matching: find.byType(Container)),
        findsNWidgets(3),
      );
    });
  });
}
