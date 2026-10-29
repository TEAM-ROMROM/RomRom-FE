import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

const double _devicePixelRatio = 3;

Future<CachedNetworkImage> _pumpAndFindNetworkImage(WidgetTester tester, CachedImage image) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(devicePixelRatio: _devicePixelRatio),
      child: Directionality(textDirection: TextDirection.ltr, child: image),
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

  testWidgets('width null > memCacheWidth 미지정', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(tester, const CachedImage(imageUrl: imageUrl));
    expect(networkImage.memCacheWidth, isNull);
    expect(networkImage.memCacheHeight, isNull);
  });

  testWidgets('width infinity > memCacheWidth 미지정', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(
      tester,
      const CachedImage(imageUrl: imageUrl, width: double.infinity),
    );
    expect(networkImage.memCacheWidth, isNull);
  });

  testWidgets('width 0 이하 > memCacheWidth 미지정', (tester) async {
    final networkImage = await _pumpAndFindNetworkImage(tester, const CachedImage(imageUrl: imageUrl, width: 0));
    expect(networkImage.memCacheWidth, isNull);
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
}
