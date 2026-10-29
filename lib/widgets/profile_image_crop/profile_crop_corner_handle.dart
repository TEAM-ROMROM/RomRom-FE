// 프로필 사진 크롭 꼭지점 핸들: 40px 터치 영역 + 18px 꺾쇠 모양, 드래그 시작·이동·종료 콜백
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 크롭 꼭지점 핸들: 모서리 방향별 꺾쇠 표시, 드래그 처리는 화면 콜백 (종료·취소 공통 onDragEnd)
class ProfileCropCornerHandle extends StatelessWidget {
  // 터치 영역 한 변 (px)
  static const double hitSizePixels = 40.0;
  // 보이는 꺾쇠 한 변 (px)
  static const double visualSizePixels = 18.0;

  // 왼쪽 모서리 핸들이면 true (꺾쇠 구멍이 오른쪽)
  final bool isLeftCorner;
  // 위쪽 모서리 핸들이면 true (꺾쇠 구멍이 아래쪽)
  final bool isTopCorner;
  final VoidCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const ProfileCropCornerHandle({
    super.key,
    required this.isLeftCorner,
    required this.isTopCorner,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,

      child: Container(
        width: hitSizePixels,
        height: hitSizePixels,
        decoration: const BoxDecoration(color: AppColors.transparent, shape: BoxShape.circle),
        child: Center(
          child: SizedBox(
            width: visualSizePixels,
            height: visualSizePixels,
            child: CustomPaint(
              painter: _CornerHandlePainter(holeAtRight: isLeftCorner, holeAtBottom: isTopCorner),
            ),
          ),
        ),
      ),
    );
  }
}

/// 꼭지점 핸들 Painter
class _CornerHandlePainter extends CustomPainter {
  final bool holeAtRight;
  final bool holeAtBottom;

  const _CornerHandlePainter({required this.holeAtRight, required this.holeAtBottom});

  static const double _shapeSize = 16.0;
  static const double _holeSize = 12.0;
  static const double _gapSize = _shapeSize - _holeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final offsetX = (size.width - _shapeSize) / 2 + (holeAtRight ? _gapSize : -_gapSize);
    final offsetY = (size.height - _shapeSize) / 2 + (holeAtBottom ? _gapSize : -_gapSize);
    final holeX = offsetX + (holeAtRight ? _shapeSize - _holeSize : 0.0);
    final holeY = offsetY + (holeAtBottom ? _shapeSize - _holeSize : 0.0);

    final paint = Paint()..color = AppColors.textColorWhite;
    final path = Path()
      ..addRect(Rect.fromLTWH(offsetX, offsetY, _shapeSize, _shapeSize))
      ..addRect(Rect.fromLTWH(holeX, holeY, _holeSize, _holeSize))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerHandlePainter old) =>
      old.holeAtRight != holeAtRight || old.holeAtBottom != holeAtBottom;
}
