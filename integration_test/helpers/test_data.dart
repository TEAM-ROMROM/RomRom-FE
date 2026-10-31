import 'package:intl/intl.dart';

// 물품 제목 접두어 (실행 중 생성한 테스트 물품 구분)
const String testItemTitlePrefix = 'E2E ';

// 물품 설명 (서버 검증: 10자 이상)
const String testItemDescription = 'Patrol E2E 테스트로 등록한 물품입니다. 확인 후 삭제됩니다.';

// 물품 가격 입력값 (원)
const String testItemPriceInput = '10000';

/// 실행마다 다른 테스트 물품 제목 (제목 20자 제한: 접두어 4자 + 월일시분초 10자)
String createUniqueTestItemTitle() {
  return '$testItemTitlePrefix${DateFormat('MMddHHmmss').format(DateTime.now())}';
}
