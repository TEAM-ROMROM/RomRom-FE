import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/utils/new_image_upload_cache.dart';

/// 업로드 대역: 호출마다 받은 파일 경로 기록, 실패 모드면 throw
class _RecordingUploader {
  final List<List<String>> uploadedPathBatches = [];
  bool isFailing = false;
  int uploadedFileCount = 0;

  Future<List<String>> upload(List<XFile> files) async {
    uploadedPathBatches.add(files.map((file) => file.path).toList());
    if (isFailing) throw Exception('upload failed');
    return [for (final file in files) 'https://image/${++uploadedFileCount}-${file.path}'];
  }
}

void main() {
  group('NewImageUploadCache', () {
    test('첫 업로드: 압축본 전부 업로드 > 원본 순서대로 주소 반환', () async {
      final uploadCache = NewImageUploadCache();
      final uploader = _RecordingUploader();
      final originalFiles = [XFile('a.jpg'), XFile('b.jpg')];

      final imageUrls = await uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: [Future.value(XFile('a.webp')), Future.value(XFile('b.webp'))],
        uploadImages: uploader.upload,
      );

      expect(uploader.uploadedPathBatches, [
        ['a.webp', 'b.webp'],
      ]);
      expect(imageUrls, ['https://image/1-a.webp', 'https://image/2-b.webp']);
    });

    test('재시도: 이미 올린 사진은 다시 올리지 않고 새로 추가한 사진만 업로드', () async {
      final uploadCache = NewImageUploadCache();
      final uploader = _RecordingUploader();
      final firstFile = XFile('a.jpg');
      await uploadCache.uploadPendingImages(
        originalFiles: [firstFile],
        compressedFiles: [Future.value(XFile('a.webp'))],
        uploadImages: uploader.upload,
      );

      final imageUrls = await uploadCache.uploadPendingImages(
        originalFiles: [firstFile, XFile('c.jpg')],
        compressedFiles: [Future.value(XFile('a.webp')), Future.value(XFile('c.webp'))],
        uploadImages: uploader.upload,
      );

      expect(uploader.uploadedPathBatches.last, ['c.webp']);
      expect(imageUrls, ['https://image/1-a.webp', 'https://image/2-c.webp']);
    });

    test('모두 올린 상태: 업로드 호출 없이 기억한 주소 반환', () async {
      final uploadCache = NewImageUploadCache();
      final uploader = _RecordingUploader();
      final originalFiles = [XFile('a.jpg')];
      await uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: [Future.value(XFile('a.webp'))],
        uploadImages: uploader.upload,
      );

      final imageUrls = await uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: [Future.value(XFile('a.webp'))],
        uploadImages: uploader.upload,
      );

      expect(uploader.uploadedPathBatches.length, 1);
      expect(imageUrls, ['https://image/1-a.webp']);
    });

    test('업로드 실패: 예외 전달, 기억하지 않아 다음 시도에 다시 업로드', () async {
      final uploadCache = NewImageUploadCache();
      final uploader = _RecordingUploader()..isFailing = true;
      final originalFiles = [XFile('a.jpg')];

      await expectLater(
        uploadCache.uploadPendingImages(
          originalFiles: originalFiles,
          compressedFiles: [Future.value(XFile('a.webp'))],
          uploadImages: uploader.upload,
        ),
        throwsException,
      );
      uploader.isFailing = false;
      await uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: [Future.value(XFile('a.webp'))],
        uploadImages: uploader.upload,
      );

      expect(uploader.uploadedPathBatches.length, 2);
    });

    test('일부만 업로드됨(개수 불일치): 예외, 기억하지 않음', () async {
      final uploadCache = NewImageUploadCache();

      await expectLater(
        uploadCache.uploadPendingImages(
          originalFiles: [XFile('a.jpg'), XFile('b.jpg')],
          compressedFiles: [Future.value(XFile('a.webp')), Future.value(XFile('b.webp'))],
          uploadImages: (files) async => ['https://image/only-one'],
        ),
        throwsException,
      );
    });

    test('업로드 중 사진 삭제 후 재시도: 삭제한 사진은 빠지고 남은 사진은 기억한 주소 재사용', () async {
      final uploadCache = NewImageUploadCache();
      final uploader = _RecordingUploader();
      final firstFile = XFile('a.jpg');
      final secondFile = XFile('b.jpg');
      // 화면이 들고 있는 실시간 목록 (업로드 대기 중 삭제 재현)
      final originalFiles = [firstFile, secondFile];
      final compressedFiles = [Future.value(XFile('a.webp')), Future.value(XFile('b.webp'))];
      final uploadGate = Completer<void>();

      final firstAttempt = uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: compressedFiles,
        uploadImages: (files) async {
          await uploadGate.future;
          return uploader.upload(files);
        },
      );
      await Future<void>.delayed(Duration.zero);
      originalFiles.removeAt(0);
      compressedFiles.removeAt(0);
      uploadGate.complete();

      // 시작 시점 목록 기준으로 짝지음 (어긋남·RangeError 없음)
      expect(await firstAttempt, ['https://image/1-a.webp', 'https://image/2-b.webp']);

      final retryImageUrls = await uploadCache.uploadPendingImages(
        originalFiles: originalFiles,
        compressedFiles: compressedFiles,
        uploadImages: uploader.upload,
      );

      expect(uploader.uploadedPathBatches.length, 1, reason: '남은 사진은 이미 올라가 재업로드 없음');
      expect(retryImageUrls, ['https://image/2-b.webp']);
    });
  });
}
