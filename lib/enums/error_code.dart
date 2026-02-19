enum ErrorCode {
  internalServerError(code: 'INTERNAL_SERVER_ERROR', koMessage: '서버에 문제가 발생했습니다.'),
  invalidRequest(code: 'INVALID_REQUEST', koMessage: '잘못된 요청입니다.'),
  accessDenied(code: 'ACCESS_DENIED', koMessage: '접근이 거부되었습니다.'),

  // AUTH
  unauthorized(code: 'UNAUTHORIZED', koMessage: '인증에 실패했습니다.'),
  invalidCredentials(code: 'INVALID_CREDENTIALS', koMessage: '아이디 또는 비밀번호가 올바르지 않습니다.'),
  missingAuthToken(code: 'MISSING_AUTH_TOKEN', koMessage: '인증 토큰이 필요합니다.'),
  invalidAccessToken(code: 'INVALID_ACCESS_TOKEN', koMessage: '유효하지 않은 엑세스 토큰입니다.'),
  invalidRefreshToken(code: 'INVALID_REFRESH_TOKEN', koMessage: '유효하지 않은 리프레시 토큰입니다.'),
  expiredAccessToken(code: 'EXPIRED_ACCESS_TOKEN', koMessage: '엑세스 토큰이 만료되었습니다.'),
  expiredRefreshToken(code: 'EXPIRED_REFRESH_TOKEN', koMessage: '리프레시 토큰이 만료되었습니다.'),
  refreshTokenNotFound(code: 'REFRESH_TOKEN_NOT_FOUND', koMessage: '리프레시 토큰을 찾을 수 없습니다.'),
  tokenBlacklisted(code: 'TOKEN_BLACKLISTED', koMessage: '블랙리스트처리된 토큰이 요청되었습니다.'),

  // OAUTH
  emptySocialAuthToken(code: 'EMPTY_SOCIAL_AUTH_TOKEN', koMessage: '소셜 로그인 인증 토큰이 제공되지 않았습니다.'),
  invalidSocialPlatform(code: 'INVALID_SOCIAL_PLATFORM', koMessage: '유효하지 않은 소셜 플랫폼입니다.'),
  socialApiError(code: 'SOCIAL_API_ERROR', koMessage: '소셜 로그인 API 호출에 실패하였습니다.'),
  invalidSocialMemberInfo(code: 'INVALID_SOCIAL_MEMBER_INFO', koMessage: '소셜 로그인 회원 정보가 올바르지 않습니다.'),

  // MEMBER
  memberNotFound(code: 'MEMBER_NOT_FOUND', koMessage: '회원을 찾을 수 없습니다.'),
  emailAlreadyExists(code: 'EMAIL_ALREADY_EXISTS', koMessage: '이미 가입된 이메일입니다.'),
  duplicateNickname(code: 'DUPLICATE_NICKNAME', koMessage: '이미 사용 중인 닉네임입니다.'),
  invalidRequiredTermsAgreed(code: 'INVALID_REQUIRED_TERMS_AGREED', koMessage: '필수 이용약관에 동의하지 않았습니다.'),
  deletedMember(code: 'DELETED_MEMBER', koMessage: '탈퇴한 회원입니다.'),

  // MEMBER BLOCK
  alreadyBlocked(code: 'ALREADY_BLOCKED', koMessage: '이미 차단한 회원입니다.'),
  cannotBlockSelf(code: 'CANNOT_BLOCK_SELF', koMessage: '자기 자신을 차단할 수 없습니다.'),
  blockedMemberInteraction(code: 'BLOCKED_MEMBER_INTERACTION', koMessage: '차단된 회원입니다.'),

  // MEMBER LOCATION
  memberLocationNotFound(code: 'MEMBER_LOCATION_NOT_FOUND', koMessage: '회원 위치 정보가 등록되지 않았습니다.'),

  // FILE
  invalidFileRequest(code: 'INVALID_FILE_REQUEST', koMessage: '잘못된 파일이 요청되었습니다.'),
  fileUploadError(code: 'FILE_UPLOAD_ERROR', koMessage: '파일 업로드 중 오류가 발생했습니다.'),
  fileDeleteError(code: 'FILE_DELETE_ERROR', koMessage: '파일 삭제 중 오류가 발생했습니다.'),

  // REPORT
  duplicateReport(code: 'DUPLICATE_REPORT', koMessage: '같은 물품을 여러 번 신고할 수 없습니다.'),
  tooLongExtraComment(code: 'TOO_LONG_EXTRA_COMMENT', koMessage: '기타 의견을 글자 수 제한을 넘겨서 작성할 수 없습니다.'),
  nullExtraComment(code: 'NULL_EXTRA_COMMENT', koMessage: '기타 의견을 빈 값으로 요청할 수 없습니다.'),
  duplicateMemberReport(code: 'DUPLICATE_MEMBER_REPORT', koMessage: '같은 회원을 여러 번 신고할 수 없습니다.'),
  selfReport(code: 'SELF_REPORT', koMessage: '자기 자신을 신고할 수 없습니다.'),

  // ITEM
  itemNotFound(code: 'ITEM_NOT_FOUND', koMessage: '해당 물품을 찾을 수 없습니다.'),
  invalidItemOwner(code: 'INVALID_ITEM_OWNER', koMessage: '해당 물품의 소유자가 아닙니다.'),
  itemValuePredictionFailed(code: 'ITEM_VALUE_PREDICTION_FAILED', koMessage: '아이템 가격 예측에 실패하였습니다.'),
  deletedItem(code: 'DELETED_ITEM', koMessage: '삭제된 물품입니다.'),

  // ITEM CUSTOM TAG
  tooManyCustomTags(code: 'TOO_MANY_CUSTOM_TAGS', koMessage: '커스텀 태그의 최대 개수를 초과하였습니다.'),
  tooLongCustomTags(code: 'TOO_LONG_CUSTOM_TAGS', koMessage: '커스텀 태그의 최대 길이를 초과하였습니다.'),

  // TRADE
  alreadyRequestedItem(code: 'ALREADY_REQUESTED_ITEM', koMessage: '이미 요청을 보낸 물품입니다.'),
  tradeRequestNotFound(code: 'TRADE_REQUEST_NOT_FOUND', koMessage: '거래 요청이 존재하지 않습니다.'),
  tradeAlreadyProcessed(code: 'TRADE_ALREADY_PROCESSED', koMessage: '거래 요청이 처리된 물품입니다.'),
  tradeToSelfForbidden(code: 'TRADE_TO_SELF_FORBIDDEN', koMessage: '자신의 물품에 거래 요청을 보낼 수 없습니다.'),
  tradeAccessForbidden(code: 'TRADE_ACCESS_FORBIDDEN', koMessage: '거래 요청 권한이 없습니다.'),
  cannotUpdateTradeRequest(code: 'CANNOT_UPDATE_TRADE_REQUEST', koMessage: '거래 요청을 수정할 수 없습니다.'),

  // CHAT
  cannotSendMessageToDeletedChatroom(
    code: 'CANNOT_SEND_MESSAGE_TO_DELETED_CHATROOM',
    koMessage: '거래요청이 취소되었거나 거래완료된 상태이므로, 메시지를 보낼 수 없습니다.',
  ),
  chatUserStateNotFound(code: 'CHAT_USER_STATE_NOT_FOUND', koMessage: '채팅방 상태를 찾을 수 없습니다.'),
  chatroomNotFound(code: 'CHATROOM_NOT_FOUND', koMessage: '채팅방을 찾을 수 없습니다.'),
  notChatroomMember(code: 'NOT_CHATROOM_MEMBER', koMessage: '채팅방의 멤버만 접근할 수 있는 권한입니다.'),
  cannotCreateSelfChatroom(code: 'CANNOT_CREATE_SELF_CHATROOM', koMessage: '자기 자신과는 채팅방을 생성할 수 없습니다.'),
  invalidSender(code: 'INVALID_SENDER', koMessage: '보낸이 정보가 올바르지 않습니다.'),
  tradeRequestNotPending(code: 'TRADE_REQUEST_NOT_PENDING', koMessage: '거래 요청이 대기 상태가 아닙니다.'),
  notTradeRequestReceiver(code: 'NOT_TRADE_REQUEST_RECEIVER', koMessage: '거래 요청을 받은 사람만이 채팅방을 생성할 수 있습니다.'),
  notTradeRequestSender(code: 'NOT_TRADE_REQUEST_SENDER', koMessage: '상대방 회원이 거래 요청의 당사자가 아닙니다.'),

  // ITEM LIKES
  selfLikeNotAllowed(code: 'SELF_LIKE_NOT_ALLOWED', koMessage: '내 아이템에는 좋아요를 누를 수 없습니다.'),

  // Vertex AI Client
  aiPredictedPricePromptLoadError(code: 'AI_PREDICTED_PRICE_PROMPT_LOAD_ERROR', koMessage: 'AI 가격측정 프롬프트 로딩에 실패했습니다.'),
  vertexRequestSerializationFailed(
    code: 'VERTEX_REQUEST_SERIALIZATION_FAILED',
    koMessage: 'Vertex AI 요청 JSON 직렬화에 실패했습니다.',
  ),
  vertexApiCallFailed(code: 'VERTEX_API_CALL_FAILED', koMessage: 'Vertex AI HTTP 응답에 실패했습니다.'),
  vertexResponseParseFailed(code: 'VERTEX_RESPONSE_PARSE_FAILED', koMessage: 'Vertex AI 응답 파싱을 실패하였습니다.'),
  vertexAuthTokenFailed(code: 'VERTEX_AUTH_TOKEN_FAILED', koMessage: 'Vertex AI Token을 받아오지 못했습니다.'),
  vertexPredictionsMalformed(code: 'VERTEX_PREDICTIONS_MALFORMED', koMessage: 'Vertex AI 응답의 predictions 형식이 잘못되었습니다.'),
  vertexPredictionsMissing(
    code: 'VERTEX_PREDICTIONS_MISSING',
    koMessage: 'Vertex AI 응답에서 predictions 누락 또는 잘못된 형식입니다.',
  ),

  // EMBEDDING
  embeddingNotFound(code: 'EMBEDDING_NOT_FOUND', koMessage: '임베딩을 찾을 수 없습니다.'),

  // ADMIN
  unsupportedAdminAction(code: 'UNSUPPORTED_ADMIN_ACTION', koMessage: '지원하지 않는 관리자 액션입니다.'),
  adminItemDeleteFailed(code: 'ADMIN_ITEM_DELETE_FAILED', koMessage: '관리자 물품 삭제에 실패했습니다.'),
  adminDataFetchFailed(code: 'ADMIN_DATA_FETCH_FAILED', koMessage: '관리자 데이터 조회에 실패했습니다.'),

  // NOTIFICATION
  notificationHistoryNotFound(code: 'NOTIFICATION_HISTORY_NOT_FOUND', koMessage: '알림 히스토리를 찾을 수 없습니다.'),
  invalidNotificationHistoryOwner(code: 'INVALID_NOTIFICATION_HISTORY_OWNER', koMessage: '해당 알림의 수신자가 아닙니다.'),

  // JSON
  unknown(code: 'UNKNOWN', koMessage: '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');

  final String code;
  final String koMessage;

  const ErrorCode({required this.code, required this.koMessage});

  static ErrorCode fromCode(String? code) {
    if (code == null) return ErrorCode.unknown;
    return ErrorCode.values.firstWhere((e) => e.code == code, orElse: () => ErrorCode.unknown);
  }
}
