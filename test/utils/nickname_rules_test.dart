import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/nickname_rules.dart';

/// 닉네임 입력 안내: 빈 값·공백만 > 입력 요청, 최대 길이 이내 > 통과
void main() {
  test('빈 값·공백만 > 입력 요청 문구', () {
    expect(findNicknameInputError(''), nicknameRequiredMessage);
    expect(findNicknameInputError('   '), nicknameRequiredMessage);
  });

  test('최대 길이 이내 > 안내 없음', () {
    expect(findNicknameInputError('롬롬유저1234'), isNull);
    expect(findNicknameInputError('가' * maximumNicknameLength), isNull);
  });

  test('최대 길이 초과 > 길이 안내 (붙여넣기 등 입력 제한 우회 대비)', () {
    expect(findNicknameInputError('가' * (maximumNicknameLength + 1)), nicknameTooLongMessage);
  });
}
