import 'package:romrom_fe/services/apis/home_popup_api.dart';

/// 홈 팝업 API 대역: 응답 본문 또는 예외 지정, 조회 횟수 기록
class FakeHomePopupApi implements HomePopupApi {
  Object? responseBody;
  Object? errorToThrow;
  int fetchCount = 0;

  @override
  Future<Object?> fetchActiveHomePopupBody() async {
    fetchCount++;
    final error = errorToThrow;
    if (error != null) throw error;
    return responseBody;
  }
}

/// 정상 팝업 JSON (백엔드 #749 계약 키, 선택 필드 지정 가능)
Map<String, dynamic> buildPopupJson({
  String homePopupId = 'popup-1',
  String? imageUrl = 'https://cdn.example.com/popup.png',
  String? linkUrl = 'https://romrom.example.com/event',
}) => {
  'homePopupId': homePopupId,
  'title': '봄맞이 교환 이벤트',
  'description': '이번 주 교환하면 선물 증정',
  'imageUrl': ?imageUrl,
  'linkUrl': ?linkUrl,
  'priority': 10,
  'isActive': true,
  'startDate': '2026-10-01T00:00:00',
  'endDate': [2026, 11, 30, 23, 59, 0],
};
