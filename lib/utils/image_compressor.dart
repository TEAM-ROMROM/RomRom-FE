import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:romrom_fe/utils/concurrency_limiter.dart';

/// 이미지를 WebP로 압축하는 공통 유틸.
///
/// 산출물은 현 백엔드(ImageCompressionService)와 동일: 가로 1280 축소(비율 유지),
/// WebP Q80. 압축 실패·시간 초과 시 원본 XFile을 그대로 반환한다(백엔드 조건부 압축이 안전망).
/// 동시 압축 최대 [maximumConcurrentCompressionCount]건 (초과 요청은 순서대로 대기)
class ImageCompressor {
  ImageCompressor._();

  /// 백엔드 scaleToWidth(1280)와 동일한 가로 기준값.
  static const int targetWidth = 1280;

  /// 백엔드 QUALITY=80과 동일.
  static const int quality = 80;

  // 동시 압축 최대 수 (원본 12MP 디코딩 약 48MB/장, 10장 동시 압축 시 메모리 급증 방지)
  static const int maximumConcurrentCompressionCount = 2;

  // 앱 전역 압축 슬롯 (등록·채팅·프로필 공통, 초과 요청은 순서대로 대기)
  static final ConcurrencyLimiter _compressionLimiter = ConcurrencyLimiter(
    maximumConcurrentCount: maximumConcurrentCompressionCount,
  );

  // 압축 1건 제한 시간 (초과 시 원본 사용 > 멈춘 압축이 슬롯을 계속 점유하지 않음)
  static const Duration compressionTimeout = Duration(seconds: 20);

  /// 단일 이미지를 WebP로 압축. 실패·시간 초과면 원본 [source]를 그대로 반환(throw 안 함).
  static Future<XFile> toWebp(XFile source) => compressWithinSlot(source, _compressToWebp);

  /// 압축 슬롯 확보 > [compress] 실행 > 제한 시간 초과 시 원본 반환 (슬롯은 시간 초과 시점에 반환)
  @visibleForTesting
  static Future<XFile> compressWithinSlot(
    XFile source,
    Future<XFile> Function(XFile source) compress, {
    Duration timeout = compressionTimeout,
  }) {
    return _compressionLimiter.run(
      () => compress(source).timeout(
        timeout,
        onTimeout: () {
          debugPrint('ImageCompressor: 압축 시간 초과, 원본 사용 (${source.path})');
          return source;
        },
      ),
    );
  }

  /// 압축 1건: 임시 경로 생성 > WebP 변환 (실패·null > 원본)
  static Future<XFile> _compressToWebp(XFile source) async {
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
