import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:romrom_fe/enums/chat_image_save_result.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';

/// 기기 사진 앨범 쓰기 (권한 확인·요청, JPEG 저장) — 테스트에서 가짜로 교체
abstract class GalleryImageWriter {
  Future<bool> hasSaveAccess();

  /// 권한 요청 (시스템 팝업, 이미 거부된 iOS는 팝업 없이 false)
  Future<bool> requestSaveAccess();

  Future<void> saveJpegBytes(Uint8List jpegBytes, {required String fileName});
}

/// gal 패키지 앨범 쓰기 (iOS 추가 전용 권한, Android 10+ 권한 없음)
class GalGalleryImageWriter implements GalleryImageWriter {
  @override
  Future<bool> hasSaveAccess() => Gal.hasAccess();

  @override
  Future<bool> requestSaveAccess() => Gal.requestAccess();

  @override
  Future<void> saveJpegBytes(Uint8List jpegBytes, {required String fileName}) =>
      Gal.putImageBytes(jpegBytes, name: fileName);
}

/// 채팅 사진 앨범 저장: 권한 확인(저장 버튼 탭 시점만, 요청 1회) > 캐시 원본 파일 > JPEG 변환 > 앨범 저장
/// JPEG 변환 이유: 서버 사진은 webp > 사진 앱·갤러리 호환
class ChatImageGallerySaver {
  ChatImageGallerySaver({
    GalleryImageWriter? galleryImageWriter,
    Future<File> Function(String imageUrl)? loadImageFile,
    Future<Uint8List?> Function(String imagePath)? convertToJpegBytes,
  }) : _galleryImageWriter = galleryImageWriter ?? GalGalleryImageWriter(),
       _loadImageFile = loadImageFile ?? AppImageCacheManager.instance.getSingleFile,
       _convertToJpegBytes = convertToJpegBytes ?? _convertToJpegBytesWithCompressor;

  // 저장 JPEG 품질 (원본 화질 유지 목적, 0~100)
  static const int savedJpegQuality = 95;
  // 앨범 파일명 접두어: romrom_{밀리초}
  static const String savedFileNamePrefix = 'romrom_';

  final GalleryImageWriter _galleryImageWriter;
  final Future<File> Function(String imageUrl) _loadImageFile;
  final Future<Uint8List?> Function(String imagePath) _convertToJpegBytes;

  /// 네트워크 사진 1장 저장 > 결과 (예외 밖으로 던지지 않음)
  Future<ChatImageSaveResult> saveNetworkImage(String imageUrl) async {
    try {
      if (!await _ensureSaveAccess()) return ChatImageSaveResult.permissionDenied;

      final imageFile = await _loadImageFile(imageUrl);
      final jpegBytes = await _convertToJpegBytes(imageFile.path);
      if (jpegBytes == null || jpegBytes.isEmpty) return ChatImageSaveResult.failed;

      await _galleryImageWriter.saveJpegBytes(
        jpegBytes,
        fileName: '$savedFileNamePrefix${DateTime.now().millisecondsSinceEpoch}',
      );
      return ChatImageSaveResult.saved;
    } on GalException catch (error) {
      debugPrint('[chat image save] failed : ${error.type.code}');
      return error.type == GalExceptionType.accessDenied
          ? ChatImageSaveResult.permissionDenied
          : ChatImageSaveResult.failed;
    } catch (error) {
      debugPrint('[chat image save] failed : $error');
      return ChatImageSaveResult.failed;
    }
  }

  /// 저장 권한: 있음 > 통과, 없음 > 요청 1회 (거부 시 반복 요청 없음)
  Future<bool> _ensureSaveAccess() async {
    if (await _galleryImageWriter.hasSaveAccess()) return true;
    return _galleryImageWriter.requestSaveAccess();
  }

  static Future<Uint8List?> _convertToJpegBytesWithCompressor(String imagePath) =>
      FlutterImageCompress.compressWithFile(imagePath, format: CompressFormat.jpeg, quality: savedJpegQuality);
}
