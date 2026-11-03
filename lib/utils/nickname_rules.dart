// 닉네임 최대 글자 수 (서버 관리자 닉네임 수정 검증 MAXIMUM_NICKNAME_LENGTH = 20과 같은 값, 서버와 같은 UTF-16 길이 기준)
const int maximumNicknameLength = 20;

const String nicknameRequiredMessage = '닉네임을 입력해주세요';
const String nicknameTooLongMessage = '닉네임은 $maximumNicknameLength자까지 입력할 수 있어요';

/// 닉네임 입력 안내 문구 (빈 값·공백만, 최대 길이 초과), 문제없으면 null
/// 중복·부적절한 표현은 저장 시 서버 응답으로 안내
String? findNicknameInputError(String nickname) {
  if (nickname.trim().isEmpty) return nicknameRequiredMessage;
  if (nickname.length > maximumNicknameLength) return nicknameTooLongMessage;
  return null;
}
