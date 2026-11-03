# #972 계정·로그인·알림·마이페이지·프로필 사용성 개선 설계

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/972
- 기준: main v1.10.129
- 범위 밖: 홈·물품 상세·등록(#969), 요청관리(#970), 채팅·거래완료·후기(#971), 서버 항목(공지 상세 API, 탈퇴 사유 API, 고객센터·FAQ)

## 1. 앱 시작, 링크 진입

| 항목 | 문제 | 변경 | 테스트 |
|---|---|---|---|
| 시작 실패 재시도 | 오프라인·시간 초과·서버 오류 시 로그인 화면으로 이동 | 토큰 재발급 실패 응답 분류(`TokenReissueResult.fromFailedResponse`: 401 만료·그 외 4xx 거절 / 408·429·5xx·연결 실패 재시도) > `TokenRefreshOutcome` 3가지. 거절만 로그인 화면, 재시도 가능 실패·시간 초과는 스플래시 안 다시 시도 화면 (`EmptyStateView.error`). 재발급 후 회원 정보 조회 오류는 연결·5xx·408·429만 다시 시도, 4xx·로컬 오류는 로그인 화면. 실패 화면 '로그인 화면으로 이동'은 로컬 토큰만 삭제. 실행 세대 번호로 늦게 끝난 이전 실행 무시 | `token_reissue_result_test`, `splash_startup_sequence_test` (`describeStartupFailure`, `isRetryableMemberLoadError`) |
| 공유 링크 내 물품 판정 | https 공유 링크는 항상 `isMyItem: false` | 물품 상세를 먼저 조회해 작성자 id <-> 현재 회원 id, 거래 상태로 판정 (`resolveItemAccessFlags`: 내 물품·교환 완료·조회 실패 > 요청 버튼 숨김). 조회 중 루트 오버레이 로딩 표시. 알림 타입으로 판정 못 하는 romrom 링크도 같은 방식. 상세 화면(#969 담당)은 자체 조회라 결과 재사용 불가 > 조회 2회 | `deep_link_router_test` |
| 로그인 전 링크 보관 | 로그인·온보딩으로 가면 링크 폐기 | `DeepLinkGate`: 메인 진입 전 링크 보관, 메인 진입(스플래시·로그인·온보딩 완료) 시 1회 열기. 메인 진입 전 세션 종료(온보딩 이탈·시작 실패 탈출)는 보관 링크 유지 | `deep_link_gate_test`, `deep_link_router_gate_test` |
| 로그인 전 링크 차단 | 앱 실행 중 링크·푸시 탭이 로그인·온보딩·정지 화면 위에 쌓임 | 실행 중 링크·푸시 탭도 게이트 경유. 세션 종료(로그아웃·만료·정지) 시 게이트 닫기 | `deep_link_gate_test`, `user_session_lifecycle_test` |
| 모르는 경로 | romrom 모르는 경로·필수 id 없음 > 무반응 | 알림함으로 이동 (`DeepLinkRoute.notificationFallback`) | `deep_link_router_test` |
| 네트워크 오류 문구 | 네트워크 오류도 "알 수 없는 오류" | `ErrorUtils.isNetworkError` + "인터넷 연결을 확인해 주세요" | `error_utils_test` |

## 2. 알림

| 항목 | 문제 | 변경 | 테스트 |
|---|---|---|---|
| 삭제 알림 값 | 알림함에서 열면 물품명·사유 빈 값 | 알림 payload를 extraData로 전달, 빈 값은 "정보 없음" 문구로 대체 | 위젯 테스트(대체 문구) |
| 전체 삭제 확인 | 확인 없이 실행 | `CommonModal.confirm` 후 실행, 진행 중 중복 탭 차단 | 수동 |
| 본 탭만 읽음 | 나가면 보지 않은 탭까지 전체 읽음 | 방문한 탭 기록. 두 탭 모두 방문 > 전체 읽음, 한 탭만 > 불러온 목록 중 그 탭의 읽지 않은 알림만 개별 읽음 (`markVisitedTabsAsRead`, 동시 4건 제한) | `notification_list_provider_test` |
| 공지 펼치기 | 본문 2줄 이후 볼 방법 없음 | 공통 `ExpandableText`(후기 섹션 펼치기 위젯 공통화)로 공지 본문 펼치기·접기. 공지는 화살표(44px)만 펼치기, 본문 탭은 항목 탭(읽음·딥링크) 유지 | `expandable_text_test` |
| 설정 실패 표시 | 불러오기 실패 시 모두 꺼짐 | 실패 시 `EmptyStateView.error` + 다시 시도 | 수동 |
| 권한 꺼짐 배너 | 시스템 알림 권한 꺼짐 표시 없음 | 설정 화면 상단 배너 + 설정 열기, 앱 복귀 시 재확인 | 수동 |
| 마케팅 처리 일자 | 처리 일자 안내 없음 | `setEnabled`가 성공 여부 반환, 마케팅 변경 성공 시 "yyyy.MM.dd 마케팅 정보 수신 동의/거부 처리되었어요" | `marketing_consent_message_test`, `notification_setting_provider_test` |
| 스위치 접근성 | 화면낭독기 상태 없음, 터치 영역 작음 | `Semantics(toggled, label)`, 선택 터치 여백 파라미터 (설정 화면 44px 이상), 색 리터럴 제거 | `completed_toggle_switch_test` |

## 3. 마이페이지, 계정

| 항목 | 문제 | 변경 | 테스트 |
|---|---|---|---|
| 탈퇴 안내·동의 | 확인 1회, 삭제 데이터 안내 없음 | `MemberWithdrawalScreen`: 사라지는 정보 안내(물품·채팅·후기 등) + 동의 체크 후 버튼 활성, 진행 중 중복 차단·뒤로 가기 차단, 성공 시 화면 해제 여부와 무관하게 세션 종료. 탈퇴 사유 수집은 서버 항목이라 제외 | `member_withdrawal_screen_test` |
| 라이선스·문의 메뉴 | 없음 | 오픈소스 라이선스(`showLicensePage`), 문의하기(메일) 메뉴 추가 | 수동 |
| 프로필 실패·위치 등록 | 실패 시 '닉네임'·'위치정보 없음', 위치 없을 때 등록 버튼 없음 | 실패 시 닉네임 박스에 실패 문구 + 다시 시도, 위치 없음이면 "위치 등록" 버튼 | 수동 |
| 차단 목록 실패 | 실패 시 "차단한 사용자가 없습니다" | `EmptyStateView.error` + 다시 시도 | 수동 |
| 온보딩 이탈 확인 | 첫 단계 뒤로 가기 즉시 로그아웃 | 확인 모달 후 로그아웃, 시스템 뒤로 가기도 같은 경로 | 수동 |
| 문의 주소 | 2곳 하드코딩 | 값은 유지, `AppUrls.supportEmailAddress` 단일 원본 + `launchSupportEmail` 공통 (3곳째 사용처: 마이페이지 문의하기) | 수동 |
| 앱 업데이트 | 권장 업데이트 없음, 스토어 실패 안내 없음, iOS 닫기 시 강제 종료 | 서버 응답의 `latestVersion`으로 권장 판정(`UpdateType.recommend`), 스플래시에서 닫을 수 있는 권장 안내(3일 주기, 실패해도 시작 진행, 스토어 열기 끝난 뒤 닫기), 스토어 실패 스낵바(스토어 검색 안내), iOS 닫기는 안내만 하고 화면 유지 | `app_version_update_type_test`, `recommended_update_prompt_service_test` |

## 4. 프로필

| 항목 | 문제 | 변경 | 테스트 |
|---|---|---|---|
| 다시 시도 | 프로필 실패 시 다시 시도 없음 | `EmptyStateView.error` + 다시 시도 | 수동 |
| 교환 물품 카드 | 타인 카드 탭 무반응 | 타인 카드 탭 > 물품 상세 (`isMyItem: false`) | 수동 |
| 후기 실패 | 실패 시 '후기 0건' | 실패 상태 분리 + 다시 시도 | 수동 |
| 닉네임 안내 | 글자 수·형식 안내 없음 | 서버 관리자 수정 규칙(20자)과 같은 최대 길이 + `n/20` 카운터, 공백만 입력 시 안내 | `nickname_rules_test` |
| 카메라·앨범 | 갤러리만 | 공용 `showImageSourceBottomSheet` 재사용 | 수동 |

## 하지 않는 것
- 서버 API 추가가 필요한 공지 상세, 탈퇴 사유, 고객센터·FAQ·공지 목록
- `main_screen.dart` 수정 (#964와 충돌 방지)
- 문의 메일 주소 값 변경 (운영 주소 미확정)
- 본 탭만 읽음의 한계: 불러오지 않은 페이지의 알림은 읽지 않음으로 남음, 탭별 일괄 읽음 API 필요 > #973 서버 항목
- 물품 상세 화면의 작성자 판정 재사용 (상세 화면은 #969 담당, 라우터 조회 결과 전달 불가)
