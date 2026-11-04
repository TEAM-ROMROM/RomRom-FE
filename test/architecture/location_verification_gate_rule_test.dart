// 규칙 테스트: 동네 인증 필요 기능(등록·교환 요청·채팅 시작·탐색 범위)은 공통 인증 확인(ensureVerified)을 먼저 거친다 (#986)
// lib/ 소스 텍스트 스캔 (진입점 메서드 본문에서 인증 확인 > 기능 실행 순서 확인)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 인증 확인이 필요한 진입점: 파일, 메서드, 목적, 인증 뒤에 와야 하는 기능 실행 코드
class GatedEntryPoint {
  final String filePath;
  final String methodName;
  final String purposeName;
  final String guardedCall;

  const GatedEntryPoint(this.filePath, this.methodName, this.purposeName, this.guardedCall);
}

const gatedEntryPoints = [
  GatedEntryPoint(
    'lib/screens/register_tab_screen.dart',
    '_onRegisterButtonPressed',
    'itemRegistration',
    'ItemRegisterScreen(',
  ),
  GatedEntryPoint(
    'lib/screens/home_tab/home_tab_actions.dart',
    '_onRegisterButtonPressed',
    'itemRegistration',
    'ItemRegisterScreen(',
  ),
  GatedEntryPoint('lib/screens/home_tab/home_tab_actions.dart', '_handleCardDrop', 'tradeRequest', 'hasTradeRequest('),
  GatedEntryPoint(
    'lib/screens/item_detail/item_detail_viewer_actions.dart',
    '_navigateToRequestScreen',
    'tradeRequest',
    'TradeRequestScreen(',
  ),
  GatedEntryPoint(
    'lib/screens/item_detail/item_detail_viewer_actions.dart',
    '_handleChatButtonPressed',
    'chatStart',
    '.createRoom(',
  ),
  GatedEntryPoint(
    'lib/screens/search_range_setting_screen.dart',
    '_onVerifyLocationPressed',
    'searchRangeChange',
    '_initializeData(',
  ),
];

// 기능 실행 코드 > 허용 파일 (새 진입점이 인증 확인 없이 생기는 것 차단)
const allowedFilesByGuardedCall = <String, Set<String>>{
  'TradeRequestScreen(': {
    'lib/screens/trade_request_screen.dart',
    'lib/screens/home_tab/home_tab_actions.dart',
    'lib/screens/item_detail/item_detail_viewer_actions.dart',
  },
  'ItemRegisterScreen(': {
    'lib/screens/item_register_screen.dart',
    'lib/screens/register_tab_screen.dart',
    'lib/screens/home_tab/home_tab_actions.dart',
  },
  '.createRoom(': {'lib/screens/item_detail/item_detail_viewer_actions.dart'},
  // 인증 화면 직접 진입: 공통 확인 + 마이페이지 메뉴(화면 자체가 안내 모달 노출)
  'MyLocationVerificationScreen(': {
    'lib/screens/my_page/my_location_verification_screen.dart',
    'lib/utils/location_verification_gate.dart',
    'lib/screens/my_page_tab_screen.dart',
  },
};

/// 메서드 본문 추출: 선언부터 다음 2칸 들여쓰기 닫는 괄호까지
String extractMethodBody(String source, String methodName) {
  final declaration = RegExp('(?:Future<\\w+>|void)\\s+$methodName\\(').firstMatch(source);
  if (declaration == null) return '';
  final bodyEnd = source.indexOf('\n  }\n', declaration.start);
  return source.substring(declaration.start, bodyEnd == -1 ? source.length : bodyEnd);
}

void main() {
  for (final entryPoint in gatedEntryPoints) {
    test('${entryPoint.filePath} ${entryPoint.methodName} > 인증 확인(${entryPoint.purposeName}) 후 기능 실행', () {
      final body = extractMethodBody(File(entryPoint.filePath).readAsStringSync(), entryPoint.methodName);
      expect(body, isNotEmpty, reason: '메서드를 찾지 못함 (이름 변경 시 이 테스트 갱신)');

      final gateIndex = body.indexOf('ensureVerified(');
      final guardedCallIndex = body.indexOf(entryPoint.guardedCall);
      expect(gateIndex, isNonNegative, reason: '공통 인증 확인 누락');
      expect(body, contains('LocationVerificationPurpose.${entryPoint.purposeName}'));
      expect(guardedCallIndex, greaterThan(gateIndex), reason: '인증 확인보다 기능 실행이 먼저');
    });
  }

  test('탐색 범위 화면 > 미인증이면 범위 지도·슬라이더 대신 인증 안내', () {
    final body = extractMethodBody(
      File('lib/screens/search_range_setting_screen.dart').readAsStringSync(),
      '_initializeData',
    );
    expect(body, contains('isCurrentMemberVerified('));
    expect(body, contains('!isLocationVerified'));
  });

  test('기능 실행 코드는 인증 확인을 거치는 파일에서만 사용', () {
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final entry in allowedFilesByGuardedCall.entries) {
        if (source.contains(entry.key) && !entry.value.contains(entity.path)) {
          violations.add('${entity.path}: ${entry.key}');
        }
      }
    }
    expect(violations, isEmpty, reason: '인증 확인 없는 새 진입점 (LocationVerificationGate.ensureVerified 경유 후 허용 목록에 추가)');
  });
}
