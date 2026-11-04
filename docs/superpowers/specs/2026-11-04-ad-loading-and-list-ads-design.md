# 광고 로딩 속도 개선 + 목록 네이티브 광고 설계 (#985)

## 1. 홈 피드 광고 로딩 문제 (원인)
- 첫 피드 도착 시 광고 자리 배치 없음 > 첫 loadMore 전까지 광고 칸·미리 요청 없음, loadMore 때 지나간 index 5에 광고가 끼어 보던 칸이 밀림
- 미리 받기 2페이지 앞·1개 보관, 광고 칸 위젯이 dispose 때 광고 폐기 > 되돌아오거나 반쯤 넘기다 취소하면 재요청
- 이미 로드된 광고도 `isLoadedFuture.then` 비동기 > 한 프레임 스켈레톤
- UMP·MobileAds 초기화가 env·네이버 지도·Google 로그인 초기화 뒤 시작, 동의 불필요해도 `loadConsentForm`

## 2. 홈 피드 결정
| 항목 | 결정 |
|---|---|
| 소유 | `HomeFeedNativeAdPreloader` = 광고 칸 가상 index > 광고 보관소 (화면 상태, 위젯은 빌리고 반납만) |
| 미리 요청 | 현재 위치 5페이지 앞까지 모든 광고 칸 (첫 광고 칸 5 > 첫 피드 도착 즉시 요청) |
| 재요청 | 미리 받기 실패 시 칸당 최대 2회, 그래도 없으면 칸 접기 |
| 폐기 | 12페이지 넘게 지난 칸, 안 보인 채 50분 지난 광고, 칸 접힘(뒤 칸 index 당김), 화면 종료 |
| 피드 교체 | 보인 광고 폐기, 안 보인 광고는 새 광고 칸에 요청 없이 재배정 |
| 그리는 중 폐기 | 보관 해제돼도 반납 때까지 미룸 (AdWidget 표시 중 dispose 방지) |
| 첫 프레임 | `NativeAdHandle.isLoaded` 동기 값 > 받은 광고는 첫 빌드부터 AdWidget |
| SDK 시작 | `AdSdkInitializer.start()`를 `main()` 첫 줄 직후 호출, 기다리지 않음 |

### UMP 순서 (Google 권장)
1. `canRequestAds()`(지난 세션 동의) true > 즉시 `MobileAds.initialize()`
2. 동시에 `requestConsentInfoUpdate` > `loadAndShowConsentFormIfRequired` (필요할 때만 폼)
3. 폼 닫힘·갱신 실패 후 다시 `canRequestAds()` > 가능하면 초기화, 불가면 요청 금지 확정
- 모든 광고 요청은 `AdSdkInitializer.whenAdRequestAllowed` 뒤 (동의 전 요청 금지)
- 앱 ID는 Info.plist·AndroidManifest(빌드 설정) 값 > 런타임 env 불필요
- ATT 요청은 앱에 없음 (변경 없음). IDFA 안내가 필요하면 AdMob 콘솔 UMP 메시지에서 설정

### iOS SKAdNetwork
- `SKAdNetworkItems` 50개 추가 (Google AdMob iOS 빠른 시작 문서 목록, 2026-11-04 확인)

## 3. 목록 네이티브 광고
- 배치 규칙: `ListAdPlacement` 순수 함수 하나 (콘텐츠 index <-> 목록 index)
  - 채팅방: 3번째 방 뒤 1개 (방 3개 이상일 때만)
  - 좋아요·내 물품: 8개마다 1개 (8·16번째 뒤)
- 광고 칸 위치는 고정 목록 index > 목록이 바뀌어도 같은 칸 유지 (keepAlive로 재요청 없음)
- 렌더링: 네이티브 팩토리 `listNativeAd` (iOS `ListNativeAdFactory.swift`, Android `ListNativeAdFactory.kt`)
  - NativeTemplateStyle 대신 팩토리를 고른 이유: "광고" 한글 배지·Pretendard·앱 토큰 색 유지, 홈 피드 팩토리 옵션 읽기·폰트 등록 재사용
  - 레이아웃: [아이콘 44] [광고 배지 + 헤드라인 / 본문] [CTA 알약], AdChoices는 SDK 자동 배치(오른쪽 위)
  - 바탕 `AppColors.listNativeAdBackground` (목록 바탕과 구분), 칸 위아래 8px 간격 (행 탭 영역·메뉴 버튼과 분리)
- 높이: `ListNativeAdStyle.cellHeight(textScaler)` 고정 px 계산 (iPad에서 `.h` 배율로 커지지 않음)
- 로드 중: 같은 높이 바탕만 표시 (로드 후 행이 밀려 오클릭 유도하는 일 방지)
- 광고 ID 없음·실패: 높이 0으로 접힘, 칸 아래 구분선도 칸이 함께 그려 같이 접힘 (구분선 중복 없음)
- 광고 단위: `.env` `NATIVE_LIST_ADMOB_UNIT_ID_ANDROID/IOS` (선택) > 없으면 홈 피드 네이티브 ID, 디버그·테스트 빌드는 Google 테스트 네이티브 ID
- 광고 제거(프리미엄) 플래그: 현재 앱에 없음 > 분기 없음

## 4. 테스트
- `test/utils/list_ad_placement_test.dart`: 배치·왕복 변환·범위 밖
- `test/widgets/home_tab/home_feed_native_ad_preloader_test.dart`: 칸별 보관, 반납 유지, 지난 칸 폐기, 그리는 중 폐기 미룸, 재요청 상한, 만료, 피드 교체 재사용, 칸 접힘 index 당김, 동기 isLoaded
- `test/widgets/native_ad_widget_test.dart`: 화면에서 빠져도 폐기 안 함, 실패 > 칸 접기 알림
- `test/widgets/list_native_ad/list_native_ad_cell_test.dart`: 로드 중 높이 확보, 실패·ID 없음 > 높이 0, 종료 시 폐기

## 5. 하지 않는 것
- 광고 보관소 Riverpod 전역화 (화면 수명과 같아 화면 소유로 충분)
- 목록 광고 칸 간 광고 공유 캐시 (칸별 keepAlive로 충분)
- 실기기 확인 전 광고 위치·간격 수치 추가 조정
