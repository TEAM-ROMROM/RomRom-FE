# 게시글 삭제 제재 알림 화면 — FCM 라우팅 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 관리자가 게시글을 삭제 제재했을 때 FCM 알림 클릭으로 `ItemDeletedScreen`(게시글 제목 + 삭제 사유)을 띄운다.

**Architecture:** 4/20 임시 작업의 `ITEM_DELETED_NOTICE` API-응답 글로벌 인터셉터를 제거하고, BE가 실제 발송하는 `ITEM_DELETED_BY_ADMIN` FCM 알림을 딥링크 라우터로 처리한다. 화면 표시값(`itemName`/`deleteReason`)은 deepLink 쿼리가 아닌 FCM data payload에서 직접 읽어 한글 인코딩 이슈를 피한다.

**Tech Stack:** Flutter, firebase_messaging, 기존 `RomRomDeepLinkRouter` / `NotificationType` enum.

**BE 확정 컨벤션 (RomRom-BE#741):**
- deepLink: `romrom://item/deleted`
- FCM data 키: `itemName`(게시글 제목), `deleteReason`(사유 카테고리 description)

**Spec:** `docs/superpowers/specs/2026-05-31-item-deleted-notice-fcm-design.md`

---

## File Structure

- **Modify** `lib/services/api_client.dart` — stale `ITEM_DELETED_NOTICE` 인터셉터(필드/메서드/호출 3곳/import 2개) 제거
- **Delete** `lib/exceptions/item_deleted_exception.dart` — 인터셉터 전용 예외, 불필요
- **Modify** `lib/enums/notification_type.dart` — `itemDeletedByAdmin` enum 멤버 + 아이콘 case 추가
- **Modify** `lib/utils/deep_link_router.dart` — `item/deleted` routeKey 케이스 + data 전달 경로(`extraData`) 추가
- **Modify** `lib/services/firebase_service.dart` — `_routeFromFcmData`가 data 맵을 라우터에 전달
- **Modify** `lib/screens/item_deleted_screen.dart` — `ApiClient.resetItemDeletedFlag()` 의존 제거(단순 `Navigator.pop`)

> 주의: 본 프로젝트는 사용자 명시 허락 없이 commit 금지(CLAUDE.md). 각 Task의 "Commit" 스텝은 **사용자 승인 후** `/cassiiopeia:commit`으로 수행한다. 단독 `git commit` 금지.

---

### Task 1: stale ITEM_DELETED_NOTICE 인터셉터 제거

**Files:**
- Modify: `lib/services/api_client.dart`
- Delete: `lib/exceptions/item_deleted_exception.dart`

- [ ] **Step 1: import 2줄 제거**

`lib/services/api_client.dart` 상단에서 아래 두 import 삭제:

```dart
import 'package:romrom_fe/exceptions/item_deleted_exception.dart';
import 'package:romrom_fe/screens/item_deleted_screen.dart';
```

- [ ] **Step 2: 플래그 필드 + 리셋 메서드 제거**

아래 블록 삭제:

```dart
  /// 게시글 삭제 알림 중복 처리 방지 플래그
  static bool _isItemDeletedHandling = false;
```

```dart
  /// 게시글 삭제 플래그 리셋 (ItemDeletedScreen 닫을 때 호출)
  static void resetItemDeletedFlag() {
    _isItemDeletedHandling = false;
  }
```

- [ ] **Step 3: `_handleItemDeletedResponse` 메서드 전체 제거**

`static ItemDeletedException? _handleItemDeletedResponse(http.Response response) { ... }` 메서드 블록 전체(주석 `/// ITEM_DELETED_NOTICE 응답 글로벌 처리` 포함) 삭제.

- [ ] **Step 4: 호출부 3곳 제거**

3개 위치에서 아래 2줄(주석 포함) 삭제:

```dart
      // 게시글 삭제 알림 체크 (ITEM_DELETED_NOTICE)
      _handleItemDeletedResponse(response);
```

- [ ] **Step 5: 예외 파일 삭제**

```bash
rm lib/exceptions/item_deleted_exception.dart
```

- [ ] **Step 6: analyze로 잔존 참조 없는지 검증**

Run: `source ~/.zshrc && flutter analyze lib/services/api_client.dart`
Expected: `ItemDeletedException`/`ItemDeletedScreen`/`_handleItemDeletedResponse` 관련 error 없음 (단, 이 시점 `item_deleted_screen.dart`의 `resetItemDeletedFlag` 참조는 Task 5에서 정리하므로 전체 analyze는 Task 5 후 수행)

- [ ] **Step 7: Commit (사용자 승인 후)**

`/cassiiopeia:commit` — 단독 git commit 금지.

---

### Task 2: NotificationType에 itemDeletedByAdmin 추가

**Files:**
- Modify: `lib/enums/notification_type.dart`

- [ ] **Step 1: enum 멤버 추가**

`systemNotice(...)` 다음에 추가 (마지막 멤버이므로 직전 항목 끝 `;`를 `,`로 바꾸고 추가):

```dart
  systemNotice(label: '공지사항', serverName: 'SYSTEM_NOTICE'),
  itemDeletedByAdmin(label: '게시글 삭제', serverName: 'ITEM_DELETED_BY_ADMIN');
```

- [ ] **Step 2: svgAssetPath switch case 추가**

`svgAssetPath` getter의 switch에 case 추가 (공지 아이콘 재사용 — 전용 아이콘 없음):

```dart
      case NotificationType.itemDeletedByAdmin:
        return 'assets/images/notificationAnnouncement.svg';
```

- [ ] **Step 3: analyze**

Run: `source ~/.zshrc && flutter analyze lib/enums/notification_type.dart`
Expected: error 없음 (switch exhaustive 충족)

- [ ] **Step 4: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 3: deep_link_router에 item/deleted 라우팅 + data 전달

**Files:**
- Modify: `lib/utils/deep_link_router.dart`

- [ ] **Step 1: `ItemDeletedScreen` import 추가**

```dart
import 'package:romrom_fe/screens/item_deleted_screen.dart';
```

- [ ] **Step 2: 라우팅 메서드 시그니처에 `extraData` 파라미터 추가**

`open`, `openFromUri`, `_openRomRomScheme` 세 메서드에 `Map<String, dynamic>? extraData` 옵셔널 파라미터를 추가하고 호출 체인으로 전달한다.

`open`:
```dart
  static Future<void> open(BuildContext context, String? deepLink,
      {NotificationType? notificationType, Map<String, dynamic>? extraData}) async {
    if (deepLink == null || deepLink.trim().isEmpty) return;
    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;
    await openFromUri(context, uri, notificationType: notificationType, extraData: extraData);
  }
```

`openFromUri`:
```dart
  static Future<void> openFromUri(BuildContext context, Uri uri,
      {NotificationType? notificationType, Map<String, dynamic>? extraData}) async {
    if (uri.scheme == 'romrom') {
      await _openRomRomScheme(context, uri, notificationType: notificationType, extraData: extraData);
    } else if (uri.scheme == 'https' && uri.host == _hostingDomain) {
      await _openHttpsLink(context, uri);
    }
  }
```

`_openRomRomScheme` 선언부:
```dart
  static Future<void> _openRomRomScheme(BuildContext context, Uri uri,
      {NotificationType? notificationType, Map<String, dynamic>? extraData}) async {
```

- [ ] **Step 3: switch에 `item/deleted` 케이스 추가**

`case 'chat/room':` 블록 다음, `default:` 앞에 추가:

```dart
      case 'item/deleted':
        {
          // 화면 표시값은 deepLink 쿼리가 아닌 FCM data payload에서 읽는다 (한글 인코딩 회피)
          final itemName = extraData?['itemName'] as String? ?? '';
          final deleteReason = extraData?['deleteReason'] as String? ?? '';

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDeletedScreen(itemTitle: itemName, deleteReason: deleteReason),
            ),
          );
          return;
        }
```

- [ ] **Step 4: analyze**

Run: `source ~/.zshrc && flutter analyze lib/utils/deep_link_router.dart`
Expected: error 없음

- [ ] **Step 5: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 4: firebase_service가 FCM data를 라우터에 전달

**Files:**
- Modify: `lib/services/firebase_service.dart`

- [ ] **Step 1: `_routeFromFcmData`가 data를 extraData로 전달**

`_routeFromFcmData` 마지막 라우팅 호출을 수정:

```dart
    RomRomDeepLinkRouter.openFromUri(context, uri, notificationType: notificationType, extraData: data);
```

- [ ] **Step 2: 콜드스타트 경로에 extraData 보관/전달 추가 (필수 — 소비처 확인됨)**

콜드스타트 경로가 실재한다(`lib/main.dart:142` `setPending`, `lib/screens/splash_screen.dart:122~130` 소비). 현재 `ColdStartDeepLinkData`는 `uri`+`notificationType`만 보관하므로, 보강하지 않으면 **앱 종료 상태에서 알림 클릭 시 itemName/deleteReason이 빈 값**으로 뜬다.

`lib/utils/deep_link_router.dart`의 `ColdStartDeepLinkData`에 extraData 필드/getter 추가:

```dart
  static Map<String, dynamic>? _pendingExtraData;
  static Map<String, dynamic>? get pendingExtraData => _pendingExtraData;
```

`setPending` 시그니처에 `extraData` 추가 + 저장:

```dart
  static void setPending(Uri uri, {NotificationType? notificationType, Map<String, dynamic>? extraData}) {
    if (_pendingUri != null && notificationType == null) {
      return;
    }
    _pendingUri = uri;
    _pendingNotificationType = notificationType ?? _pendingNotificationType;
    _pendingExtraData = extraData ?? _pendingExtraData;
  }
```

`clear`에 `_pendingExtraData = null;` 추가.

`lib/main.dart:142` — FCM data가 있는 경로의 `setPending` 호출에 `extraData: <data map>` 전달. (main.dart의 해당 함수가 RemoteMessage.data를 들고 있는지 확인 후, 들고 있으면 그 맵을 전달. 없으면 그 호출 시점에 data가 없는 일반 app_links 경로이므로 생략.)

`lib/screens/splash_screen.dart:130` — pending 소비 호출에 extraData 전달:

```dart
            RomRomDeepLinkRouter.openFromUri(ctx, pendingUri,
                notificationType: pendingType, extraData: ColdStartDeepLinkData.pendingExtraData);
```

단 `splash_screen.dart:125`에서 `clear()`를 호출하므로, **`clear()` 호출 전에** `pendingExtraData`를 지역 변수로 보관한 뒤 전달한다(`pendingUri`/`pendingType`이 이미 그렇게 처리됨 — 동일 패턴 적용):

```dart
        final pendingUri = ColdStartDeepLinkData.pendingUri!;
        final pendingType = ColdStartDeepLinkData.pendingNotificationType;
        final pendingExtra = ColdStartDeepLinkData.pendingExtraData;
        ColdStartDeepLinkData.clear();
        ...
            RomRomDeepLinkRouter.openFromUri(ctx, pendingUri, notificationType: pendingType, extraData: pendingExtra);
```

- [ ] **Step 3: analyze**

Run: `source ~/.zshrc && flutter analyze lib/services/firebase_service.dart lib/utils/deep_link_router.dart`
Expected: error 없음

- [ ] **Step 4: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

### Task 5: ItemDeletedScreen에서 인터셉터 의존 제거

**Files:**
- Modify: `lib/screens/item_deleted_screen.dart`

- [ ] **Step 1: `_handleClose`에서 resetItemDeletedFlag 호출 제거**

```dart
  /// X 버튼: 화면 닫기
  void _handleClose() {
    Navigator.of(context).pop();
  }
```

- [ ] **Step 2: 사용 안 하는 `ApiClient` import 제거**

`import 'package:romrom_fe/services/api_client.dart';` 가 더 이상 참조되지 않으면 삭제.

- [ ] **Step 3: 전체 analyze (Task 1~5 통합 검증)**

Run: `source ~/.zshrc && flutter analyze`
Expected: 본 작업 관련 error 0건. (기존 무관 warning은 범위 밖)

- [ ] **Step 4: format**

Run: `source ~/.zshrc && dart format --line-length=120 lib/services/api_client.dart lib/enums/notification_type.dart lib/utils/deep_link_router.dart lib/services/firebase_service.dart lib/screens/item_deleted_screen.dart`

- [ ] **Step 5: Commit (사용자 승인 후)** — `/cassiiopeia:commit`

---

## 수동 검증 (구현 후)

BE #741 배포 전이라 실제 FCM 테스트는 불가. 코드 레벨 검증:
- `flutter analyze` 통과
- `item/deleted` deepLink + `extraData={itemName, deleteReason}` → `ItemDeletedScreen` 진입 경로가 컴파일 단계에서 연결됨
- 기존 알림(`item/detail`, `chat/room`) 라우팅 회귀 없음 (extraData 옵셔널이라 영향 없음)
- `ITEM_DELETED_NOTICE` 잔존 참조 0건: `grep -rn "ITEM_DELETED_NOTICE\|ItemDeletedException\|resetItemDeletedFlag\|_handleItemDeletedResponse" lib/`

BE #741 배포 후: 관리자 물품 삭제 → 알림 클릭 → 화면에 게시글 제목/사유 정확 표시 E2E 확인.
