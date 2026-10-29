import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/services/apis/image_api.dart';

/// 이미지 저장소: 업로드, 삭제 (ImageApi 래핑, UI 모름)
class ImageRepository {
  final ImageApi _api;

  ImageRepository(this._api);

  /// 이미지 파일 목록 > 업로드된 이미지 URL 목록
  Future<List<String>> uploadImages(List<XFile> images) => _api.uploadImages(images);

  /// 업로드된 이미지 URL 목록 삭제
  Future<void> deleteImages(List<String> imageUrls) => _api.deleteImages(imageUrls);
}
