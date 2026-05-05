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
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

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

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
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
