# 서버 계약 정리 설계 (FE #1004 / BE #858)

스토어 v1.10.142 앱이 새 서버에서 그대로 동작해야 하므로 서버는 필드·API 추가만 하고, 옛 앱을 막는 동작은 스위치(기본 꺼짐)로 둔다.

## API 계약
| 항목 | 서버 | 앱 |
|---|---|---|
| 동네 인증 | `POST /api/members/post/location` + `locationVerificationMethod`(GPS / MANUAL_OUTSIDE_SERVICE_AREA), `gpsLatitude`·`gpsLongitude`(지도 선택 시 실제 GPS). `memberLocation.isLocationVerified`·`locationVerifiedAt`·`locationVerificationMethod` 응답 | 인증 저장 시 방식 전송, 인증 여부는 서버 값 우선(없으면 기기 기록) |
| 인증 거부 | 물품 등록·교환 요청·새 채팅방 생성 403 `LOCATION_NOT_VERIFIED` | 거부 시 서버 상태 재조회 > 기기 기록 삭제 > 기존 안내 모달·인증 화면 |
| 피드 좋아요 | `/api/item/list/get` 각 Item `isLiked` | 값 있으면 카드별 상세 조회 생략 (추천 VIEW 점수 부풀림 제거) |
| 물품 주소 | 등록·수정 `siDo`·`siGunGu`·`eupMyoenDong`·`ri` 저장 > Item `address` ("시도 시군구 읍면동") | 등록·수정 시 전송, 표시 주소는 서버 값 우선 > 없으면 좌표 변환 |
| 보낸 요청 전체 | `POST /api/trade/get/sent/all` (페이지, 물품별 조회와 같은 조건·정렬) | 1회 조회 후 카드 순서로 묶음, 404·실패 > 카드별 조회 |
| 요청 채팅방 | 거래 요청 응답 `tradeRequestHistory.chatRoomId` (received·sent·sent/all·상세) | 값 있으면 이미지 비교 추정 생략 |
| 후기 작성 여부 | `messages/get` `isReviewWrittenByMe`, `/api/trade/get` `isReviewWrittenByMe` | 채팅방 완료 카드 '후기 쓰기' 숨김 판단 (방문 가드 대체) |
| 후기 통계 | `POST /api/trade/review/stats` `tradeReviewStats{totalReviewCount, averageRatingScore, ratingCounts, tagCounts}` | 프로필 후기 요약 = 서버 통계 (구버전 서버 > 최근 10건 계산) |
| 신고 물품 | 신고 시 신고자 숨김 물품 저장 > 피드에서 영구 제외 | 현재 화면 즉시 제거용 메모리 필터는 유지 |
| 롬업 자격 | `POST /api/item/promote/eligibility` `promotionEligibility{isEligible, ineligibleReason, remainingDailyPromotionCount, itemCooldownEndsAt, dailyLimitResetsAt, nextAvailableAt}` | 광고 전 확인, 불가 > 광고 없이 사유 안내, 조회 실패 > 기존처럼 진행 |
| 삭제 물품 | 상세·공개 상세 `ITEM_NOT_FOUND`(404)로 정리 (도달 불가 DELETED_ITEM 분기 제거, 코드 자체는 유지) | 탈퇴 작성자 판정을 문구가 아닌 errorCode `DELETED_MEMBER` 로 |
| 최신 버전 | `/api/app/version/check` `latestVersionIos`·`latestVersionAndroid` (미설정 > latestVersion), `/version/update` + `platform` | 실행 플랫폼 값으로 권장 업데이트 판정 |

## 스위치
- `system_config` `location.verification.enforced` (Flyway V1_4_69 에서 'false' 등록). `"true"` 일 때만 미인증 403.
  - 켜는 순서: 새 앱 배포·보급 확인 > `UPDATE system_config SET config_value='true' WHERE config_key='location.verification.enforced'` > 관리자 캐시 새로고침(`/api/admin/config/cache/reload`).

## 결정
- 결정: 동네 인증 만료 없음, 기존 회원(#858 이전 저장) = 미인증 > 앱이 다음 기능 사용 때 재인증.
- 결정: 인증 방식 없이 위치 저장(구버전 앱) > 위치는 저장, 인증 기록은 지움(미인증). 인증 상태를 잘못 "인증됨"으로 남기지 않음.
- 결정: 지도 직접 선택은 실제 GPS 좌표가 서비스 지역 밖 + 고른 좌표가 서비스 지역 안일 때만, GPS 방식은 좌표가 서비스 지역 안일 때만 (위반 400 `INVALID_LOCATION_VERIFICATION`). 범위는 앱 `koreaServiceAreaBounds` = 서버 `KoreaServiceArea`.
- 결정: 앱 인증 여부 = 서버 `isLocationVerified` (null = 구버전 서버·위치 없음·조회 실패 > 기기 기록). 기기 기록은 빠른 폴백으로만 유지.
- 결정: 서버에 역지오코딩이 없어 기존 물품 주소는 마이그레이션으로 채우지 않음(null) > 앱이 좌표로 변환. 행정구역 없이 수정(구버전 앱)하면 주소를 비워 옛 주소가 남지 않게 함.
- 결정: 후기 통계는 블라인드 후기 제외, 평균 평점 BAD 1·GOOD 2·GREAT 3 (소수 둘째 자리).
- 결정: 알림 탭별 읽음은 서버 전체 읽음 API가 탭 구분이 없어 그대로 건별 처리. 단, 서버 미확인 수 = 본 탭 미확인 수(다른 탭 미확인 없음)면 전체 읽음 1회로 대체. 두 탭 모두 봤으면 기존처럼 전체 읽음.
- 결정: 최신 버전 갱신 시점 — Android = Play 프로덕션 심사 등록(store_submit) 성공 후(Play API로 심사 통과를 알 수 없음, 심사 중 몇 시간 안내가 먼저 나갈 수 있음), iOS = 6시간마다 App Store 공개 조회(iTunes Lookup)로 실제 출시 버전 확인. TestFlight·내부 테스트 업로드 시점 갱신 제거. 구버전 앱용 공통 `latestVersion` = 두 플랫폼 중 낮은 버전.
- 결정: 롬업 자격 불가 사유 우선순위 = 교환 불가 > 물품 24시간 제한 > 하루 횟수 (활성화 API 판정 순서).
- 결정: 신고 물품 메모리 필터(`_reportedItemIds`)는 이미 불러온 목록 즉시 제거용으로 유지 (서버는 다음 조회부터 제외).

## 구버전 앱(v1.10.142) 영향
- 새 필드(`isLiked`·`address`·`chatRoomId`·`isLocationVerified` 등)는 json_serializable 이 무시하거나 이미 있는 `address` 로 읽음(형식 같음, 기존 변환이 덮어씀).
- 새 enum 값 없음(인증 방식은 새 필드), 거부는 스위치 꺼짐 기본, 기존 API 응답 의미 유지(`latestVersion` 은 두 스토어 출시 버전 기준으로 더 보수적).
- 신고 즉시 숨김 저장은 옛 앱에서도 피드 제외로 동작(신고한 물품을 다시 보지 않게 됨).
