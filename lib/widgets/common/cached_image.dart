import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/utils/image_decode_size.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 디스크 캐싱 네트워크 이미지 ([Image.network] 대체, 재방문 시 네트워크 요청 없음)
/// 디코딩 크기: 확대 보기 > 원본, 지정 크기 > 그 크기, 없거나 무한대 > 레이아웃 제약 첫 유효 크기 고정
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  // 인증 헤더 등 요청 헤더 (캐시 키는 URL 기준)
  final Map<String, String>? httpHeaders;
  // 확대 보기(핀치 줌) 화면이면 true > 원본 해상도 디코딩
  final bool shouldDecodeAtFullResolution;

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
    this.shouldDecodeAtFullResolution = false,
  });

  /// 가로·세로 중 하나라도 유한한 양수로 지정 (레이아웃 측정 없이 디코딩 크기 결정)
  bool get _hasValidDisplaySize =>
      ImageDecodeSize.isValidLogicalSize(width) || ImageDecodeSize.isValidLogicalSize(height);

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

    final Widget image = _buildSizedImage(MediaQuery.devicePixelRatioOf(context));

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  /// 디코딩 크기 결정: 원본(확대 보기) > 지정 크기 > 레이아웃 제약
  Widget _buildSizedImage(double devicePixelRatio) {
    if (shouldDecodeAtFullResolution) return _buildNetworkImage(ImageDecodeSize.original);
    if (_hasValidDisplaySize) {
      return _buildNetworkImage(
        ImageDecodeSize.forDisplay(width: width, height: height, fit: fit, devicePixelRatio: devicePixelRatio),
      );
    }
    return _LockedLayoutDecodeSizeBuilder(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      devicePixelRatio: devicePixelRatio,
      builder: _buildNetworkImage,
    );
  }

  Widget _buildNetworkImage(ImageDecodeSize decodeSize) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: AppImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders,
      memCacheWidth: decodeSize.width,
      memCacheHeight: decodeSize.height,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultError(),
    );
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

/// 레이아웃 제약 > 디코딩 크기: 첫 유효 크기 고정, URL·fit·배율 바뀌면 재계산
/// Hero 복귀 비행·크기 애니메이션 중 제약이 매 프레임 바뀌어도 같은 캐시 키 유지 (깜빡임·반복 디코딩 방지)
class _LockedLayoutDecodeSizeBuilder extends StatefulWidget {
  const _LockedLayoutDecodeSizeBuilder({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fit,
    required this.devicePixelRatio,
    required this.builder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double devicePixelRatio;
  final Widget Function(ImageDecodeSize decodeSize) builder;

  @override
  State<_LockedLayoutDecodeSizeBuilder> createState() => _LockedLayoutDecodeSizeBuilderState();
}

class _LockedLayoutDecodeSizeBuilderState extends State<_LockedLayoutDecodeSizeBuilder> {
  // 처음 확정된 디코딩 크기 (원본 크기는 확정으로 보지 않음 > 유한한 제약이 오면 그때 고정)
  ImageDecodeSize? _lockedDecodeSize;

  @override
  void didUpdateWidget(_LockedLayoutDecodeSizeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasDecodeInputChanged =
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fit != widget.fit ||
        oldWidget.devicePixelRatio != widget.devicePixelRatio;
    if (hasDecodeInputChanged) _lockedDecodeSize = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => widget.builder(_resolveDecodeSize(constraints)));
  }

  ImageDecodeSize _resolveDecodeSize(BoxConstraints constraints) {
    final lockedDecodeSize = _lockedDecodeSize;
    if (lockedDecodeSize != null) return lockedDecodeSize;
    final decodeSize = ImageDecodeSize.forLayout(
      constraints,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      devicePixelRatio: widget.devicePixelRatio,
    );
    if (!decodeSize.isOriginal) _lockedDecodeSize = decodeSize;
    return decodeSize;
  }
}
