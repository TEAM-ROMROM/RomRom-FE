import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class ImageApi {
  // 싱글톤 구현
  static final ImageApi _instance = ImageApi._internal();

  factory ImageApi() => _instance;

  ImageApi._internal();

  /// 사진 등록 API
  /// `POST /api/image/upload`
  Future<List<String>> uploadImages(List<XFile> images) async {
    const String url = '${AppUrls.baseUrl}/api/image/upload';
    List<String> imageUrls = [];

    // 타입 안전하게 파일 처리
    Map<String, List<File>>? fileMap;
    if (images.isNotEmpty) {
      fileMap = {'images': images.map((xFile) => File(xFile.path)).toList()};
    }

    await ApiClient.sendMultipartRequest(
      url: url,
      files: fileMap,
      isAuthRequired: true,
      onSuccess: (responseData) {
        final urls = responseData['imageUrls'];
        if (urls is! List) {
          throw const FormatException('imageUrls 필드 누락 또는 형식 오류');
        }
        imageUrls = urls.map((e) => e.toString()).toList(growable: false);
        debugPrint('사진 등록 성공: $imageUrls');
      },
    );

    return imageUrls;
  }

  /// 물품 삭제 API
  /// `POST /api/item/delete`
  Future<void> deleteImages(List<String> imageUrls) async {
    const String url = '${AppUrls.baseUrl}/api/image/delete';

    final Map<String, dynamic> fields = {
      'imageUrls': imageUrls.join(','),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('사진 삭제 성공: $imageUrls');
      },
    );
  }
}
