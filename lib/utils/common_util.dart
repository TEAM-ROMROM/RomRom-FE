import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_type.dart';

/// api 요청 응답 프린터
void responsePrinter(String url, Map<String, dynamic>? response) {
  debugPrint("👽----$url----👽"); // api 요청 주소 출력
  if (response != null) {
    // 응답 출력
    for (var entry in response.entries) {
      debugPrint('${entry.key} : ${entry.value}');
    }
  }
}

/// Navigator 메서드와 대상 screen을 인자로 받는 확장 함수
extension NavigationExtension on BuildContext {
  /// 네비게이션 메서드
  void navigateTo({
    required Widget screen, // 이동할 page
    NavigationType type = NavigationType.push, // 이동 형식 (기본적으로 Push로 설정)
    RouteSettings? routeSettings, // routing할 때 화면에 넘겨줄 값
    bool Function(Route<dynamic>)? predicate, // 라우트 제거 유무
  }) {
    switch (type) {
      case NavigationType.push: // 기존 화면 위에 새 화면 추가
        Navigator.push(
          this,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: routeSettings,
          ),
        );
        break;
      case NavigationType.pushReplacement: // 기존 화면을 새 화면으로 대체
        Navigator.pushReplacement(
          this,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: routeSettings,
          ),
        );
        break;
      case NavigationType.pushAndRemoveUntil: // 기존 화면을 지우고 새 화면 push
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
