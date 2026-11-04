# 검색·필터·계정 묶음 설계 (FE #1008 / BE #862)

## 1. 물품 검색
- API: `POST /api/item/search` (multipart, 인증 필요) > `ItemResponse.itemPage`
  - `searchKeyword`(필수, trim 후 1자 이상, 50자 초과분 자름) / `searchItemCategories`(쉼표, 미전송=전체) / `searchSortField`(`LATEST`·`DISTANCE`·`PRICE_ASC`·`PRICE_DESC`, 기본 LATEST) / `pageNumber`·`pageSize`(1~50 보정)
  - 빈 검색어 > 400 `INVALID_SEARCH_KEYWORD`
- 노출 조건: 홈 피드 조건식을 `ItemFeedQueryExpressions`로 옮겨 피드·롬업 후보·검색이 같은 식 사용 (본인·삭제·관리자 차단·교환 완료·정지 회원·상호 차단·다시 보지 않기 제외) + 내가 신고한 물품 제외(쿼리 단계, 페이지 크기 유지)
- 결정: 검색은 반경 제한 없음(전체 지역). 거리순은 회원 위치 기준, 위치 미등록이면 최신순
- 결정: 정렬은 피드 `ItemSortField`에 값을 추가하지 않고 별도 `ItemSearchSortField` (피드·구버전 앱 영향 없음)
- 인덱스: `lower(item_name|item_description) LIKE '%검색어%'`. V1_4_73이 pg_trgm 설치 가능하면 설치 후 `lower(...) gin_trgm_ops` GIN 인덱스 생성, 불가하면 인덱스 없이 일반 LIKE (3자 미만 검색어는 인덱스 미사용)
- 앱: 홈 상단 검색 아이콘 > `ItemSearchScreen`
  - 결정: 키보드 검색(제출) 시에만 조회 (입력마다 조회 안 함)
  - 최근 검색어: 기기 저장, 회원별 키, 최신 순 최대 10개, 개별·전체 삭제
  - 카테고리: 복수 선택 바텀시트(`ItemCategoryMultiSelectBottomSheet`, 등록 화면과 공용), 정렬: 칩 4개. 필터 바꾸면 같은 검색어로 재검색
  - 상태: `itemSearchProvider`(autoDispose, 화면 전용), 빈 결과·실패는 `EmptyStateView`
  - 결과 행: 기존 독립 카드 위젯이 없어 공통 부품(CachedImage·ErrorImagePlaceholder·AppPressable)으로 `ItemSearchResultTile` 신설

## 2. 희망 교환 카테고리
- Item 필드 `wantedItemCategories` (컬렉션 테이블 `item_wanted_item_category`, 문자열 저장), 응답 item에 항상 포함(없으면 `[]`)
- 결정: 0~3개, 중복·null 제거, 3개 초과 400 `TOO_MANY_WANTED_ITEM_CATEGORIES`
- 등록: 미전송 > 없음. 수정: 미전송(구버전 앱) > 기존 값 유지, 빈 값 전송 > 전부 해제 (바인딩 테스트로 고정)
- 앱: 등록·수정 폼 "이런 물건과 바꾸고 싶어요 (선택)" 칸 > 바텀시트(최대 3개), 항상 전송. 상세 화면 설명 아래 태그 표시
- `register_input_form.dart` 524줄 > 필드 입력 처리 mixin 분리(`register_input_form_field_handlers.dart`)로 446줄

## 3. 탈퇴 사유·진행 중 거래
- `POST /api/members/delete`에 선택 필드 `withdrawalReason`(6종)·`withdrawalReasonDetail`(최대 500자, 초과 400 `TOO_LONG_WITHDRAWAL_REASON_DETAIL`)
- `POST /api/members/withdrawal/ongoing-trades` > `TradeResponse.ongoingTradeRequestHistories` (보낸·받은 PENDING·CHATTING·TRADE_COMPLETE_REQUESTED)
- 결정: 탈퇴 시 서버가 진행 중 거래를 전부 CANCELED (구버전 앱 탈퇴 포함, 기존 강제탈퇴 쿼리 재사용) + `member_withdrawal_history` 기록(사유 null 허용, 취소 건수)
- 결정: 새 앱은 사유 선택 필수·상세 선택. 탈퇴 버튼 > 진행 중 거래 조회 > 있으면 목록(최대 3줄 + 외 N건) 확인 모달 > 확인 시 탈퇴. 조회 실패·구버전 서버면 안내 없이 진행(서버가 어차피 취소)

## 4. 닉네임 규칙
- 서버 `NicknameRule`(단일 원본) <-> 앱 `lib/utils/nickname_rules.dart`(같은 규칙·문구)
  - 2~20자(UTF-16), `^[가-힣a-zA-Z0-9_]+$`, 앞뒤 공백 제거 후 검사
  - 결정: 예약어 `운영자·관리자·admin·romrom` 부분 포함 금지(대소문자 무시)
  - 에러 코드 3개: `INVALID_NICKNAME_LENGTH`, `INVALID_NICKNAME_CHARACTER`, `RESERVED_NICKNAME` (앱 ErrorCode 문구 = 서버 문구)
- 결정: 현재 닉네임과 같으면 검사 생략(서버 기존 동작, 앱도 `savedNickname` 비교) > 규칙 이전 닉네임으로 사진만 바꾸기 허용

## 스위치 (system_config, V1_4_73 시드)
| 키 | 기본 | 효과 |
|---|---|---|
| `member.nickname.rule-enforced` | `false` | true면 프로필 수정 시 서버 닉네임 규칙 검사. 구버전 앱(최대 길이만 검사)이 규칙 밖 닉네임으로 저장 실패하지 않도록 OFF, 새 앱 보급 후 ON + 캐시 재로딩 |

## 구버전 앱(v1.10.142) 호환
- 추가만: 새 엔드포인트 2개, 응답 필드 `wantedItemCategories`·`ongoingTradeRequestHistories`(json_serializable은 모르는 키 무시), 새 에러 코드는 새 요청·스위치 ON에서만 발생
- 수정 API에서 `wantedItemCategories` 미전송 > 기존 값 유지 (구버전 앱 수정이 희망 카테고리를 지우지 않음)
- 탈퇴 시 거래 취소는 기존 상태값 `CANCELED` 사용 (구버전 앱이 아는 값)
