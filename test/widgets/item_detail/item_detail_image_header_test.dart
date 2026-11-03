import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/item_detail/item_detail_image_header.dart';

import '../../helpers/pump_design_screen.dart';

/// 물품 상세 헤더 이미지 검증: 피드와 같은 디스크 캐시(AppImageCacheManager), 확대 보기용 원본 해상도, 이미지 없음 자리표시
void main() {
  Future<void> pumpHeader(WidgetTester tester, List<String> imageUrls) async {
    useDesignScreenView(tester);
    final pageController = PageController();
    final currentIndexNotifier = ValueNotifier<int>(0);
    addTearDown(pageController.dispose);
    addTearDown(currentIndexNotifier.dispose);
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: ItemDetailImageHeader(
            imageSize: const Size(393, 393),
            imageUrls: imageUrls,
            pageController: pageController,
            currentIndexNotifier: currentIndexNotifier,
            heroBaseId: 'itemImage_item-1_',
            isExchanged: false,
          ),
        ),
      ),
    );
  }

  testWidgets('헤더 이미지 > AppImageCacheManager 디스크 캐시, 원본 해상도', (tester) async {
    await pumpHeader(tester, ['https://example.com/item_0.jpg', 'https://example.com/item_1.jpg']);

    final headerImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage).first);
    expect(headerImage.cacheManager, same(AppImageCacheManager.instance));
    expect(headerImage.imageUrl, 'https://example.com/item_0.jpg');
    expect(headerImage.memCacheWidth, isNull);
    expect(headerImage.memCacheHeight, isNull);
  });

  testWidgets('이미지 없음 > 실패 자리표시', (tester) async {
    await pumpHeader(tester, const []);

    expect(find.byType(ErrorImagePlaceholder), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
