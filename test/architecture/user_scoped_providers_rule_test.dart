// 규칙 테스트: Notifier 계열 provider는 userScopedProviders(로그아웃 초기화 목록) 등록 또는 명시 예외 필수
// lib/ 소스 텍스트의 최상위 선언 스캔 (리플렉션 미사용, provider.name은 null이라 소스에서 이름 추출)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';

// 회원별 데이터가 아니라 초기화 불필요한 provider (이름 > 이유)
const exemptProviderReasons = <String, String>{
  // 화면 위젯 크기·스케일 UI 상태 (회원 데이터 아님)
  'itemCardProvider': 'UI 전용 카드 스케일 상태, 회원별 데이터 아님',
  // 비로그인 포함 공통 공지 팝업, 노출 기록은 앱 실행 단위 (재로그인 시 같은 실행 재노출 방지)
  'homePopupProvider': '회원 무관 공지·이벤트 팝업, 세션 노출 기록은 앱 실행 단위',
};

// 최상위 provider 선언: final xxxProvider = [AsyncNotifier|Notifier|StateNotifier|State]Provider[.autoDispose][.family][<...>](
final stateProviderDeclaration = RegExp(
  r'^final\s+(\w+)\s*=\s*(?:AsyncNotifier|Notifier|StateNotifier|State)Provider\b',
  multiLine: true,
);

/// lib/ 아래 dart 파일의 상태 provider 선언 이름 수집 (이름 > 선언 파일)
Map<String, String> collectStateProviderDeclarations() {
  final declarations = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    for (final match in stateProviderDeclaration.allMatches(source)) {
      declarations[match.group(1)!] = entity.path;
    }
  }
  return declarations;
}

// userScopedProviders 리스트 리터럴 본문
final registeredListBody = RegExp(r'userScopedProviders\s*=\s*\[([^\]]*)\]');

/// user_scoped_providers.dart 소스에서 등록된 provider 이름 추출 (주석 제거 후 식별자 단위)
Set<String> collectRegisteredProviderNames() {
  final source = File('lib/providers/user_scoped_providers.dart').readAsStringSync();
  final body = registeredListBody.firstMatch(source)!.group(1)!.replaceAll(RegExp(r'//.*'), '');
  return RegExp(r'\w+').allMatches(body).map((match) => match.group(0)!).toSet();
}

void main() {
  test('Notifier 계열 provider는 userScopedProviders에 있거나 예외 목록에 이유와 함께 있어야 한다', () {
    final declarations = collectStateProviderDeclarations();
    // 스캔 자체가 깨져 아무것도 못 찾는 경우 방지
    expect(declarations, isNotEmpty, reason: 'provider 선언 스캔 결과가 비어 있음 (정규식 점검 필요)');

    final registeredNames = collectRegisteredProviderNames();
    final unregistered = declarations.entries
        .where((entry) => !registeredNames.contains(entry.key) && !exemptProviderReasons.containsKey(entry.key))
        .map((entry) => '${entry.key} (${entry.value})')
        .toList();

    expect(
      unregistered,
      isEmpty,
      reason:
          'userScopedProviders 미등록 provider: $unregistered\n'
          '회원 데이터면 lib/providers/user_scoped_providers.dart에 추가, 아니면 이 테스트 예외 목록에 이유와 함께 추가',
    );
  });

  test('등록 항목은 소스에 선언된 provider이고 런타임 목록 개수와 일치해야 한다', () {
    final declaredNames = collectStateProviderDeclarations().keys.toSet();
    final registeredNames = collectRegisteredProviderNames();
    final missing = registeredNames.where((name) => !declaredNames.contains(name)).toList();
    expect(missing, isEmpty, reason: '선언을 찾지 못한 등록 항목: $missing');
    // 소스 파싱 결과 <-> 실제 리스트 개수 (파싱 누락 감지)
    expect(registeredNames.length, userScopedProviders.length);
  });

  test('예외 목록은 실제 선언된 provider만 가리켜야 한다', () {
    final declaredNames = collectStateProviderDeclarations().keys.toSet();
    final stale = exemptProviderReasons.keys.where((name) => !declaredNames.contains(name)).toList();
    expect(stale, isEmpty, reason: '더 이상 없는 예외 항목: $stale');
  });
}
