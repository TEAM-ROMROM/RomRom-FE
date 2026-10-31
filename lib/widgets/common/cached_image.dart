import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 캐싱이 적용된 네트워크 이미지 위젯
///
/// [Image.network] 대신 사용하면 이미지가 디스크에 캐싱되어
/// 재방문 시 네트워크 요청 없이 빠르게 로드됩니다.
class CachedImage extends StatelessWidget {
  // cover + 가로·세로 모두 지정 시 디코딩 배율 (16:9까지 확대 없이 표시)
  static const double coverDecodeScale = 1.8;

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  // 인증 헤더 등 요청 헤더 (캐시 키는 URL 기준)
  final Map<String, String>? httpHeaders;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.httpHeaders,
  });

  /// cover + 가로·세로 모두 유효 (박스 비율과 원본 비율이 달라 잘림 발생)
  bool get _hasCoverBox =>
      fit == BoxFit.cover && _toDecodePixels(width, 1) != null && _toDecodePixels(height, 1) != null;

  /// 긴 변 기준 디코딩 크기 (가로로 긴 사진도 박스를 채우도록 coverDecodeScale 배)
  int _toCoverDecodePixels(double devicePixelRatio) =>
      (math.max(width!, height!) * devicePixelRatio * coverDecodeScale).round();

  /// 표시 크기(논리 px) > 디코딩 크기(물리 px), 유한한 양수가 아니면 null (원본 크기 디코딩)
  static int? _toDecodePixels(double? logicalSize, double devicePixelRatio) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) return null;
    return (logicalSize * devicePixelRatio).round();
  }

  @override
  Widget build(BuildContext context) {
    // 빈 URL 방어 처리
    if (imageUrl.trim().isEmpty) {
      final fallback = errorWidget ?? _buildDefaultError();
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    // cover + 폭·높이 지정: 긴 변 × 1.8, 그 외 폭 우선
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final memCacheWidth = _hasCoverBox
        ? _toCoverDecodePixels(devicePixelRatio)
        : _toDecodePixels(width, devicePixelRatio);
    final memCacheHeight = memCacheWidth == null ? _toDecodePixels(height, devicePixelRatio) : null;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultError(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  /// 기본 로딩 플레이스홀더 — shimmer 효과
  Widget _buildDefaultPlaceholder() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: Container(width: width, height: height, color: AppColors.secondaryBlack1),
    );
  }

  /// 기본 에러 위젯
  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondaryBlack1,
      child: const Center(child: Icon(AppIcons.itmeRegisterImage, color: AppColors.opacity40White)),
    );
  }
}
