import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/utils/image_decode_size.dart';

/// CachedImage와 같은 키의 이미지 provider: 디스크 캐시(AppImageCacheManager) + 표시 크기 디코딩(ResizeImage)
/// CachedNetworkImage가 memCacheWidth·memCacheHeight로 감싸는 방식과 동일 > 미리 받은 이미지를 카드가 그대로 사용
ImageProvider buildCachedImageProvider(
  BuildContext context, {
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final decodeSize = ImageDecodeSize.forDisplay(
    width: width,
    height: height,
    fit: fit,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );
  return ResizeImage.resizeIfNeeded(
    decodeSize.width,
    decodeSize.height,
    CachedNetworkImageProvider(imageUrl, cacheManager: AppImageCacheManager.instance),
  );
}

/// 화면에 그리기 전 이미지 미리 받기·디코딩 (실패는 로그만, 카드가 그릴 때 다시 시도)
Future<void> precacheCachedImage(
  BuildContext context, {
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final imageProvider = buildCachedImageProvider(context, imageUrl: imageUrl, width: width, height: height, fit: fit);
  return precacheImage(
    imageProvider,
    context,
    onError: (error, stackTrace) => debugPrint('[image precache] failed : $error'),
  );
}
