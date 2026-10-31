import 'package:flutter/widgets.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';

/// E2E(Patrol) 위젯 탐색용 Key 단일 원본: 문구·아이콘으로 구분 불가한 위젯만 등록 (앱 동작 무관)
/// 사용처 <-> integration_test/flows/*.dart 와 함께 변경
class AppTestKeys {
  AppTestKeys._();

  /// 물품 등록·수정 폼 입력칸: 제목, 설명, 가격, 거래 희망 위치 (입력 전후 힌트 문구가 달라 문구 탐색 불가)
  static Key itemRegisterField(ItemTextFieldPhrase phrase) => ValueKey<String>('itemRegisterField_${phrase.name}');

  /// 홈 탭 알림함 진입 버튼 (미확인 배지 유무로 아이콘이 바뀜)
  static const Key homeNotificationButton = ValueKey<String>('homeNotificationButton');

  /// 요청하기 화면 하단 '요청하기' 제출 버튼 (앱바 제목과 문구 중복)
  static const Key tradeRequestSubmitButton = ValueKey<String>('tradeRequestSubmitButton');
}
