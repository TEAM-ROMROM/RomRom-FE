import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/nickname_rules.dart';

/// 닉네임 입력 안내: 빈 값 > 최대 길이 > 최소 길이 > 허용 문자 > 예약어 (서버 NicknameRule과 같은 규칙)
void main() {
  test('빈 값·공백만 > 입력 요청 문구', () {
    expect(findNicknameInputError(''), nicknameRequiredMessage);
    expect(findNicknameInputError('   '), nicknameRequiredMessage);
  });

  test('허용 문자 2~20자 > 안내 없음 (자동 생성 닉네임 형식 포함)', () {
    expect(findNicknameInputError('롬롬유저1234'), isNull);
    expect(findNicknameInputError('가냘픈나무1234'), isNull);
    expect(findNicknameInputError('trade_lover_99'), isNull);
    expect(findNicknameInputError('가' * maximumNicknameLength), isNull);
  });

  test('최대 길이 초과 > 길이 안내 (붙여넣기 등 입력 제한 우회 대비)', () {
    expect(findNicknameInputError('가' * (maximumNicknameLength + 1)), nicknameTooLongMessage);
  });

  test('1자 > 최소 길이 안내', () {
    expect(findNicknameInputError('가'), nicknameInvalidLengthMessage);
  });

  test('가운데 공백·특수문자·자모 > 허용 문자 안내, 앞뒤 공백은 제거 후 검사', () {
    expect(findNicknameInputError('롬 롬'), nicknameInvalidCharacterMessage);
    expect(findNicknameInputError('롬롬!'), nicknameInvalidCharacterMessage);
    expect(findNicknameInputError('ㄱㄴㄷ'), nicknameInvalidCharacterMessage);
    expect(findNicknameInputError(' 롬롬유저 '), isNull);
  });

  test('예약어 포함 (대소문자 무시) > 예약어 안내', () {
    expect(findNicknameInputError('운영자'), nicknameReservedMessage);
    expect(findNicknameInputError('ADMIN_kim'), nicknameReservedMessage);
    expect(findNicknameInputError('RomRom공식'), nicknameReservedMessage);
  });

  test('저장된 닉네임 그대로 > 규칙 이전 닉네임도 통과', () {
    expect(findNicknameInputError('옛 닉네임!', savedNickname: '옛 닉네임!'), isNull);
    expect(findNicknameInputError('옛 닉네임!!', savedNickname: '옛 닉네임!'), nicknameInvalidCharacterMessage);
  });
}
