import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:romrom_fe/enums/chat_image_save_result.dart';
import 'package:romrom_fe/services/chat_image_gallery_saver.dart';

/// 가짜 앨범 쓰기: 권한 상태·요청 결과·저장 오류 지정, 호출 기록
class FakeGalleryImageWriter implements GalleryImageWriter {
  FakeGalleryImageWriter({required this.hasAccess, this.isRequestGranted = false, this.saveError});

  bool hasAccess;
  final bool isRequestGranted;
  final Object? saveError;
  int requestCount = 0;
  final List<String> savedFileNames = [];

  @override
  Future<bool> hasSaveAccess() async => hasAccess;

  @override
  Future<bool> requestSaveAccess() async {
    requestCount++;
    hasAccess = isRequestGranted;
    return isRequestGranted;
  }

  @override
  Future<void> saveJpegBytes(Uint8List jpegBytes, {required String fileName}) async {
    final error = saveError;
    if (error != null) throw error;
    savedFileNames.add(fileName);
  }
}

GalException buildGalException(GalExceptionType type) => GalException(
  type: type,
  platformException: PlatformException(code: type.code),
  stackTrace: StackTrace.empty,
);

/// 채팅 사진 앨범 저장 (#987): 버튼 탭 시점 권한 확인·요청 1회, 거부면 저장 없이 권한 거부 결과
void main() {
  late List<String> loadedImageUrls;

  ChatImageGallerySaver buildSaver(FakeGalleryImageWriter writer, {Uint8List? convertedBytes}) {
    return ChatImageGallerySaver(
      galleryImageWriter: writer,
      loadImageFile: (imageUrl) async {
        loadedImageUrls.add(imageUrl);
        return File('/cache/photo.webp');
      },
      convertToJpegBytes: (_) async => convertedBytes,
    );
  }

  setUp(() => loadedImageUrls = []);

  test('권한 있음 > 요청 없이 JPEG 저장, 결과 저장됨', () async {
    final writer = FakeGalleryImageWriter(hasAccess: true);

    final saveResult = await buildSaver(
      writer,
      convertedBytes: Uint8List.fromList([1, 2]),
    ).saveNetworkImage('https://image/1.webp');

    expect(saveResult, ChatImageSaveResult.saved);
    expect(writer.requestCount, 0);
    expect(writer.savedFileNames.single, startsWith(ChatImageGallerySaver.savedFileNamePrefix));
    expect(loadedImageUrls, ['https://image/1.webp']);
  });

  test('권한 없음 > 요청 1회 허용 > 저장', () async {
    final writer = FakeGalleryImageWriter(hasAccess: false, isRequestGranted: true);

    final saveResult = await buildSaver(writer, convertedBytes: Uint8List.fromList([1])).saveNetworkImage('u');

    expect(saveResult, ChatImageSaveResult.saved);
    expect(writer.requestCount, 1);
  });

  test('권한 요청 거부 > 사진 받기·저장 없이 권한 거부 결과 (설정 안내 대상, 반복 요청 없음)', () async {
    final writer = FakeGalleryImageWriter(hasAccess: false);

    final saveResult = await buildSaver(writer, convertedBytes: Uint8List.fromList([1])).saveNetworkImage('u');

    expect(saveResult, ChatImageSaveResult.permissionDenied);
    expect(writer.requestCount, 1);
    expect(writer.savedFileNames, isEmpty);
    expect(loadedImageUrls, isEmpty);
  });

  test('저장 중 권한 거부 예외 > 권한 거부 결과, 공간 부족 등 그 외 > 실패', () async {
    final deniedWriter = FakeGalleryImageWriter(
      hasAccess: true,
      saveError: buildGalException(GalExceptionType.accessDenied),
    );
    final noSpaceWriter = FakeGalleryImageWriter(
      hasAccess: true,
      saveError: buildGalException(GalExceptionType.notEnoughSpace),
    );
    final bytes = Uint8List.fromList([1]);

    expect(
      await buildSaver(deniedWriter, convertedBytes: bytes).saveNetworkImage('u'),
      ChatImageSaveResult.permissionDenied,
    );
    expect(await buildSaver(noSpaceWriter, convertedBytes: bytes).saveNetworkImage('u'), ChatImageSaveResult.failed);
  });

  test('JPEG 변환 실패(null) > 저장 없이 실패', () async {
    final writer = FakeGalleryImageWriter(hasAccess: true);

    expect(await buildSaver(writer).saveNetworkImage('u'), ChatImageSaveResult.failed);
    expect(writer.savedFileNames, isEmpty);
  });

  test('사진 받기 실패(네트워크) > 예외 없이 실패 결과', () async {
    final saver = ChatImageGallerySaver(
      galleryImageWriter: FakeGalleryImageWriter(hasAccess: true),
      loadImageFile: (_) async => throw const SocketException('offline'),
      convertToJpegBytes: (_) async => Uint8List.fromList([1]),
    );

    expect(await saver.saveNetworkImage('u'), ChatImageSaveResult.failed);
  });
}
