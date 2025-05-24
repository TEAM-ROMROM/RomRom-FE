import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_types.dart';

/// Navigator 메서드와 대상 screen을 인자로 받는 확장 함수
extension NavigationExtension on BuildContext {
  /// 네비게이션 메서드
  void navigateTo({
    required Widget screen, // 이동할 page
    NavigationTypes type = NavigationTypes.push, // 이동 형식 (기본적으로 Push로 설정)
    RouteSettings? routeSettings, // routing할 때 화면에 넘겨줄 값
    bool Function(Route<dynamic>)? predicate, // 라우트 제거 유무
  }) {
    switch (type) {
      case NavigationTypes.push: // 기존 화면 위에 새 화면 추가
        Navigator.push(
          this,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: routeSettings,
          ),
        );
        break;
      case NavigationTypes.pushReplacement: // 기존 화면을 새 화면으로 대체
        Navigator.pushReplacement(
          this,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: routeSettings,
          ),
        );
        break;
      case NavigationTypes.pushAndRemoveUntil: // 기존 화면을 지우고 새 화면 push
        Navigator.pushAndRemoveUntil(
          this,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: routeSettings,
          ),
          predicate ?? (route) => false, // 기본값은 모든 이전 라우트 제거
        );
        break;
    }
  }
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double adjustedFontSize(BuildContext context, double spSize) {
  final shortestSide = MediaQuery.of(context).size.shortestSide;
  if (shortestSide > 600) {
    // 태블릿 크기 기준
    return (spSize * 0.8).sp; // 태블릿에서는 80% 크기로 조정
  } else {
    return spSize.sp;
  }
}

/// Boxdecoration 색상, radius 설정
/// : color, radius를 인자로 받아 BoxDecoration을 반환
BoxDecoration buildBoxDecoration(Color color, BorderRadius radius) {
  return BoxDecoration(color: color, borderRadius: radius);
}
