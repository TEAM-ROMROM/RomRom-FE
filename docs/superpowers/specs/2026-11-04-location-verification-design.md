# 동네 위치 인증: 실제 GPS로만, 필요한 기능에서만 (#986)

## 배경
- 앱 시작·가입 단계에서 권한을 강요해 Apple 심사 거절 이력 있음
- 기존 인증 화면은 지도 중심 핀 위치를 그대로 저장 > 임의 위치·가짜 위치로 인증 가능
- 등록 탭만 로컬 플래그(`isMemberLocationSaved`)로 확인, 교환 요청·채팅·탐색 범위는 확인 없음

## 원칙
- 가입·온보딩·스플래시에서 위치 권한 요청 없음 (위치 없이 가입 완료 가능)
- 권한은 위치가 필요한 기능을 누른 순간에만: 앱 안내(CommonModal) > 시스템 권한 창
- 거부해도 앱 전체 사용 가능, 해당 기능만 "위치 인증이 필요해요" + 다시 시도·설정 열기
- 자동 재요청 반복 없음, 화면·앱 차단·종료 없음
- 인증 위치 = 실제 현재 GPS 위치만 (지도 선택·가상 위치 거부)

## 구조
| 계층 | 파일 | 역할 |
|---|---|---|
| 공통 확인 | `lib/utils/location_verification_gate.dart` | `ensureVerified(context, purpose:)` 인증됨 > 통과, 미인증 > 안내 모달 > 인증 화면 |
| 상태 | `lib/providers/location_verification_provider.dart` | 회원별 인증 여부, GPS 위치로 인증(서버 위치 저장 + 로컬 기록) |
| 저장소 | `lib/repositories/location_verification_repository.dart` | SharedPreferences 기록 1건 `{memberId, verifiedAt, latitude, longitude}` |
| GPS 확인 | `lib/services/gps_location_verifier.dart` | 위치 서비스 > 권한 > 정확한 위치 > 현재 좌표 > 가상 위치 > 정확도 > 역지오코딩 |
| 화면 | `lib/screens/my_page/my_location_verification_screen.dart` | 확인 중 / 실패 사유 / 확인된 동네(고정 지도) > 이 동네로 인증 |

- 공통 확인은 화면 이동을 포함 > `utils` 배치 (services·providers는 screens import 금지 규칙)
- 기록에 회원 ID 포함 > 다른 계정 로그인 시 미인증, 로그아웃·탈퇴 시 `UserInfo` 정리에서 삭제 + `userScopedProviders` 초기화
- 기존 핀 방식으로 위치를 저장한 회원은 기록이 없으므로 다음 기능 사용 시 GPS로 1회 인증

## GPS 판정
- 조회: `LocationAccuracy.high`, 시간 제한 15초 (초과 > 현재 위치 없음)
- 가상 위치: `Position.isMocked` (Android 모의 위치, iOS 15+ `isSimulatedBySoftware`) > 거부
- 오차: 100m 초과 또는 0 이하 > "실내라면 창가나 바깥에서 다시 시도"
- 대략적 위치만 허용(iOS 정확한 위치 끔·Android 대략 위치) > 설정 안내
- 영구 거부·위치 서비스 꺼짐 > 시스템 창 없이 설정 열기 안내, 설정 복귀 시 권한 요청 없이 1회 재확인
- 서비스 지역 밖(위도 33.0~38.7, 경도 124.5~131.9 밖) 실제 GPS > 지도에서 동네 직접 선택 (해외 심사 대응, 2.1)
  - 가상 위치·낮은 정확도 판정 뒤에만 > 가상 위치는 어디서든 거부, 국내는 GPS만
  - 기록 방식 `method`: `gps` | `manualOutsideServiceArea` (같은 회원 위치 API로 저장)

## 인증 필요 기능 (purpose)
| 기능 | 진입점 |
|---|---|
| 물품 등록 | 등록 탭 등록 버튼, 홈 블러 등록 버튼 |
| 교환 요청 | 물품 상세 요청하기, 홈 카드 드롭 |
| 채팅 시작 | 물품 상세 채팅하기 (받은 요청 수락 = 채팅방 생성 = 거래 시작) |
| 탐색 범위 변경 | 탐색 범위 화면 (미인증 > 범위 대신 인증 안내) |

- 받은 요청 "수락" 별도 API 사용처 없음 (`/api/trade/accept` 미사용) > 채팅하기가 실질 수락이라 같은 확인 적용
- 기존 채팅방 열기·거래 완료·채팅 위치 보내기는 범위 밖 (이미 시작된 거래)
- 거래 장소 선택(물품 등록 위치·채팅 위치)은 지도 직접 선택 유지 (범위 밖)

## iOS 설정
- `NSLocationWhenInUseUsageDescription`: 동네 인증 목적 명시
- Always 키 2개 삭제: geolocator는 WhenInUse 키가 있으면 WhenInUse만 요청, 네이버 지도도 WhenInUse, permission_handler 위치 미사용
- Podfile `PERMISSION_LOCATION_ALWAYS=1` 삭제

## 함께 고친 것
- 교환 희망 장소 지도: 진입 시 지도 SDK가 안내 없이 권한 창을 띄움 > 이미 허용된 경우만 현재 위치 점 표시

## 알림 권한 (같은 원칙)
- 앱 시작 요청 제거 (`main.dart`), 로컬 알림 초기화 iOS 권한 창 끔, FCM 토큰 등록은 권한 요청 없이 (iOS APNs 토큰 대기)
- 교환 요청 성공·물품 등록 성공 직후 1회 안내(CommonModal) > 알림 켜기 > 시스템 창, 설치당 1회 (나중에·거부 후 재안내 없음)
- 허용 직후 FCM 토큰 재등록 + 안내한 교환·채팅 알림 설정 켜기 (미결정 중 서버 설정 꺼짐 보정)
- 홈 진입 자동 알림 바텀시트(가입 후 1회·7일 주기) 제거, 채팅방 안내 시트·알림 설정 화면 유지
- 알림 설정 화면 "알림 켜기": 권한 미결정 > 시스템 요청 (iOS 미요청 앱은 설정에 알림 항목 없음)
- 시스템 권한 거부 > 서버 알림 설정 전체 끔 동기화는 "거부"일 때만 (미결정 제외)

## 테스트
- `test/services/gps_location_verifier_test.dart`: 거부·영구 거부·가상 위치·낮은 정확도·대략 위치·시간 초과·주소 실패
- `test/providers/location_verification_provider_test.dart`: 회원별 기록, 다른 회원, 서버 저장 실패, 로그아웃 삭제
- `test/utils/location_verification_gate_test.dart`: 인증됨 통과, 안내 모달, 취소, 중복 호출
- `test/screens/my_location_verification_screen_test.dart`: 안내 모달 순서, 실패 안내, 설정 복귀 재확인
- `test/architecture/location_verification_gate_rule_test.dart`: 진입점 인증 확인 순서, 새 우회 진입점 차단

## 후속
- 서버 인증 플래그·검증 (#973) 도입 시 로컬 기록을 서버 값으로 교체
