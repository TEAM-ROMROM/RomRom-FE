import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/image_decode_size.dart';

/// 디코딩 크기 검증: 지정 크기 규칙(cover·fitHeight·none·가로 우선), 무효 값, 레이아웃 제약 대체·올림
void main() {
  const devicePixelRatio = 3.0;

  group('forDisplay (지정 크기)', () {
    test('가로만 100 > 가로 300', () {
      expect(
        ImageDecodeSize.forDisplay(width: 100, fit: BoxFit.cover, devicePixelRatio: devicePixelRatio),
        const ImageDecodeSize(width: 300),
      );
    });

    test('cover + 100x50 > 긴 변 x 1.8 > 가로 540', () {
      expect(
        ImageDecodeSize.forDisplay(width: 100, height: 50, fit: BoxFit.cover, devicePixelRatio: devicePixelRatio),
        const ImageDecodeSize(width: 540),
      );
    });

    test('contain + 100x100 > 가로만 300', () {
      expect(
        ImageDecodeSize.forDisplay(width: 100, height: 100, fit: BoxFit.contain, devicePixelRatio: devicePixelRatio),
        const ImageDecodeSize(width: 300),
      );
    });

    test('fitHeight + 100x50 > 세로만 150', () {
      expect(
        ImageDecodeSize.forDisplay(width: 100, height: 50, fit: BoxFit.fitHeight, devicePixelRatio: devicePixelRatio),
        const ImageDecodeSize(height: 150),
      );
    });

    test('none > 원본', () {
      expect(
        ImageDecodeSize.forDisplay(width: 100, height: 100, fit: BoxFit.none, devicePixelRatio: devicePixelRatio),
        ImageDecodeSize.original,
      );
    });

    test('null·무한대·0 이하 > 없는 값 취급', () {
      expect(
        ImageDecodeSize.forDisplay(width: double.infinity, height: 0, fit: BoxFit.cover, devicePixelRatio: 3),
        ImageDecodeSize.original,
      );
      expect(
        ImageDecodeSize.forDisplay(width: -1, height: 50, fit: BoxFit.cover, devicePixelRatio: devicePixelRatio),
        const ImageDecodeSize(height: 150),
      );
      expect(ImageDecodeSize.original.isOriginal, isTrue);
    });
  });

  group('forLayout (레이아웃 제약)', () {
    test('크기 없음 + 70x70 고정 제약, cover > 70 x 3 x 1.8 = 378 > 400 올림', () {
      expect(
        ImageDecodeSize.forLayout(
          BoxConstraints.tight(const Size(70, 70)),
          fit: BoxFit.cover,
          devicePixelRatio: devicePixelRatio,
        ),
        const ImageDecodeSize(width: 400),
      );
    });

    test('가로 무한대 지정 + 가로 393 제약, 세로 무제한 > 가로 393 x 3 = 1179 > 1200 올림', () {
      expect(
        ImageDecodeSize.forLayout(
          const BoxConstraints(maxWidth: 393),
          width: double.infinity,
          fit: BoxFit.cover,
          devicePixelRatio: devicePixelRatio,
        ),
        const ImageDecodeSize(width: 1200),
      );
    });

    test('지정 크기 우선 (제약보다 작은 지정 가로)', () {
      expect(
        ImageDecodeSize.forLayout(
          const BoxConstraints(maxWidth: 393),
          width: 100,
          fit: BoxFit.contain,
          devicePixelRatio: devicePixelRatio,
        ),
        const ImageDecodeSize(width: 300),
      );
    });

    test('가로·세로 제약 모두 무제한 > 원본', () {
      expect(
        ImageDecodeSize.forLayout(const BoxConstraints(), fit: BoxFit.cover, devicePixelRatio: devicePixelRatio),
        ImageDecodeSize.original,
      );
    });

    test('제약이 조금 바뀌어도 같은 올림 단위면 같은 크기 (캐시 키 유지)', () {
      final smallerSize = ImageDecodeSize.forLayout(
        BoxConstraints.tight(const Size(101, 50)),
        fit: BoxFit.contain,
        devicePixelRatio: 1,
      );
      final largerSize = ImageDecodeSize.forLayout(
        BoxConstraints.tight(const Size(199, 50)),
        fit: BoxFit.contain,
        devicePixelRatio: 1,
      );
      expect(smallerSize, largerSize);
      expect(smallerSize.width, 200);
    });
  });
}
