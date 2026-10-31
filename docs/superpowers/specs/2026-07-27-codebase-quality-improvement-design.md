# 코드베이스 전반 품질 개선 로드맵 설계

> 2026-07-27 진단 기반. 서브프로젝트 3개(A→B→C)로 분해해 순차 진행한다.
> 각 서브프로젝트는 별도 이슈·브랜치·PR로 나간다.

## 진단 요약 (2026-07-27, main @ 2fce92b / v1.10.105)

**정상 항목**: `flutter analyze` 이슈 0건, 이벤트 버스 잔재 없음, GlobalKey 교차호출 없음,
enum 위치 규칙·AlertDialog 금지·isTablet 규칙 모두 준수.

**개선 대상**:

| 항목 | 규모 | 위험도 |
|------|------|--------|
| A. 스타일·네비게이션 규칙 위반 | 직접 TextStyle 55건 + 직접 Color 39건 + MaterialPageRoute 7건 | 낮음 (기계적) |
| B. 대형 파일 분해 | 900줄 이상 5개 파일 | 중간 (동작 불변 리팩터링) |
| C. Riverpod 마이그레이션 확대 | services 직접 import 화면 31/41개 중 공유 도메인 화면 선별 | 높음 (구조 변경) |

---

## 서브프로젝트 A — 스타일·네비게이션 규칙 위반 일괄 정리

### 대상 및 처리 원칙

**A1. 직접 `TextStyle(` 55건 → CustomTextStyles 통일**

| 위치 | 건수 | 처리 |
|------|------|------|
| `lib/debug/widgets/` 3개 패널 + menu | 29 | debug 전용 반복 패턴은 `CustomTextStyles`에 debug 스타일 신규 추가 후 참조 |
| `lib/widgets/coach_mark/pages/` 5개 | 9 | 기존 스타일 매핑 또는 `copyWith` 파생 |
| `notification_bottom_sheet` 등 실사용 위젯 | 17 | 기존 스타일 매핑 또는 `copyWith` 파생 |

- 우선순위: ① 기존 `CustomTextStyles` 스타일 그대로 매핑 → ② `CustomTextStyles.pN.copyWith(...)` 파생
  → ③ 3회 이상 반복되는 패턴만 신규 스타일 추가
- 폰트 크기·굵기·색상 등 **시각적 결과는 기존과 동일해야 한다** (동작·외관 불변)

**A2. 직접 `Color(0x` 39건 → AppColors 통일**

- `AppColors` 기존 상수와 동일 값이면 그 상수 참조
- 없는 값은 기존 명명 규칙(`opacityNN<색상>` / 용도명 + 한국어 주석)으로 신규 상수 추가
- debug 패널 전용 색상은 `// 디버그 패널 전용` 주석 블록으로 묶어 추가

**A3. `MaterialPageRoute` 직접 사용 7건 → `context.navigateTo()` 교체**

| 파일 | 건수 |
|------|------|
| `lib/utils/deep_link_router.dart` | 4 |
| `lib/screens/register_tab_screen.dart` | 2 |
| `lib/widgets/home_feed_item_widget.dart` | 1 |

- `lib/utils/common_utils.dart` 내부의 MaterialPageRoute는 `navigateTo` 구현부이므로 유지
- push 반환값(`await` 결과)을 사용하는 곳은 `navigateTo<T>`의 반환값으로 동일하게 처리

### 검증
- `dart format --line-length=120 .` + `flutter analyze` 통과
- 변경 파일이 속한 화면 스모크 확인 (빌드 통과 기준)

---

## 서브프로젝트 B — 대형 파일 5개 분해

### 대상 (진행 순서대로)

1. `lib/screens/item_detail_description_screen.dart` (1,131줄)
2. `lib/screens/chat_room_screen.dart` (1,065줄)
3. `lib/widgets/home_tab_card_hand.dart` (1,039줄)
4. `lib/widgets/register_input_form.dart` (948줄)
5. `lib/screens/request_management_tab_screen.dart` (907줄)

### 원칙
- **동작 불변 위젯 추출**: private 빌더 메서드/대형 build 블록을 별도 위젯 파일로 이동
- 상태 로직(setState·provider 연동)은 건드리지 않는다 — 순수 UI 추출만
- 파일당 목표 500줄 이하, 추출 위젯은 `lib/widgets/<화면명>/` 하위로 그룹화
- 파일별 분해 단위는 B의 plan 단계에서 각 파일을 읽고 확정
- 파일 1개 = 커밋 1개 단위로 진행 (리뷰·롤백 용이)

---

## 서브프로젝트 C — Riverpod 마이그레이션 확대

### 원칙
- 화면 41개 중 `services/` 직접 import 31개를 분석해 **공유 도메인 상태를 만지는 화면만** 선별
  (화면 로컬 1회성 API 호출 — 신고 제출 등 — 은 규칙상 허용, 대상 아님)
- 선별된 도메인별로 `.claude/instructions/state-management.md` 레시피 적용:
  repository → state → provider(+test) → 화면 구독 전환
- 비동기 목록 로딩은 `AsyncNotifier`, optimistic 토글은 동기 `Notifier` + `_inFlight` dedup
- 대상 도메인 목록·우선순위는 C 시작 시점에 분석해 별도 spec으로 확정한다

---

## 진행 흐름

1. 서브프로젝트별 이슈 생성 → 브랜치 분리
2. A: plan 작성 → 구현 → 커밋(사용자 승인) → PR
3. A 머지 후 B, B 머지 후 C — 각 단계 시작 전 해당 상세 plan을 사용자 승인 후 진행
4. A를 먼저 하는 이유: B에서 위젯을 추출하기 전에 스타일 규칙을 정리해두면
   추출된 위젯이 처음부터 규칙 준수 상태가 되어 이중 작업이 없다
