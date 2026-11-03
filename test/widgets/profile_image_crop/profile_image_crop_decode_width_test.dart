import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/screens/my_page/profile_image_crop_screen.dart';

/// 프로필 자르기 디코딩 폭 검증: max(화면 물리 폭, 결과 크기 × 최대 확대), 원본보다 크게는 안 늘림
void main() {
  test('원본 4032 > max(화면 1179, 500 x 5 = 2500) = 2500', () {
    expect(ProfileImageCropScreen.toDecodeTargetWidth(intrinsicWidth: 4032, screenPhysicalWidth: 1179), 2500);
  });

  test('화면 물리 폭이 더 크면 화면 폭 (iPad 2732)', () {
    expect(ProfileImageCropScreen.toDecodeTargetWidth(intrinsicWidth: 4032, screenPhysicalWidth: 2732), 2732);
  });

  test('원본이 목표보다 작음 > null (원본 그대로, 확대 안 함)', () {
    expect(ProfileImageCropScreen.toDecodeTargetWidth(intrinsicWidth: 1200, screenPhysicalWidth: 1179), isNull);
  });

  test('화면 크기 모름 > 결과 크기 x 최대 확대 기준', () {
    expect(ProfileImageCropScreen.toDecodeTargetWidth(intrinsicWidth: 4032, screenPhysicalWidth: null), 2500);
  });
}
