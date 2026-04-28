/// UGC(사용자 생성 콘텐츠) 필터링 위반 시 발생하는 예외
/// 백엔드에서 400 PROHIBITED_CONTENT 응답을 반환할 때 사용
class UgcViolationException implements Exception {
  final String errorCode;
  final String errorMessage;
  final String violatingText;
  final String fieldName;

  UgcViolationException({
    required this.errorCode,
    required this.errorMessage,
    required this.violatingText,
    required this.fieldName,
  });

  @override
  String toString() => 'UgcViolationException: errorCode=$errorCode, field=$fieldName, violatingText=$violatingText';
}
