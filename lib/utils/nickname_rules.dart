// 닉네임 규칙 단일 원본 (서버 NicknameRule과 같은 규칙·문구, 바꾸면 함께 변경)
// 길이 2~20자 (서버와 같은 UTF-16 길이), 완성형 한글·영문·숫자·밑줄만, 예약어 포함 금지

const int minimumNicknameLength = 2;
// 서버 관리자 닉네임 수정 상한과 같은 값
const int maximumNicknameLength = 20;

const String nicknameRequiredMessage = '닉네임을 입력해주세요';
const String nicknameTooLongMessage = '닉네임은 $maximumNicknameLength자까지 입력할 수 있어요';
// 서버 에러 코드 문구와 같은 값 (lib/enums/error_code.dart가 참조)
const String nicknameInvalidLengthMessage = '닉네임은 $minimumNicknameLength자 이상 $maximumNicknameLength자 이하로 입력해 주세요.';
const String nicknameInvalidCharacterMessage = '닉네임은 한글, 영문, 숫자, 밑줄(_)만 사용할 수 있어요.';
const String nicknameReservedMessage = '사용할 수 없는 닉네임이에요.';

// 운영 주체 사칭 방지 예약어 (대소문자 무시, 부분 포함도 금지)
const List<String> reservedNicknameWords = ['운영자', '관리자', 'admin', 'romrom'];

final RegExp _allowedNicknamePattern = RegExp(r'^[가-힣a-zA-Z0-9_]+$');

/// 닉네임 입력 안내 문구 (빈 값 > 최대 길이 > 최소 길이 > 허용 문자 > 예약어), 문제없으면 null
/// [savedNickname]과 같으면 빈 값만 검사 (규칙 이전 닉네임으로 사진만 바꾸는 경우 허용)
/// 앞뒤 공백은 저장 시 제거되므로 제거한 값으로 검사, 중복·부적절한 표현은 서버 응답으로 안내
String? findNicknameInputError(String nickname, {String? savedNickname}) {
  final trimmedNickname = nickname.trim();
  if (trimmedNickname.isEmpty) return nicknameRequiredMessage;
  if (savedNickname != null && trimmedNickname == savedNickname.trim()) return null;
  if (nickname.length > maximumNicknameLength) return nicknameTooLongMessage;
  if (trimmedNickname.length < minimumNicknameLength) return nicknameInvalidLengthMessage;
  if (!_allowedNicknamePattern.hasMatch(trimmedNickname)) return nicknameInvalidCharacterMessage;
  if (_containsReservedWord(trimmedNickname)) return nicknameReservedMessage;
  return null;
}

bool _containsReservedWord(String nickname) {
  final lowerCaseNickname = nickname.toLowerCase();
  return reservedNicknameWords.any(lowerCaseNickname.contains);
}
