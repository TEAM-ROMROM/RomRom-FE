import 'package:flutter/material.dart';

/// 물품 카드 비율 계산 유틸리티 클래스
class ItemCardScale {
  final double scale;

  const ItemCardScale(this.scale);

  // 주어진 값에 scale 비율을 곱해서 반환
  double s(double value) => value * scale;

  // 주어진 fontSize에 scale 비율 적용
  double fontSize(double value) => value * scale;

  // 수평/수직 padding을 scale 비율로 계산
  EdgeInsets padding(double h, double v) => EdgeInsets.symmetric(horizontal: s(h), vertical: s(v));

  // margin을 scale 비율로 계산
  EdgeInsets margin({double l = 0, double t = 0, double r = 0, double b = 0}) =>
      EdgeInsets.fromLTRB(s(l), s(t), s(r), s(b));

  // border radius를 scale 비율로 계산
  BorderRadius radius(double r) => BorderRadius.circular(s(r));

  // 높이만 있는 SizedBox 생성 (scale 적용)
  SizedBox sizedBoxH(double h) => SizedBox(height: s(h));
}

/// ChangeNotifier 기반의 scale 관리
class ItemCardScaleProvider with ChangeNotifier {
  ItemCardScale _scale = const ItemCardScale(1.0);

  // baseWidth 기준으로 현재 scale 계산 및 갱신
  void setScale(double baseWidth, double currentWidth) {
    _scale = ItemCardScale(currentWidth / baseWidth);
    notifyListeners();
  }

  ItemCardScale get scale => _scale;
}
