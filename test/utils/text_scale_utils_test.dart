import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/text_scale_utils.dart';

void main() {
  group('clampAppTextScaler', () {
    test('시스템 1.5배 > 최대 1.2배로 제한', () {
      expect(clampAppTextScaler(const TextScaler.linear(1.5)).scale(10), closeTo(12, 0.001));
    });

    test('시스템 0.8배 > 최소 1.0배로 보정', () {
      expect(clampAppTextScaler(const TextScaler.linear(0.8)).scale(10), closeTo(10, 0.001));
    });

    test('시스템 1.1배 > 그대로 유지', () {
      expect(clampAppTextScaler(const TextScaler.linear(1.1)).scale(10), closeTo(11, 0.001));
    });

    test('시스템 기본 1.0배 > 그대로 유지', () {
      expect(clampAppTextScaler(TextScaler.noScaling).scale(10), closeTo(10, 0.001));
    });
  });
}
