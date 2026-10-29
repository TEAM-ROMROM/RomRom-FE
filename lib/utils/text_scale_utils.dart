import 'package:flutter/widgets.dart';

// 앱 글자 크기 배율 범위: 고정 높이 레이아웃 overflow 방지를 위해 상한 1.2
const double minimumAppTextScaleFactor = 1.0;
const double maximumAppTextScaleFactor = 1.2;

/// 시스템 글자 크기 > 앱 허용 범위(1.0~1.2배)로 보정
TextScaler clampAppTextScaler(TextScaler systemScaler) {
  return systemScaler.clamp(minScaleFactor: minimumAppTextScaleFactor, maxScaleFactor: maximumAppTextScaleFactor);
}
