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
  });
}
