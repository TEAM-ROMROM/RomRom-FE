// lib/models/apis/responses/home_popup_response.dart
import 'package:romrom_fe/models/apis/objects/home_popup.dart';

/// 활성 홈 팝업 조회 응답 (`GET /api/home-popups/active`)
/// 래퍼 형식 2개 허용: {homePopup: {...}} (백엔드 *Response 관례) 또는 팝업 객체 그대로
class HomePopupResponse {
  // 응답 래퍼 안 팝업 키
  static const String homePopupKey = 'homePopup';

  final HomePopup? homePopup;

  const HomePopupResponse({this.homePopup});

  /// 디코딩된 응답 본문 > 응답 (객체 아님·null·homePopup null이면 팝업 없음)
  factory HomePopupResponse.fromJsonBody(Object? body) {
    if (body is! Map<String, dynamic>) return const HomePopupResponse();
    if (body.containsKey(homePopupKey)) {
      final wrappedPopup = body[homePopupKey];
      return HomePopupResponse(
        homePopup: wrappedPopup is Map<String, dynamic> ? HomePopup.fromJson(wrappedPopup) : null,
      );
    }
    return HomePopupResponse(homePopup: HomePopup.fromJson(body));
  }
}
