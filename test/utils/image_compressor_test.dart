import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/utils/image_compressor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressor.toWebp', () {
    test('존재하지 않는 파일이면 원본 XFile을 그대로 반환하고 throw하지 않는다', () async {
      const sourcePath = '/non/existent/path/fake.jpg';
      final source = XFile(sourcePath);

      final result = await ImageCompressor.toWebp(source);

      expect(result.path, sourcePath);
    });

    test('상수값이 BE와 동일하다 (가로 1280, Q80)', () {
      expect(ImageCompressor.targetWidth, 1280);
      expect(ImageCompressor.quality, 80);
    });

    test('여러 장 동시 요청 > 결과 순서 = 입력 순서 (동시 압축 수 제한과 무관)', () async {
      final sources = [for (var index = 0; index < 5; index++) XFile('/non/existent/path/fake_$index.jpg')];

      final results = await Future.wait(sources.map(ImageCompressor.toWebp));

      expect(results.map((file) => file.path), sources.map((file) => file.path));
      expect(ImageCompressor.maximumConcurrentCompressionCount, 2);
    });

    test('압축이 끝나지 않음 > 제한 시간 뒤 원본 반환, 슬롯 반환되어 다음 압축 진행', () async {
      final stuckSources = [XFile('/stuck_0.jpg'), XFile('/stuck_1.jpg')];
      Future<XFile> neverCompletingCompress(XFile source) => Completer<XFile>().future;

      final stuckResults = await Future.wait(
        stuckSources.map(
          (source) => ImageCompressor.compressWithinSlot(
            source,
            neverCompletingCompress,
            timeout: const Duration(milliseconds: 20),
          ),
        ),
      );
      final nextResult = await ImageCompressor.compressWithinSlot(
        XFile('/next.jpg'),
        (source) async => XFile('/compressed.webp'),
        timeout: const Duration(milliseconds: 20),
      );

      expect(stuckResults.map((file) => file.path), ['/stuck_0.jpg', '/stuck_1.jpg']);
      expect(nextResult.path, '/compressed.webp');
      expect(ImageCompressor.compressionTimeout, const Duration(seconds: 20));
    });
  });
}
