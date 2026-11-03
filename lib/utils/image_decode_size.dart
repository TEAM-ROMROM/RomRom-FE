import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 표시 크기(논리 px) > 디코딩 크기(물리 px): 원본 해상도 대신 화면에 그릴 만큼만 디코딩
/// 규칙 4개: none > 원본, cover + 가로·세로 > 긴 변 × 1.8 (가로만), fitHeight > 세로만, 그 외 가로 우선 (없으면 세로)
/// 가로·세로 중 하나만 지정 > 원본 비율 유지, 원본보다 크면 확대 안 함 (ResizeImage 기본값)
@immutable
class ImageDecodeSize {
  const ImageDecodeSize({this.width, this.height});

  // 크기 지정 없음 (원본 해상도 디코딩)
  static const ImageDecodeSize original = ImageDecodeSize();

  // cover + 가로·세로 모두 지정 시 디코딩 배율 (16:9 사진도 박스를 확대 없이 채움)
  static const double coverDecodeScale = 1.8;

  // 레이아웃 기반 디코딩 크기 올림 단위 (애니메이션 등 제약이 조금씩 바뀌어도 같은 캐시 키 유지)
  static const int layoutDecodeStepPixels = 100;

  final int? width;
  final int? height;

  bool get isOriginal => width == null && height == null;

  /// 표시 크기 > 디코딩 크기 (유한한 양수가 아닌 값은 없는 것으로 취급)
  factory ImageDecodeSize.forDisplay({
    double? width,
    double? height,
    required BoxFit fit,
    required double devicePixelRatio,
  }) {
    final validWidth = _toValidLogicalSize(width);
    final validHeight = _toValidLogicalSize(height);
    if (fit == BoxFit.none) return original;

    // cover: 박스 비율 <-> 원본 비율이 달라 한 변이 박스를 넘침 > 긴 변 기준 여유 배율
    if (fit == BoxFit.cover && validWidth != null && validHeight != null) {
      return ImageDecodeSize(width: (math.max(validWidth, validHeight) * devicePixelRatio * coverDecodeScale).round());
    }
    // fitHeight: 세로가 표시 기준 (가로는 박스를 넘을 수 있음)
    if (fit == BoxFit.fitHeight && validHeight != null) {
      return ImageDecodeSize(height: (validHeight * devicePixelRatio).round());
    }
    if (validWidth != null) return ImageDecodeSize(width: (validWidth * devicePixelRatio).round());
    if (validHeight != null) return ImageDecodeSize(height: (validHeight * devicePixelRatio).round());
    return original;
  }

  /// 레이아웃 제약 > 디코딩 크기: 지정 크기 우선, 없거나 무한대면 제약 최대값, 결과는 [layoutDecodeStepPixels] 단위 올림
  factory ImageDecodeSize.forLayout(
    BoxConstraints constraints, {
    double? width,
    double? height,
    required BoxFit fit,
    required double devicePixelRatio,
  }) {
    final displaySize = ImageDecodeSize.forDisplay(
      width: _toValidLogicalSize(width) ?? constraints.maxWidth,
      height: _toValidLogicalSize(height) ?? constraints.maxHeight,
      fit: fit,
      devicePixelRatio: devicePixelRatio,
    );
    return ImageDecodeSize(width: _roundUpToStep(displaySize.width), height: _roundUpToStep(displaySize.height));
  }

  static double? _toValidLogicalSize(double? logicalSize) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) return null;
    return logicalSize;
  }

  static int? _roundUpToStep(int? pixels) {
    if (pixels == null) return null;
    return (pixels / layoutDecodeStepPixels).ceil() * layoutDecodeStepPixels;
  }

  @override
  bool operator ==(Object other) => other is ImageDecodeSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'ImageDecodeSize(width: $width, height: $height)';
}
