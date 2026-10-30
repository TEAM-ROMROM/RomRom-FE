import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// 하트 튕김 관찰 구간 (300ms 안팎 목표)
const Duration heartBounceObserveDuration = Duration(milliseconds: 320);
const Duration frameDuration = Duration(milliseconds: 16);

/// 하트 표시 배율 (좋아요 버튼 안 ScaleTransition)
double readHeartScale(WidgetTester tester) {
  final heartScale = tester.widget<ScaleTransition>(
    find.descendant(of: find.byType(HomeFeedItemLikeButton), matching: find.byType(ScaleTransition)).first,
  );
  return heartScale.scale.value;
}

/// 프레임 단위로 진행하며 하트 최대 배율 기록
Future<double> pumpAndReadPeakHeartScale(WidgetTester tester, {required Duration duration}) async {
  double peakHeartScale = readHeartScale(tester);
  for (Duration elapsed = Duration.zero; elapsed < duration; elapsed += frameDuration) {
    await tester.pump(frameDuration);
    peakHeartScale = math.max(peakHeartScale, readHeartScale(tester));
  }
  return peakHeartScale;
}

/// 햅틱 호출 기록 (플랫폼 채널 HapticFeedback.vibrate 인자)
List<String> recordHapticCalls(WidgetTester tester) {
  final hapticCalls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
    if (methodCall.method == 'HapticFeedback.vibrate') hapticCalls.add(methodCall.arguments as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return hapticCalls;
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

    testWidgets('탭 > 하트가 1보다 커졌다 300ms 안팎에 1로 복귀 + 가벼운 햅틱', (tester) async {
      final hapticCalls = recordHapticCalls(tester);
      await pumpHomeFeedWidget(tester, HomeFeedItemLikeButton(isLiked: false, likeCount: 7, onTap: () {}));
      expect(readHeartScale(tester), 1.0);

      await tester.tap(find.bySemanticsLabel('좋아요'));
      final double peakHeartScale = await pumpAndReadPeakHeartScale(tester, duration: heartBounceObserveDuration);

      expect(peakHeartScale, greaterThan(1.1));
      expect(peakHeartScale, lessThan(1.3));
      expect(readHeartScale(tester), closeTo(1.0, 0.01));
      expect(hapticCalls, contains('HapticFeedbackType.lightImpact'));

      await tester.pumpAndSettle();
      expect(readHeartScale(tester), 1.0);
    });

    testWidgets('빠른 연타 > 크기가 튀지 않고 이어지다 1로 정착', (tester) async {
      await pumpHomeFeedWidget(tester, HomeFeedItemLikeButton(isLiked: false, likeCount: 7, onTap: () {}));

      // 튕김 도중 다시 탭 > 현재 크기에서 이어서 확대 (1로 되돌아가는 점프 없음)
      await tester.tap(find.bySemanticsLabel('좋아요'));
      await tester.pump(const Duration(milliseconds: 40));
      final double heartScaleBeforeSecondTap = readHeartScale(tester);
      await tester.tap(find.bySemanticsLabel('좋아요'));
      await tester.pump();
      expect(readHeartScale(tester), greaterThanOrEqualTo(heartScaleBeforeSecondTap - 0.01));

      await tester.pumpAndSettle();
      expect(readHeartScale(tester), 1.0);
    });

    testWidgets('좋아요 수 변경 > 위아래 슬라이드 전환 후 새 숫자만 남음', (tester) async {
      await pumpHomeFeedWidget(tester, HomeFeedItemLikeButton(isLiked: false, likeCount: 7, onTap: () {}));
      await pumpHomeFeedWidget(tester, HomeFeedItemLikeButton(isLiked: true, likeCount: 8, onTap: () {}));

      // 전환 중: 이전·새 숫자 함께 표시, 새 숫자는 아래에서 올라오는 중
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('7'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(tester.getCenter(find.text('8')).dy, greaterThan(tester.getCenter(find.text('7')).dy));

      await tester.pumpAndSettle();
      expect(find.text('7'), findsNothing);
      expect(find.text('8'), findsOneWidget);
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
