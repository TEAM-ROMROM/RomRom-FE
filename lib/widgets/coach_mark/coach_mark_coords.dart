import 'dart:math' as math;

/// 코치마크 배경 이미지(393×852 기준) 좌표를
/// BoxFit.cover 기준으로 현재 화면 좌표로 변환하는 헬퍼.
///
/// 배경은 BoxFit.cover로 렌더링되므로 기기 비율에 따라
/// scale/crop이 달라진다. 이 클래스는 디자인 좌표를 항상
/// 배경 이미지 위에 정확히 오버레이되도록 변환한다.
class CoachMarkCoords {
  static const double kDesignW = 393.0;
  static const double kDesignH = 852.0;

  final double screenW;
  final double screenH;
  final double scale;
  final double offsetX;
  final double offsetY;

  CoachMarkCoords(this.screenW, this.screenH)
    : scale = math.max(screenW / kDesignW, screenH / kDesignH),
      offsetX = (math.max(screenW / kDesignW, screenH / kDesignH) * kDesignW - screenW) / 2,
      offsetY = (math.max(screenW / kDesignW, screenH / kDesignH) * kDesignH - screenH) / 2;

  /// 디자인 left(px) → 화면 left
  double left(double x) => x * scale - offsetX;

  /// 디자인 right(px from right edge) → 화면 right
  double right(double x) => screenW - (kDesignW - x) * scale + offsetX;

  /// 디자인 top(px from top) → 화면 top
  double top(double y) => y * scale - offsetY;

  /// 디자인 bottom(px from bottom) → 화면 bottom
  double bottom(double y) => screenH - (kDesignH - y) * scale + offsetY;

  /// 디자인 bottom 비율(0~1) → 화면 bottom
  double bottomRatio(double ratio) => bottom(kDesignH * ratio);

  /// 디자인 크기(px) → 화면 크기 (width/height 모두 동일 scale 적용)
  double px(double d) => d * scale;
}
