enum ErrorCode {
  duplicateReport(code: 'DUPLICATE_REPORT', koMessage: '이미 신고가 접수된 물품입니다.'),
  nullExtraComment(code: 'NULL_EXTRA_COMMENT', koMessage: '기타 의견을 입력해 주세요.'),
  internalServerError(code: 'INTERNAL_SERVER_ERROR', koMessage: '일시적인 오류가 발생했습니다.'),
  invalidRequest(code: 'INVALID_REQUEST', koMessage: '요청 정보가 올바르지 않습니다.'),
  accessDenied(code: 'ACCESS_DENIED', koMessage: '접근 권한이 없습니다.'),
  unauthorized(code: 'UNAUTHORIZED', koMessage: '로그인이 필요합니다.'),
  missingAuthToken(code: 'MISSING_AUTH_TOKEN', koMessage: '인증 토큰이 누락되었습니다.'),
  invalidAccessToken(code: 'INVALID_ACCESS_TOKEN', koMessage: '로그인 상태가 만료되었습니다.'),
  invalidRefreshToken(code: 'INVALID_REFRESH_TOKEN', koMessage: '재로그인이 필요합니다.'),
  expiredAccessToken(code: 'EXPIRED_ACCESS_TOKEN', koMessage: '세션이 만료되었습니다.'),
  expiredRefreshToken(code: 'EXPIRED_REFRESH_TOKEN', koMessage: '세션이 만료되었습니다.'),
  refreshTokenNotFound(code: 'REFRESH_TOKEN_NOT_FOUND', koMessage: '토큰 정보를 찾을 수 없습니다.'),
  tokenBlacklisted(code: 'TOKEN_BLACKLISTED', koMessage: '만료된 토큰입니다.'),
  emptySocialAuthToken(code: 'EMPTY_SOCIAL_AUTH_TOKEN', koMessage: '소셜 인증 정보가 없습니다.'),
  invalidSocialPlatform(code: 'INVALID_SOCIAL_PLATFORM', koMessage: '지원하지 않는 로그인 플랫폼입니다.'),
  socialApiError(code: 'SOCIAL_API_ERROR', koMessage: '소셜 로그인에 실패했습니다.'),
  invalidSocialMemberInfo(code: 'INVALID_SOCIAL_MEMBER_INFO', koMessage: '소셜 계정 정보를 확인할 수 없습니다.'),
  memberNotFound(code: 'MEMBER_NOT_FOUND', koMessage: '회원 정보를 찾을 수 없습니다.'),
  emailAlreadyExists(code: 'EMAIL_ALREADY_EXISTS', koMessage: '이미 가입된 이메일입니다.'),
  invalidRequiredTermsAgreed(code: 'INVALID_REQUIRED_TERMS_AGREED', koMessage: '필수 약관에 동의해 주세요.'),
  memberLocationNotFound(code: 'MEMBER_LOCATION_NOT_FOUND', koMessage: '회원 위치 정보를 찾을 수 없습니다.'),
  invalidFileRequest(code: 'INVALID_FILE_REQUEST', koMessage: '파일 요청이 올바르지 않습니다.'),
  fileUploadError(code: 'FILE_UPLOAD_ERROR', koMessage: '파일 업로드 중 오류가 발생했습니다.'),
  fileDeleteError(code: 'FILE_DELETE_ERROR', koMessage: '파일 삭제 중 오류가 발생했습니다.'),
  tooLongExtraComment(code: 'TOO_LONG_EXTRA_COMMENT', koMessage: '기타 의견은 300자 이하로 작성해 주세요.'),
  itemNotFound(code: 'ITEM_NOT_FOUND', koMessage: '해당 물품을 찾을 수 없습니다.'),
  invalidItemOwner(code: 'INVALID_ITEM_OWNER', koMessage: '본인만 수정할 수 있습니다.'),
  tooManyCustomTags(code: 'TOO_MANY_CUSTOM_TAGS', koMessage: '커스텀 태그는 최대 개수를 초과했습니다.'),
  tooLongCustomTags(code: 'TOO_LONG_CUSTOM_TAGS', koMessage: '커스텀 태그 길이가 너무 깁니다.'),
  alreadyRequestedItem(code: 'ALREADY_REQUESTED_ITEM', koMessage: '이미 거래 요청한 물품입니다.'),
  tradeRequestNotFound(code: 'TRADE_REQUEST_NOT_FOUND', koMessage: '거래 요청 정보를 찾을 수 없습니다.'),
  selfLikeNotAllowed(code: 'SELF_LIKE_NOT_ALLOWED', koMessage: '내 아이템에는 좋아요를 누를 수 없습니다.'),
  tradeCancelForbidden(code: 'TRADE_CANCEL_FORBIDDEN', koMessage: '거래 요청을 취소할 수 없습니다.'),
  vertexRequestSerializationFailed(code: 'VERTEX_REQUEST_SERIALIZATION_FAILED', koMessage: 'AI 요청 준비 중 오류가 발생했습니다.'),
  vertexApiCallFailed(code: 'VERTEX_API_CALL_FAILED', koMessage: 'AI 서비스 호출에 실패했습니다.'),
  vertexResponseParseFailed(code: 'VERTEX_RESPONSE_PARSE_FAILED', koMessage: 'AI 응답 처리 중 오류가 발생했습니다.'),
  vertexAuthTokenFailed(code: 'VERTEX_AUTH_TOKEN_FAILED', koMessage: 'AI 인증 토큰 발급에 실패했습니다.'),
  vertexPredictionsMalformed(code: 'VERTEX_PREDICTIONS_MALFORMED', koMessage: 'AI 응답 형식이 잘못되었습니다.'),
  vertexPredictionsMissing(code: 'VERTEX_PREDICTIONS_MISSING', koMessage: 'AI 응답이 누락되었습니다.'),
  unknown(code: 'UNKNOWN', koMessage: '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');

  final String code;
  final String koMessage;

  const ErrorCode({required this.code, required this.koMessage});

  static ErrorCode fromCode(String? code) {
    if (code == null) return ErrorCode.unknown;
    return ErrorCode.values.firstWhere((e) => e.code == code, orElse: () => ErrorCode.unknown);
  }
}
