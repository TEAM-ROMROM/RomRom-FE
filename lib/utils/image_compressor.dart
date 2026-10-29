import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// 이미지를 WebP로 압축하는 공통 유틸.
///
/// 산출물은 현 백엔드(ImageCompressionService)와 동일: 가로 1280 축소(비율 유지),
/// WebP Q80. 압축 실패 시 원본 XFile을 그대로 반환한다(백엔드 조건부 압축이 안전망).
class ImageCompressor {
  ImageCompressor._();

  /// 백엔드 scaleToWidth(1280)와 동일한 가로 기준값.
  static const int targetWidth = 1280;

  /// 백엔드 QUALITY=80과 동일.
  static const int quality = 80;

  /// 단일 이미지를 WebP로 압축. 실패하면 원본 [source]를 그대로 반환(throw 안 함).
  static Future<XFile> toWebp(XFile source) async {
    try {
      final dir = await getTemporaryDirectory();
      final nonce = Random().nextInt(1 << 32);
      final fileName = 'cmp_${DateTime.now().microsecondsSinceEpoch}_$nonce.webp';
      final targetPath = '${dir.path}/$fileName';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        format: CompressFormat.webp,
        quality: quality,
        // 긴 변 기준 비율 유지 축소. 가로/세로 모두 targetWidth 이하로 맞춰지며
        // 원본이 더 작으면 확대하지 않는다(비율 보존).
        minWidth: targetWidth,
        minHeight: targetWidth,
      );

      if (result == null) {
        debugPrint('ImageCompressor: 압축 결과 null, 원본 사용 (${source.path})');
        return source;
      }
      return XFile(result.path);
    } catch (e) {
      debugPrint('ImageCompressor: 압축 실패, 원본 사용 ($e)');
      return source;
    }
  }
}
