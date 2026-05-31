# 요청 관리 정렬 UI 재설계 스펙

**날짜:** 2026-05-08
**관련 이슈:** [#794](https://github.com/TEAM-ROMROM/RomRom-FE/issues/794)
**범위:** UI만. 실제 데이터 정렬·API 연동은 후속 작업.

---

## 배경

`#794` 1차 구현(현재 브랜치 `bc44972`) 후 사용자 피드백:

1. 정렬 버튼이 헤더 우측 토글 옆 인라인으로 노란 텍스트(`가격 낮은순 ▾`) 형태 — 제목과 같은 라인에 노랑이 튀어 시각 위계 모호하고 조잡함.
2. 바텀시트에서 제목("정렬") 가독성 약함 (60% 화이트, p3 작은 폰트).
3. 옵션 사이 1px 디바이더 → 무거운 인상. Mattermost 스타일(디바이더 없음, 좌측 굵은 제목)이 더 깔끔.

이 스펙은 위 3개 피드백을 해소하는 UI 재설계만 다룬다.

---

## 변경 범위

### 변경 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/screens/request_management_tab_screen.dart` | 정렬 버튼 위치/스타일 변경, 토글 라벨 단축, 받은/보낸 요청 헤더 레이아웃 재배치 |
| `lib/widgets/common/request_sort_bottom_sheet.dart` | 바텀시트 디자인 변경 (좌측 굵은 제목, 디바이더 제거) |

### 변경 안함

- `lib/enums/request_sort_type.dart` — enum 정의 그대로 유지 (label/serverName)
- 정렬 동작 로직 — 본 PR에서 추가하지 않음 (상태만 변경, 목록 재정렬 X)
- API 호출 파라미터 — 백엔드 명세 미확정. 후속 PR에서 처리.

---

## UI 디자인 결정

### 1. 정렬 버튼 — 보더 pill 칩

**위치:** 받은/보낸 요청 헤더 안에서 토글과 같은 라인. 제목/설명과는 별행.

**스타일:**
- 형태: 라운드 pill (border-radius `20`)
- 외곽선: `AppColors.primaryYellow` 50% opacity, 1px
- 배경: 투명
- 텍스트 컬러: `AppColors.primaryYellow`
- 텍스트: `[현재 정렬명] ▾` (예: `가격 낮은순 ▾`)
- 폰트: `CustomTextStyles.p3` 기준, fontWeight 500
- 패딩: `EdgeInsets.symmetric(horizontal: 12, vertical: 5)` (고정 픽셀 — iPad 과확대 방지)
- 우측 아이콘: `Icons.keyboard_arrow_down`, 크기 `14`, 컬러 `AppColors.primaryYellow`

**탭 동작:** `RequestSortBottomSheet.show()` 호출.

### 2. 토글 라벨 단축

`교환 완료된 글표시` (9자) → `완료 표시` (4자).

**근거:**
- 가로 공간 확보 — 정렬 칩 ↔ 토글 균형.
- 컨텍스트(헤더 상단 "내 물건에 온 교환 요청이에요" 설명 + 화면명 "요청 관리") 으로 의미 전달 충분.

### 3. 헤더 레이아웃

#### 받은 요청 (`_buildReceivedRequestHeader` 등 해당 영역)

```
[요청 목록]                               (좌측, p1, fontWeight 500)
내 물건에 온 교환 요청이에요               (설명, p3, opacity 50% white)
[보더 pill 정렬칩 ▾]            [완료 표시 토글]   ← 같은 라인, 좌·우 분리
[요청 카드 리스트…]
```

#### 보낸 요청 (`_buildSentRequestsList`)

- 제목/설명: 현재 코드 따름 (본 PR 추가 변경 없음)
- 정렬 칩 우측 정렬 — `Column(crossAxisAlignment: CrossAxisAlignment.end)` 유지
- 토글 없음 (보낸 요청에는 "완료 표시" 토글 부재)

> 시각 일관성 결정 — 받은 요청 칩이 우측(토글 옆)에 있으므로, 보낸 요청도 칩 위치 우측 통일. 좌측 단독 배치 시 받은/보낸 탭 전환할 때 칩 위치가 좌↔우 점프하는 인상이 나서 비추.

### 4. 바텀시트 — Mattermost 스타일

`request_sort_bottom_sheet.dart` 전면 개편.

**구조:**
```
[드래그 핸들 — 36×4, opacity 30 white, 라운드 2]
[정렬]                    ← 좌측 정렬, 굵은 제목, 17px, fontWeight 600, white
[최신순]                  ← 16/16 padding, 15px, white
[가격 높은순]
[가격 낮은순  ✓]          ← 선택 항목: primaryYellow + fontWeight 600 + 우측 ✓
[AI 추천순]
[하단 safe area 패딩]
```

**스타일:**
- 배경: `AppColors.primaryBlack`
- 상단 라운드: `BorderRadius.vertical(top: Radius.circular(16))`
- 핸들: `width: 36, height: 4, color: opacity30White, borderRadius: 2`
- 제목 영역: `padding: EdgeInsets.fromLTRB(20, 16, 20, 12)`, 좌측 정렬, 텍스트 `CustomTextStyles.p1.copyWith(fontWeight: w600)`, 컬러 `textColorWhite`
- 옵션 row: `padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16)`
  - 텍스트: `CustomTextStyles.p1`, 비선택 시 `textColorWhite` + w400, 선택 시 `primaryYellow` + w600
  - 우측 아이콘: 선택 시 `Icons.check`, 18px, `primaryYellow`. 비선택 시 아이콘 없음.
- **옵션 사이 디바이더 제거** (제목 아래 `Divider`도 제거)
- 옵션 row 하단 `Border` 제거

**고정 픽셀 사용** — `.h`, `.w` 금지 (모달 iPad 과확대 방지). 단 폰트 크기는 기존 `CustomTextStyles` 사용 (Pretendard 기반 일관 처리).

---

## 컴포넌트 구조

### 공통 정렬 칩 추출 — 별도 위젯 X

정렬 칩은 `Padding + GestureDetector + Container(decoration: BoxDecoration(border)) + Row(Text + Icon)` 조합으로 충분히 짧음. 별도 위젯 추출 안 함.

받은/보낸 요청 두 곳에서 사용 — 빌드 메서드 `_buildSortChip(RequestSortType current, ValueChanged<RequestSortType> onChanged)` 정도로 같은 파일 내 private 메서드로 추출.

### 바텀시트

`RequestSortBottomSheet.show()` API 시그니처 유지 (호출부 변경 없음). 내부 `_RequestSortSheet` 위젯의 `build` 메서드만 재작성.

---

## 비고 / 후속 작업

- **AI 추천순 옵션 라벨**: 현재 enum `aiRecommend.label = 'AI 추천순'` 그대로. 백엔드 API 명세 확정 시 라벨 조정 가능성.
- **실제 정렬 동작**: 후속 이슈에서 처리. API 정렬 파라미터(`sortBy`, `sortDirection`) 백엔드 확정 후 `_fetchSentRequests`/`_fetchReceivedRequests`에 파라미터 전달.
- **빈 상태 처리**: 정렬 칩은 빈 상태/로딩에서도 항상 표시 (현재 보낸 요청 헤더 동작과 일치).

---

## 디자인 검증 — 사용자 합의 결정사항

브레인스토밍 세션(2026-05-08) 결정 요약:

1. ✅ 정렬 버튼 — **보더 pill (E2)**: 보더형 라운드 pill, 노랑 텍스트+노랑 보더 50% opacity
2. ✅ 토글 라벨 — **F1 "완료 표시"**: 4자, 가장 짧음
3. ✅ 바텀시트 — **G2 Mattermost 스타일**: 좌측 굵은 제목, 옵션 사이 디바이더 X
4. ✅ 정렬 + 필터 합치기 비추 (F5 제외) — 정렬 단일선택 ↔ 필터 ON/OFF 멘탈모델 다름
5. ✅ 칩 직접 노출(D) 비추 — iPhone SE 가로폭 잘림 + 옵션 추가 시 깨짐
6. ✅ 본 PR 범위 — UI만 (a 옵션). API/실제 정렬 동작 후속 처리
