import 'package:flutter/material.dart';

/// 물품 카드 비율 계산 유틸리티
class GoodsCardScale {
  final double scale;

  const GoodsCardScale(this.scale);

  double s(double value) => value * scale;
  double fontSize(double value) => value * scale;
  EdgeInsets padding(double h, double v) =>
      EdgeInsets.symmetric(horizontal: s(h), vertical: s(v));
  EdgeInsets margin({double l = 0, double t = 0, double r = 0, double b = 0}) =>
      EdgeInsets.fromLTRB(s(l), s(t), s(r), s(b));
  BorderRadius radius(double r) => BorderRadius.circular(s(r));
  SizedBox sizedBoxH(double h) => SizedBox(height: s(h));
}

class GoodsCardScaleProvider with ChangeNotifier {
  GoodsCardScale _scale = const GoodsCardScale(1.0);

  void setScale(double baseWidth, double currentWidth) {
    _scale = GoodsCardScale(currentWidth / baseWidth);
    notifyListeners();
  }

  GoodsCardScale get scale => _scale;
}
