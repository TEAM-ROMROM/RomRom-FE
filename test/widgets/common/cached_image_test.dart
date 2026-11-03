import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

const double _devicePixelRatio = 3;

/// [boxSize] 지정 시 가운데 고정 크기 박스 안에 배치 (레이아웃 기준 디코딩 검증)
Future<CachedNetworkImage> _pumpAndFindNetworkImage(WidgetTester tester, CachedImage image, {Size? boxSize}) async {
  final Widget content = boxSize == null
      ? image
      : Center(
          child: SizedBox(width: boxSize.width, height: boxSize.height, child: image),
        );
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(devicePixelRatio: _devicePixelRatio),
      child: Directionality(textDirection: TextDirection.ltr, child: content),
    ),
  );
  return tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
}

void main() {
  const imageUrl = 'https://example.com/thumbnail.jpg';

  testWidgets('width 100, DPR 3 > memCacheWidth 300', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(tester, const CachedImage(imageUrl: imageUrl, width: 100));
    expect(networkImage.memCacheWidth, 300);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('크기 없음 + 70x70 박스, cover > 레이아웃 기준 70 x 3 x 1.8 = 378 > 400 올림', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl),
      boxSize: const Size(70, 70),
    );
    expect(networkImage.memCacheWidth, 400);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('width infinity + 가로 393 박스, contain > 393 x 3 = 1179 > 1200 올림', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: double.infinity, fit: BoxFit.contain),
      boxSize: const Size(393, 200),
    );
    expect(networkImage.memCacheWidth, 1200);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('width 0 이하 > 레이아웃 기준', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: 0, fit: BoxFit.contain),
      boxSize: const Size(100, 100),
    );
    expect(networkImage.memCacheWidth, 300);
  });

  testWidgets('확대 보기 (shouldDecodeAtFullResolution) > 원본 해상도', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: double.infinity, shouldDecodeAtFullResolution: true),
      boxSize: const Size(393, 600),
    );
    expect(networkImage.memCacheWidth, isNull);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('디스크 캐시 > AppImageCacheManager 사용', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(tester, const CachedImage(imageUrl: imageUrl, width: 100));
    expect(networkImage.cacheManager, same(AppImageCacheManager.instance));
  });

  // 요청 카드: IntrinsicHeight > Row > 고정 크기 박스 안 크기 없는 이미지 (LayoutBuilder 고유 크기 질의 예외 없음)
  testWidgets('IntrinsicHeight 안 고정 크기 박스 > 예외 없이 박스 크기 기준', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: _devicePixelRatio),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 345,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: ClipRRect(child: CachedImage(imageUrl: imageUrl)),
                            ),
                          ),
                          Expanded(child: Text('title')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).memCacheWidth, 400);
  });

  testWidgets('height만 있으면 memCacheHeight 지정', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(tester, const CachedImage(imageUrl: imageUrl, height: 50));
    expect(networkImage.memCacheWidth, isNull);
    expect(networkImage.memCacheHeight, 150);
  });

  testWidgets('cover + 100x100, DPR 3 > memCacheWidth 540 (긴 변 x 1.8)', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: 100, height: 100),
    );
    expect(networkImage.memCacheWidth, 540);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('cover + 100x50 > 긴 변(width) 기준 540', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: 100, height: 50),
    );
    expect(networkImage.memCacheWidth, 540);
  });

  testWidgets('contain + 100x100 > memCacheWidth 300 (width만)', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: 100, height: 100, fit: BoxFit.contain),
    );
    expect(networkImage.memCacheWidth, 300);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('httpHeaders를 CachedNetworkImage로 전달', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, httpHeaders: {'x-key': 'value'}),
    );
    expect(networkImage.httpHeaders, {'x-key': 'value'});
  });

  group('레이아웃 기준 디코딩 크기 고정', () {
    Widget buildImageInBox(Size boxSize, String url) => MediaQuery(
      data: const MediaQueryData(devicePixelRatio: _devicePixelRatio),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: boxSize.width,
            height: boxSize.height,
            child: CachedImage(imageUrl: url),
          ),
        ),
      ),
    );

    int? readMemCacheWidth(WidgetTester tester) =>
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).memCacheWidth;

    // Hero 복귀 비행처럼 박스 크기가 매 프레임 바뀌는 상황
    testWidgets('크기 없음 + 박스 크기가 계속 바뀜 > 첫 디코딩 크기 유지 (재디코딩 없음)', (tester) async {
      await tester.pumpWidget(buildImageInBox(const Size(300, 300), imageUrl));
      final firstMemCacheWidth = readMemCacheWidth(tester);
      expect(firstMemCacheWidth, 1700);

      for (final boxSide in [260.0, 200.0, 140.0, 90.0]) {
        await tester.pumpWidget(buildImageInBox(Size(boxSide, boxSide), imageUrl));
        expect(readMemCacheWidth(tester), firstMemCacheWidth);
      }
    });

    testWidgets('URL 바뀜 > 현재 박스 기준으로 다시 계산', (tester) async {
      await tester.pumpWidget(buildImageInBox(const Size(300, 300), imageUrl));
      await tester.pumpWidget(buildImageInBox(const Size(90, 90), 'https://example.com/other.jpg'));

      expect(readMemCacheWidth(tester), 500);
    });
  });
}
