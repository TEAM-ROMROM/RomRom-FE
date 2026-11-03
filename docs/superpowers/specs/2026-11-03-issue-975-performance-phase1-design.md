# #975 성능 개선 1단계 설계 (이미지 디코딩·캐싱·상태관리)

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/975
- 범위: #969·#970·#971·#972 브랜치가 동시에 고치는 파일은 건드리지 않고, 공통 지점(위젯·서비스·유틸) 안에서만 고친다
- 원칙: 화면 동작은 그대로, 성능만 바꾼다. 호출부 수정 없이 공통 지점에서 한 번에 적용한다

## 1. 이미지 디코딩

| 대상 | 문제 | 설계 |
|---|---|---|
| `CachedImage` | 크기를 안 넘기는 호출부 10여 곳이 원본 해상도로 디코딩 | 크기가 없거나 무한대면 `LayoutBuilder` 제약으로 디코딩 크기 계산 (100px 단위 올림). 첫 유효 크기를 위젯 생명주기 동안 고정, URL·fit·배율 바뀔 때만 재계산 (Hero 복귀 비행 중 매 프레임 재디코딩·깜빡임 방지). 확대 보기용 `shouldDecodeAtFullResolution` 추가 |
| 디코딩 크기 계산 | `CachedImage` 안 private 로직 | `ImageDecodeSize` 유틸로 분리 (CachedImage·채팅 셀·등록 썸네일 3곳 공통) |
| `chat_image_bubble` 셀 | 셀이 원본 디코딩 | `photoGridCellSize`(그리드 배치와 같은 줄 배치 표 단일 원본)로 셀 크기를 직접 계산해 디코딩 (레이아웃 측정 없음), 전체 보기는 원본 유지. 전체 보기 로딩 중에는 셀 이미지(메모리 캐시)를 미리보기로 사용 |
| 등록 탭 목록 썸네일 | 크기 없이 호출 | 박스 크기(90.w) 직접 전달 |
| `UserProfileCircularAvatar` | 아바타가 원본 디코딩 | 아바타 크기를 `CachedImage`에 전달 |
| 등록 썸네일 (`Image.file`) | 원본 디코딩 | `cacheWidth` 지정 |
| 프로필 자르기 | 원본 디코딩 | max(화면 물리 폭, 결과 500px × 최대 확대 5배 = 2500px)까지만 디코딩 (최대 확대 후 잘라도 결과 화질 유지, 작은 사진은 확대 안 함) |

**의도한 손실 (cover 1.8배 규칙)**: cover + 가로·세로 지정 시 긴 변 × 1.8로 가로만 지정한다. 박스 비율과 사진 비율 차이가 1.8배를 넘는 극단 비율(예: 정사각 박스에 1:2 이상 세로 파노라마, 3.2:1 이상 가로 파노라마 등)은 박스를 채우려고 약간 확대되어 흐려질 수 있다. 일반 사진(4:3·16:9·3:4)은 손실 없음. 메모리 절감을 위해 받아들인 손실이며 코드로 막지 않는다.

## 2. 이미지 디스크 캐시

- `AppImageCacheManager`: 키 `romromImageCache`, 최대 1000개, 14일. `CachedImage`·채팅 이미지·물품 상세 헤더가 공통 사용
- 물품 상세 헤더: `photo_viewer` 패키지 위젯(`PhotoViewerMultipleImage`)은 캐시 주입을 지원하지 않음 > 헤더 이미지는 `CachedImage`(원본 해상도)로 직접 그리고 전체 보기만 `showPhotoViewer` 사용, 전체 보기 이미지도 같은 캐시. Hero 태그 형식은 패키지와 동일하게 유지
- 기존 기본 캐시(200개)는 키가 달라 재사용하지 않음 (첫 실행 1회 재다운로드)

## 3. 이미지 압축 동시 실행

- `ConcurrencyLimiter` 유틸 (FIFO 대기열, 성공·실패 공통 슬롯 반환)
- `ImageCompressor.toWebp` 내부에서 동시 2개로 제한 > 호출부(`Future.wait`) 그대로, 결과 순서 유지
- 1건 20초 제한: 초과 시 원본 반환, 슬롯 반환 (멈춘 압축의 슬롯 영구 점유 방지)

## 4. 주소 변환

- 동시 실행 제한은 실제 네트워크 조회 지점(`AddressLookupCache` fetch)에 둔다: 캐시 적중은 대기 없이 즉시 반환, `LocationService` 경유 모든 조회에 적용 (동시 4개)
- 디스크 캐시: `AddressLookupPersistentStore` (SharedPreferences JSON, 키 = 소수 4자리 반올림 좌표, 최대 500개). 첫 조회 때 1회 로드, 저장은 2초 묶음 저장
- 조회 1건 10초 제한 (슬롯 대기 포함): 초과 시 null(미지정), 진행 중 표시 제거로 다음 조회에서 재시도. 대기 중 초과된 조회는 슬롯 차례가 와도 네트워크 호출 안 함

## 5. 토큰 메모리 캐시

- `TokenManager`: 첫 읽기에 보안저장소 1회 로드 (동시 읽기 1회로 합침) > 이후 메모리. 저장·삭제 시 메모리 먼저 갱신
- 로드 중 저장·삭제가 끼면 로드 결과 버림 (세대 번호 비교)

## 6. 회원 캐시 중복

- `MemberManagerService`의 `Member` 객체 메모리 캐시·미사용 리스너·로딩 플래그 제거, `UserInfo`(SharedPreferences)를 단일 원본으로
- 서버 조회는 `SingleFlight`로 동시 1회. 호출부(제외 파일) API는 유지

## 7. 기타

- 미사용 `itemCardProvider`·`ItemCardNotifier`·`ItemCardState` 삭제 (규칙 테스트 예외 항목도 삭제)
- `AppFadeSlideIn`: 등장 지연 최대 240ms (`AppMotion.maximumStaggerDelay`)
- 채팅 웹소켓: `connect()` 때 이전 회원 ID가 있고 현재 회원 ID와 다르면 (연결 여부 무관, 토큰 재발급 실패로 클라이언트만 비워진 경우 포함) 이전 연결·구독 전부 정리 후 새로 연결. `disconnect()`는 첫 await 전에 상태·목록을 비워 정리 도중 새 구독을 보존하고, 참조 카운트·재연결 판정도 초기화
- 로그아웃·탈퇴(`AuthService`): 토큰 삭제 직후 `ChatWebSocketService().disconnect()`

## 2단계로 이월 (제외 파일 수정 필요)

- 알림 목록 지연 생성: 부모 스크롤(`notification_screen.dart`)을 sliver로 바꿔야 함
- 채팅 업로드 말풍선 원본 디코딩 (`chat_message_item.dart`)
- 홈 피드 다음 카드 precache (`home_tab_screen.dart`) — `AppImageCacheManager.instance`와 같은 디코딩 크기를 써야 캐시 공유
- 목록 placeholder 경량화: 시각 변화(shimmer 제거)라 디자인 확인 필요
- 세션 만료(`api_client.dart`)·제재 경로의 웹소켓 해제: 세션 정리 지점(`user_session_lifecycle.dart`)에서 `ChatWebSocketService().disconnect()` 호출 (로그아웃·탈퇴는 1단계에서 처리)
- 회원 정보 단일화: 스플래시(`splash_screen.dart`)의 `MemberManager.getCurrentMember()`를 provider로 이전
