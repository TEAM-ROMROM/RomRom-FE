# 키워드 알림 · 관리자 채팅 신고 탭 · 공지 이미지·링크 입력 설계

- 이슈: FE #1020 (키워드 알림 앱), BE #873 (키워드 알림 서버 + 관리자 화면), 상위 #1019
- 사용자 승인: 2026-11-05 (알림 범위 = 내 탐색 범위 안, 관리자 두 가지 모두)

## 1. 왜

- 홈 피드는 추천 점수 순(카테고리·신선도·좋아요 + 시드 섞기)이라 특정 물건을 기다리는 사람은 계속 검색해야 함
- 키워드 알림 = "검색 저장 + 새 물품 알림". 피드 순서는 건드리지 않음
- 채팅 메시지 신고는 쌓이지만 관리자가 볼 화면이 없음, 공지 이미지·링크는 서버만 지원

## 2. 키워드 알림

### 정책
- 회원당 최대 10개, 정규화 후 2~20자
- 정규화: 앞뒤 공백 제거 > 연속 공백 1칸 > 소문자. 같은 정규화 값 중복 등록 불가
- 매칭: 정규화 키워드가 `lower(물품 이름 + " " + 설명)`에 포함
- 대상 제외: 물품 주인, 차단 관계(양방향), 탈퇴·정지 회원, 탐색 범위 밖 물품
  - 거리: 회원 latitude/longitude + searchRadiusInMeters 기준, 물품 location 과의 거리 (위치 없는 회원은 거리 조건 없음, 반경 없으면 서버 기본 탐색 반경)
- 물품 1건당 회원 1명에게 알림 1회 (여러 키워드 매칭 시 첫 키워드로 문구)
- 키워드 등록 자체가 수신 동의 (별도 토글 없음). 방해금지 시간은 적용
- 옛 앱: 알림 목록에서 숨김(LEGACY_CLIENT_HIDDEN_TYPES). 옛 앱은 키워드를 등록할 수 없어 푸시도 안 감

### 서버 (RomRom-BE)
- 테이블 `member_keyword_alert` (Flyway V1_4_75): keyword_alert_id UUID PK, member_id FK, keyword(원문 표시용), normalized_keyword, created_date/updated_date, unique(member_id, normalized_keyword), index(normalized_keyword)
- API (MemberBlock 패턴: multipart @ModelAttribute, Docs 인터페이스 분리 `MemberKeywordAlertControllerDocs`)
  - `POST /api/members/keyword-alert/get` > `{ keywordAlerts: [ { keywordAlertId, keyword, createdDate } ], maximumKeywordAlertCount: 10 }` (최신 등록순)
  - `POST /api/members/keyword-alert/post` (form `keyword`) > 같은 응답 (등록 후 목록)
  - `POST /api/members/keyword-alert/delete` (form `keywordAlertId`) > 같은 응답 (본인 것만 삭제, 없으면 오류)
  - 오류 코드: 길이 위반 / 개수 초과 / 중복 / 없는 키워드. 메시지는 사용자에게 그대로 보여줄 한국어
- 매칭 시점: `ItemService.postItem` 저장 후 `ItemRegisteredEvent` 발행 > `@Async @TransactionalEventListener(AFTER_COMMIT)` 리스너 > 매칭 서비스 > 대상 회원별 `KeywordItemRegisteredEvent` 또는 sendToMember
- 알림 종류 `KEYWORD_ITEM_REGISTERED`: 제목 "키워드 알림", 본문 예 "'{keyword}' 새 물품: {itemName}", payload deepLink `romrom://item/detail?itemId=`, itemId, keyword. 알림 기록 저장(기존 sendToMember 흐름)
- 실패 격리: 매칭·발송 실패가 물품 등록에 영향 없음 (커밋 후 비동기, try/catch 로그)

### 앱 (RomRom-FE)
- 4-레이어: `keyword_alert_repository.dart` > `keyword_alerts_provider.dart` (AsyncNotifier, 등록·삭제 후 서버 응답 목록으로 갱신) + 테스트, 로그아웃 시 초기화(user_scoped_providers)
- 화면 `keyword_alert_settings_screen.dart`: 입력칸 + 추가 버튼, 키워드 목록(삭제), 개수 "n/10", 빈 상태 안내, 로딩·실패 다시 시도
- 진입: 알림 설정 화면에 "키워드 알림" 행 (오른쪽 화살표, 등록 개수 표시)
- 검색 결과 종 버튼: 검색어 입력칸 오른쪽, 검색 후에만 표시. 등록된 키워드면 채운 종, 탭하면 등록/해제 + 스낵바. 2자 미만·10개 초과는 안내
- 권한: 키워드 등록 성공 시 휴대폰 알림 권한이 꺼져 있으면 그때 안내(notification_permission_prompt_service 재사용). 거부해도 등록은 유지, 앱을 막지 않음
- 알림 종류 `keywordItemRegistered`(label "키워드 알림", serverName `KEYWORD_ITEM_REGISTERED`): 아이콘, 끄기 메뉴 숨김(대응 설정 없음), 탭 > 기존 item/detail 딥링크
- 공유 상태: 설정 화면·검색 화면 모두 `keywordAlertsProvider` 구독 (규칙 0)

## 3. 관리자 화면 (RomRom-BE 템플릿)
- 채팅 신고 탭 (`templates/admin/reports.html`): 목록(상태 필터·페이지)·상세(신고자, 대상 회원, 채팅방 ID, 메시지 원문 스냅샷, 사유, 추가 의견)·상태 변경·처리 완료. 대기 건수·통계에 포함
  - reports.html 이 611줄이라 채팅 탭 JS 는 별도 정적 파일 또는 fragment 로 분리
  - AdminResponse(803줄)·AdminRequest(431줄)는 키우지 않고 새 DTO 로
- 공지 작성·수정 (`templates/admin/announcements.html`): 이미지 URL 입력(+ 가능하면 기존 업로드 API 로 파일 업로드) + 미리보기, 링크 입력(https:// 또는 romrom:// 만 허용, 서버에서도 검증), 수정 시 비우면 제거

## 4. 하지 않는 것
- 피드 추천 점수에 키워드 반영
- 키워드 알림 별도 on/off 토글 (키워드 삭제로 대신)
- 이미 올라온 물품 소급 알림
