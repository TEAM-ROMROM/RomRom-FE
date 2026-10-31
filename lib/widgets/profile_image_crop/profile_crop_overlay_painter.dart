// 프로필 사진 크롭 오버레이: 원 바깥 반투명, rect·원 테두리, 핸들 드래그 중 3등분 격자
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 크롭 오버레이 Painter
/// - rect 내부(원 외부): 반투명 검정 오버레이
/// - rect 테두리, 원 테두리, 원 내부 rule of thirds 격자선
class ProfileCropOverlayPainter extends CustomPainter {
  final double rectLeft;
  final double rectTop;
  final double rectW;
  final double rectH;
  final Animation<double> gridOpacity;

  const ProfileCropOverlayPainter({
    required this.rectLeft,
    required this.rectTop,
    required this.rectW,
    required this.rectH,
    required this.gridOpacity,
  }) : super(repaint: gridOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(rectLeft, rectTop, rectW, rectH);

    final circleRadius = math.min(rectW, rectH) / 2;
    final circleCenter = Offset(rectLeft + rectW / 2, rectTop + rectH / 2);

    // rect 내부(원 외부) 반투명 오버레이
    final overlayPaint = Paint()..color = AppColors.opacity40PrimaryBlack;

    final overlayPath = Path()
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // 격자선: 핸들 드래그 중에만 fade-in / fade-out
    final opacity = gridOpacity.value;

    // 격자선: rect 전체 기준 3등분
    if (opacity > 0.01) {
      final gridPaint = Paint()
        ..color = AppColors.textColorWhite.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      // 세로선 2개
      for (int i = 1; i <= 2; i++) {
        final x = rectLeft + rectW * i / 3;
        canvas.drawLine(Offset(x, rectTop), Offset(x, rectTop + rectH), gridPaint);
      }

      // 가로선 2개
      for (int i = 1; i <= 2; i++) {
        final y = rectTop + rectH * i / 3;
        canvas.drawLine(Offset(rectLeft, y), Offset(rectLeft + rectW, y), gridPaint);
      }
    }

    // rect 테두리
    final borderPaint = Paint()
      ..color = AppColors.textColorWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRect(rect, borderPaint);

    // 원 테두리
    canvas.drawCircle(circleCenter, circleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ProfileCropOverlayPainter oldDelegate) {
    return rectLeft != oldDelegate.rectLeft ||
        rectTop != oldDelegate.rectTop ||
        rectW != oldDelegate.rectW ||
        rectH != oldDelegate.rectH;
  }
}
