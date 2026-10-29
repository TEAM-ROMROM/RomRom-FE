import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';

FixedScrollMetrics _metrics({required Axis axis, required double pixels}) => FixedScrollMetrics(
  minScrollExtent: 0,
  maxScrollExtent: 3000,
  pixels: pixels,
  viewportDimension: 800,
  axisDirection: axis == Axis.vertical ? AxisDirection.down : AxisDirection.right,
  devicePixelRatio: 1,
);

void main() {
  group('shouldPrefetchHomeFeed', () {
    test('세로 depth 0 + 끝 근처(뷰포트 1.5배 이내) -> true', () {
      // 임계값 = 3000 - 800 * 1.5 = 1800
      expect(shouldPrefetchHomeFeed(_metrics(axis: Axis.vertical, pixels: 1800), 0), true);
      expect(shouldPrefetchHomeFeed(_metrics(axis: Axis.vertical, pixels: 3000), 0), true);
    });

    test('세로 depth 0 + 끝에서 멀면 -> false', () {
      expect(shouldPrefetchHomeFeed(_metrics(axis: Axis.vertical, pixels: 1799), 0), false);
    });

    test('가로 스크롤 -> false', () {
      expect(shouldPrefetchHomeFeed(_metrics(axis: Axis.horizontal, pixels: 3000), 0), false);
    });

    test('중첩(depth 1) 알림 -> false', () {
      expect(shouldPrefetchHomeFeed(_metrics(axis: Axis.vertical, pixels: 3000), 1), false);
    });
  });
}
