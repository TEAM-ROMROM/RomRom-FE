import 'dart:ui';

import 'package:flutter/material.dart';

/// child를 블러처리하는 위젯
class BlurWrapper extends StatelessWidget {
  final bool enabled;
  final double sigma; // 블러 강도
  final Widget child;

  const BlurWrapper({super.key, required this.enabled, this.sigma = 8, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
