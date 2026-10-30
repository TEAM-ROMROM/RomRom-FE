// 네이티브 광고 카드 스타일 <-> 물품 카드 치수·글자·색 일치 고정
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_card_layout.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_item_summary.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_native_ad_style.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import '../../helpers/pump_design_screen.dart';

// 테스트 상태바 높이 (iPhone 노치 기준)
const double testTopSafeAreaInset = 47;
// 앱 허용 최대 글자 배율 (text_scale_utils 상한)
const double testTextScaleFactor = 1.2;

/// 디자인 기준 화면에서 customOptions 생성 (글자 배율 1.2)
Future<Map<String, Object>> buildOptionsOnDesignScreen(WidgetTester tester) async {
  useDesignScreenView(tester);
  late Map<String, Object> customOptions;
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Builder(
        builder: (context) {
          customOptions = HomeFeedNativeAdStyle.buildCustomOptions(
            textScaler: const TextScaler.linear(testTextScaleFactor),
            topSafeAreaInset: testTopSafeAreaInset,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return customOptions;
}

void main() {
  group('HomeFeedNativeAdStyle', () {
    testWidgets('정보 패널 위치·간격·프로필 크기 = 물품 카드 값', (tester) async {
      final customOptions = await buildOptionsOnDesignScreen(tester);

      expect(customOptions['infoPanelBottomInset'], HomeFeedCardLayout.infoPanelBottomInset);
      expect(customOptions['infoPanelHorizontalPadding'], HomeFeedCardLayout.infoPanelHorizontalPadding);
      expect(customOptions['titleToMetaGap'], HomeFeedCardLayout.titleToMetaGap);
      expect(customOptions['metaToTagGap'], HomeFeedCardLayout.metaToTagGap);
      expect(customOptions['tagToPriceGap'], HomeFeedCardLayout.tagToPriceGap);
      expect(customOptions['iconSize'], HomeFeedCardLayout.profileAvatarSize);
      expect(customOptions['mediaTopCornerRadius'], HomeFeedCardLayout.imageTopCornerRadius.x);
      expect(customOptions['mediaBottomCornerRadius'], HomeFeedCardLayout.imageBottomCornerRadius.x);
      expect(customOptions['cardBackgroundColorArgb'], AppColors.homeFeedCardBackground.toARGB32());
    });

    testWidgets('헤드라인·본문·CTA 글자 = 이름·위치·가격 스타일 (글자 배율 반영)', (tester) async {
      final customOptions = await buildOptionsOnDesignScreen(tester);
      final headlineText = customOptions['headlineText']! as Map<String, Object>;
      final bodyText = customOptions['bodyText']! as Map<String, Object>;
      final callToActionText = customOptions['callToActionText']! as Map<String, Object>;

      expect(headlineText['fontSize'], HomeFeedItemSummary.titleTextStyle.fontSize! * testTextScaleFactor);
      expect(headlineText['fontAssetPath'], 'assets/fonts/pretendard/Pretendard-SemiBold.otf');
      expect(headlineText['colorArgb'], HomeFeedItemSummary.titleTextStyle.color!.toARGB32());
      expect(bodyText['fontSize'], HomeFeedItemSummary.metaTextStyle.fontSize! * testTextScaleFactor);
      expect(bodyText['fontAssetPath'], 'assets/fonts/pretendard/Pretendard-Medium.otf');
      expect(callToActionText['fontSize'], HomeFeedItemSummary.priceTextStyle.fontSize! * testTextScaleFactor);
      expect(callToActionText['fontAssetPath'], 'assets/fonts/pretendard/Pretendard-SemiBold.otf');
    });

    testWidgets('"광고" 배지 = 사용감 태그 모양, 최소 15x15 이상', (tester) async {
      final customOptions = await buildOptionsOnDesignScreen(tester);
      final adBadge = customOptions['adBadge']! as Map<String, Object>;
      final badgeText = adBadge['text']! as Map<String, Object>;

      expect(adBadge['label'], '광고');
      expect(adBadge['backgroundColorArgb'], ItemDetailConditionTag.backgroundColor.toARGB32());
      expect(adBadge['minWidth'], ItemDetailConditionTag.constraints.minWidth);
      expect(adBadge['minHeight'], ItemDetailConditionTag.constraints.minHeight);
      expect(adBadge['horizontalPadding'], ItemDetailConditionTag.padding.left);
      expect(adBadge['cornerRadius'], ItemDetailConditionTag.borderRadius);
      expect(badgeText['colorArgb'], ItemDetailConditionTag.textStyle.color!.toARGB32());
      expect(adBadge['minWidth']! as double, greaterThanOrEqualTo(15));
      expect(adBadge['minHeight']! as double, greaterThanOrEqualTo(15));
    });

    testWidgets('AdChoices = 상태바 아래 신고 버튼 자리', (tester) async {
      final customOptions = await buildOptionsOnDesignScreen(tester);

      expect(customOptions['adChoicesTopInset'], testTopSafeAreaInset + HomeFeedCardLayout.topActionsTopOffset);
      expect(customOptions['adChoicesTrailingInset'], HomeFeedCardLayout.topActionsTrailingInset);
    });
  });
}
