import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/cached_image_precache.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

const double _devicePixelRatio = 3;
const String _imageUrl = 'https://example.com/feed.jpg';

/// 미리 받기 키 == CachedImage가 그리는 이미지 키 (디스크 캐시·디코딩 크기 모두 같아야 메모리 캐시 공유)
void main() {
  testWidgets('카드 표시 크기 cover > CachedImage 이미지 provider와 같은 키', (tester) async {
    const displaySize = Size(393, 620);
    late ImageProvider precacheImageProvider;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: _devicePixelRatio),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              precacheImageProvider = buildCachedImageProvider(
                context,
                imageUrl: _imageUrl,
                width: displaySize.width,
                height: displaySize.height,
              );
              return CachedImage(imageUrl: _imageUrl, width: displaySize.width, height: displaySize.height);
            },
          ),
        ),
      ),
    );

    // CachedNetworkImage 내부 Image 위젯이 실제로 그리는 provider
    final renderedImageProvider = tester.widget<Image>(find.byType(Image)).image;
    expect(precacheImageProvider, renderedImageProvider);
    expect(precacheImageProvider, isA<ResizeImage>());
  });
}
