// 물품 등록·수정 새 사진 업로드 기억: 저장 실패 후 재시도 시 이미 올린 사진 재업로드 방지
import 'package:image_picker/image_picker.dart';

/// 새 사진 업로드 기억: 원본 파일(객체 동일성)별 서버 주소 > 안 올린 사진만 업로드
class NewImageUploadCache {
  // 원본 파일 > 업로드된 서버 주소 (같은 파일 재선택도 다른 객체라 구분됨)
  final Map<XFile, String> _uploadedUrlByOriginalFile = Map.identity();

  /// 안 올린 사진만 업로드 > 원본 순서대로 전체 주소 (원본·압축 목록 인덱스 1:1, 일부 실패 시 예외·미기억)
  /// 호출 시점 목록 사본으로 짝짓기·반환 (대기 중 화면 목록이 바뀌어도 사진 <-> 주소 어긋남 없음)
  Future<List<String>> uploadPendingImages({
    required List<XFile> originalFiles,
    required List<Future<XFile>> compressedFiles,
    required Future<List<String>> Function(List<XFile> files) uploadImages,
  }) async {
    final originalFilesSnapshot = List<XFile>.of(originalFiles);
    final compressedFilesSnapshot = List<Future<XFile>>.of(compressedFiles);
    final pendingOriginalFiles = <XFile>[];
    final pendingCompressedFutures = <Future<XFile>>[];
    for (var index = 0; index < originalFilesSnapshot.length; index++) {
      if (_uploadedUrlByOriginalFile.containsKey(originalFilesSnapshot[index])) continue;
      pendingOriginalFiles.add(originalFilesSnapshot[index]);
      pendingCompressedFutures.add(compressedFilesSnapshot[index]);
    }

    if (pendingOriginalFiles.isNotEmpty) {
      final pendingCompressedFiles = await Future.wait(pendingCompressedFutures);
      final uploadedUrls = await uploadImages(pendingCompressedFiles);
      if (uploadedUrls.length != pendingCompressedFiles.length) {
        throw Exception('일부 이미지 업로드에 실패했습니다 (${uploadedUrls.length}/${pendingCompressedFiles.length})');
      }
      for (var order = 0; order < pendingOriginalFiles.length; order++) {
        _uploadedUrlByOriginalFile[pendingOriginalFiles[order]] = uploadedUrls[order];
      }
    }

    return [for (final originalFile in originalFilesSnapshot) _uploadedUrlByOriginalFile[originalFile]!];
  }
}
