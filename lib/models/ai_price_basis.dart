import 'package:flutter/foundation.dart';

/// AI 가격 측정 기준 입력: 제목·설명·물건 상태 (이 값이 바뀌면 AI 가격 표시 해제)
@immutable
class AiPriceBasis {
  final String itemName;
  final String itemDescription;
  // 물건 상태 서버 이름 (미선택 > null)
  final String? itemCondition;

  const AiPriceBasis({required this.itemName, required this.itemDescription, required this.itemCondition});

  /// 현재 입력 <-> 측정 기준 비교 (앞뒤 공백 무시)
  bool isSameInput({required String itemName, required String itemDescription, required String? itemCondition}) {
    return this.itemName.trim() == itemName.trim() &&
        this.itemDescription.trim() == itemDescription.trim() &&
        this.itemCondition == itemCondition;
  }
}
