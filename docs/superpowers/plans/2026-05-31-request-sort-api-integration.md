# 요청 목록 정렬 — API 연동 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** 이미 머지된 정렬 칩 UI가 실제로 받은/보낸 요청 목록을 BE 정렬 파라미터로 재조회하도록 연동한다.

**Architecture:** 현재 정렬 칩 `onChanged`는 `setState`로 선택값만 저장하고 목록은 안 바뀐다. FE `RequestSortType`을 BE `TradeRequestSortField`(`sortField`) + `Sort.Direction`(`sortDirection`)으로 매핑하고, 화면의 직접 API 호출(`TradeApi.getReceived/getSentTradeRequests`)에 정렬값을 실어 재조회한다. 화면이 provider/repository를 우회해 직접 API를 호출하므로 repository/provider는 건드리지 않는다.

**BE 확정 컨벤션 (RomRom-BE, 배포 완료):**
- `sortField`: enum name 그대로 — `CREATED_DATE` / `PRICE` / `AI_RECOMMENDED`
- `sortDirection`: `ASC` / `DESC` (AI_RECOMMENDED는 무시)
- 엔드포인트: `/api/trade/get/received`, `/api/trade/get/sent` (multipart fields)

**FE→BE 매핑:**

| RequestSortType | sortField | sortDirection |
|---|---|---|
| latest | CREATED_DATE | DESC |
| priceHigh | PRICE | DESC |
| priceLow | PRICE | ASC |
| aiRecommend | AI_RECOMMENDED | DESC(무시) |

> 주의: 사용자 명시 허락 없이 commit/파일삭제 금지(CLAUDE.md). Commit 스텝은 사용자 승인 후 `/cassiiopeia:commit`.

---

## File Structure

- **Modify** `lib/enums/request_sort_type.dart` — BE 매핑 게터(`serverSortField`, `serverDirection`) 추가, 기존 `serverName` 정리
- **Modify** `lib/models/apis/requests/trade_request.dart` — `sortField`/`sortDirection` 필드 추가
- **Regenerate** `lib/models/apis/requests/trade_request.g.dart` — build_runner
- **Modify** `lib/services/apis/trade_api.dart` — `getReceived/getSentTradeRequests`의 multipart fields에 정렬 키 추가
- **Modify** `lib/screens/request_management_tab_screen.dart` — 로드 시 정렬값 전달 + `onChanged`에서 재로드

---

### Task 1: RequestSortType에 BE 매핑 추가

**Files:** Modify `lib/enums/request_sort_type.dart`

- [ ] **Step 1: enum을 BE 정렬 필드/방향 매핑으로 교체**

기존 `serverName`(PRICE_HIGH 등 BE에 없는 값)을 BE 실제 enum에 맞춘 `serverSortField` + `serverDirection`으로 대체:

```dart
enum RequestSortType {
  latest(label: '최신순', serverSortField: 'CREATED_DATE', serverDirection: 'DESC'),
  priceHigh(label: '가격 높은순', serverSortField: 'PRICE', serverDirection: 'DESC'),
  priceLow(label: '가격 낮은순', serverSortField: 'PRICE', serverDirection: 'ASC'),
  aiRecommend(label: 'AI 추천순', serverSortField: 'AI_RECOMMENDED', serverDirection: 'DESC');

  final String label;
  final String serverSortField; // BE TradeRequestSortField enum name
  final String serverDirection; // BE Sort.Direction (ASC/DESC), AI_RECOMMENDED는 무시됨

  const RequestSortType({required this.label, required this.serverSortField, required this.serverDirection});
}
```

- [ ] **Step 2: `serverName` 잔존 참조 확인**

Run: `grep -rn "\.serverName" lib/ | grep -i sort`
Expected: RequestSortType.serverName 참조 0건 (있으면 해당 위치를 serverSortField로 교체)

- [ ] **Step 3: analyze**

Run: `source ~/.zshrc && flutter analyze lib/enums/request_sort_type.dart`
Expected: error 없음

- [ ] **Step 4: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 2: TradeRequest 모델에 정렬 필드 추가

**Files:** Modify `lib/models/apis/requests/trade_request.dart`, Regenerate `.g.dart`

- [ ] **Step 1: 필드 + 생성자 파라미터 추가**

`reviewComment` 다음에 필드 추가:

```dart
  String? reviewComment;
  String? sortField; // BE TradeRequestSortField enum name (CREATED_DATE/PRICE/AI_RECOMMENDED)
  String? sortDirection; // BE Sort.Direction (ASC/DESC)
```

생성자에 추가:

```dart
    this.reviewComment,
    this.sortField,
    this.sortDirection,
```

- [ ] **Step 2: build_runner로 .g.dart 재생성**

Run: `source ~/.zshrc && dart run build_runner build --delete-conflicting-outputs`
Expected: `trade_request.g.dart`에 `sortField`/`sortDirection` 직렬화 추가됨, 빌드 성공

- [ ] **Step 3: 재생성 확인**

Run: `grep -n "sortField\|sortDirection" lib/models/apis/requests/trade_request.g.dart`
Expected: toJson/fromJson에 두 키 등장

- [ ] **Step 4: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 3: trade_api 정렬 파라미터 전달

**Files:** Modify `lib/services/apis/trade_api.dart`

- [ ] **Step 1: getReceivedTradeRequests fields에 정렬 추가**

`final Map<String, dynamic> fields = {'takeItemId': request.takeItemId};` 를 정렬값 포함으로 교체:

```dart
    final Map<String, dynamic> fields = {
      'takeItemId': request.takeItemId,
      if (request.sortField != null) 'sortField': request.sortField,
      if (request.sortDirection != null) 'sortDirection': request.sortDirection,
    };
```

- [ ] **Step 2: getSentTradeRequests fields에도 동일 적용**

`getSentTradeRequests`의 fields(현재 `{'giveItemId': request.giveItemId}` 형태)에 동일하게 `sortField`/`sortDirection` 조건부 추가.

> 구현 시: `sed -n '94,120p' lib/services/apis/trade_api.dart`로 getSent의 정확한 fields 구성을 확인한 뒤 같은 패턴으로 추가.

- [ ] **Step 3: analyze**

Run: `source ~/.zshrc && flutter analyze lib/services/apis/trade_api.dart`
Expected: error 없음

- [ ] **Step 4: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 4: 화면 — 정렬값 전달 + 변경 시 재로드

**Files:** Modify `lib/screens/request_management_tab_screen.dart`

- [ ] **Step 1: 받은 요청 로드에 정렬값 전달**

`_loadReceivedRequestsForCurrentCard`의 API 호출(현재 `TradeRequest(takeItemId: takeItemId, pageNumber: 0, pageSize: 10)`)에 정렬 추가:

```dart
      final received = await TradeApi().getReceivedTradeRequests(
        TradeRequest(
          takeItemId: takeItemId,
          pageNumber: 0,
          pageSize: 10,
          sortField: _receivedSortType.serverSortField,
          sortDirection: _receivedSortType.serverDirection,
        ),
      );
```

- [ ] **Step 2: 보낸 요청 로드에 정렬값 전달**

`_loadSentRequestsForCurrentCard`의 `api.getSentTradeRequests(TradeRequest(giveItemId: card.itemId))` 를:

```dart
            return await api.getSentTradeRequests(
              TradeRequest(
                giveItemId: card.itemId,
                sortField: _sentSortType.serverSortField,
                sortDirection: _sentSortType.serverDirection,
              ),
            );
```

- [ ] **Step 3: 받은 요청 정렬칩 onChanged에서 재로드**

라인 ~691 `onChanged: (selected) => setState(() => _receivedSortType = selected)` 를 재로드 포함으로:

```dart
                    onChanged: (selected) {
                      if (selected == _receivedSortType) return;
                      setState(() => _receivedSortType = selected);
                      _loadReceivedRequestsForCurrentCard();
                    },
```

- [ ] **Step 4: 보낸 요청 정렬칩 onChanged에서 재로드**

라인 ~290 `onChanged: (selected) => setState(() => _sentSortType = selected)` 를:

```dart
            onChanged: (selected) {
              if (selected == _sentSortType) return;
              setState(() => _sentSortType = selected);
              _loadSentRequestsForCurrentCard();
            },
```

- [ ] **Step 5: format + analyze**

Run: `source ~/.zshrc && dart format --line-length=120 lib/screens/request_management_tab_screen.dart lib/enums/request_sort_type.dart lib/models/apis/requests/trade_request.dart lib/services/apis/trade_api.dart`
Run: `source ~/.zshrc && flutter analyze lib/`
Expected: No issues found

- [ ] **Step 6: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

## 수동 검증

- 받은/보낸 탭에서 정렬 칩 → 바텀시트 → 옵션 선택 시 목록이 실제 재조회되어 순서 변경됨
- 최신순/가격높은순(PRICE+DESC)/가격낮은순(PRICE+ASC)/AI추천순(AI_RECOMMENDED) 각각 정상 동작
- 같은 옵션 재선택 시 불필요한 재조회 없음(early return)
- 받은/보낸 탭 정렬 상태 독립 유지
- `flutter analyze` 통과
