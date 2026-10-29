# 게시글 삭제 제재 알림 화면 — FCM 라우팅 방식 설계

**이슈**: [#786](https://github.com/TEAM-ROMROM/RomRom-FE/issues/786)
**브랜치**: `20260420_#786_서비스_제재_페이지_추가`
**작성일**: 2026-05-31
**관련 BE**: [#629](https://github.com/TEAM-ROMROM/RomRom-BE/issues/629)(closed), [#662](https://github.com/TEAM-ROMROM/RomRom-BE/issues/662)(closed)

---

## 요구사항

관리자가 회원의 게시글(물품)을 가이드라인 위반으로 삭제 제재했을 때, 해당 회원에게 **게시글 제목 + 삭제 사유**를 안내하는 전용 화면을 표시한다.

디자인 기준: 이슈 #786 첨부 이미지 3번 ("게시글이 커뮤니티 가이드라인 위반으로 삭제되었습니다" + 콘텐츠 정보(게시글 제목) + 삭제 사유 + 문의하기 버튼).

> 참고: #786 디자인 1번(일시 제한)·2번(영구 제한)은 **계정 제재**로, 이미 `AccountSuspendedScreen`(이슈 #582)에 구현돼 있다. 본 작업 범위는 **3번 게시글 삭제 화면**에 한정한다.

---

## 배경 — 기존 작업과 BE 실제 구현의 불일치

### 4/20 임시 작업 (현 브랜치에 존재)
4/20에 BE 미구현 상태에서 임시 설계로 다음을 만들었다:
- `lib/screens/item_deleted_screen.dart` — 게시글 삭제 화면 (디자인 3번 일치, **재사용**)
- `lib/exceptions/item_deleted_exception.dart` — `ITEM_DELETED_NOTICE` 에러코드 감지용 예외
- `lib/services/api_client.dart` — API 응답에서 `ITEM_DELETED_NOTICE` 에러코드를 감지해 화면을 띄우는 **글로벌 인터셉터**

### BE 실제 구현 (#629/#662, 배포 완료)
BE는 에러코드 방식이 아닌 **FCM 푸시 알림** 방식으로 구현했다:
- `ItemService.deleteItemByAdmin()` → `ItemDeletedByAdminEvent` 발행 → 영향받은 회원에게 FCM 발송
- `NotificationType.ITEM_DELETED_BY_ADMIN` 존재
- 알림 body: `"회원님의 물품 '{물품명}'이(가) '{사유}' 사유로 삭제되었습니다."`
- 사유 카테고리: `ItemAdminDeleteReason` enum (거래 금지 품목 / 사기 의심 / 부적절한 콘텐츠 / 저작권 침해 / 신고 누적 / 기타)
- FCM data payload: 현재 `{ notificationType: "ITEM_DELETED_BY_ADMIN" }`만 포함

### 불일치 결론
게시글 삭제는 관리자가 **나중에 비동기로** 수행하는 작업이다. "다음 API 호출 시 에러코드를 받는" 글로벌 인터셉터 방식으로는 이 비동기 이벤트를 잡을 수 없다. **기존 `ITEM_DELETED_NOTICE` 인터셉터 방식은 폐기하고, BE가 실제로 사용하는 FCM 알림 라우팅 방식으로 전환한다.**

---

## 설계

### 데이터 흐름

```
관리자 게시글 삭제 (BE)
  └─ ItemDeletedByAdminEvent → FCM 푸시 발송
       data payload:
         notificationType : "ITEM_DELETED_BY_ADMIN"
         deepLink         : "romrom://item/deleted"    ← BE 추가 필요
         itemName         : "{게시글 제목}"             ← BE 추가 필요
         deleteReason     : "{사유 카테고리 description}" ← BE 추가 필요
  └─ FE 알림 수신/클릭
       firebase_service.dart::_routeFromFcmData(data)
         └─ deepLink 파싱 → RomRomDeepLinkRouter.openFromUri
              └─ _openRomRomScheme: routeKey "item/deleted" 케이스 추가
                   └─ ItemDeletedScreen(itemTitle: itemName, deleteReason) push

> BE payload 키는 기존 알림 이벤트(`ItemLikedEvent` 등) 컨벤션을 따른다:
> deepLink는 `romrom://{도메인}/{액션}?{key}=value` 형태, payload 키는 엔티티 필드명 camelCase(`itemName`).
> deepLink에 itemName/deleteReason을 쿼리로 실으면 한글·특수문자 인코딩 이슈가 있으므로,
> **라우팅 트리거는 deepLink(`romrom://item/deleted`)로, 화면 표시값(`itemName`/`deleteReason`)은
> data payload의 별도 키에서 직접 읽는다.**
```

### FE 변경 사항

1. **`NotificationType` enum에 `itemDeletedByAdmin` 추가**
   `lib/enums/notification_type.dart` — `serverName: 'ITEM_DELETED_BY_ADMIN'`, label/아이콘 정의. (현재 4개만 있어 이 타입 수신 시 `fromServerName`이 처리 못 함 → 알림 목록/라우팅에서 인식 가능하도록 추가)

2. **딥링크 라우팅 케이스 추가**
   `lib/utils/deep_link_router.dart` — `_openRomRomScheme`의 switch에 `item/deleted` routeKey 추가. 화면 표시값(`itemName`/`deleteReason`)은 deepLink 쿼리가 아니라 **FCM data payload에서 직접 읽어** `ItemDeletedScreen`으로 전달한다(한글 인코딩 회피). 이를 위해 `firebase_service.dart::_routeFromFcmData`가 `RomRomDeepLinkRouter`에 data의 부가 필드를 함께 넘기도록 시그니처를 확장하거나, 라우터가 ColdStart 경로와 동일하게 data 맵을 받도록 한다.

3. **stale 인터셉터 제거**
   `lib/services/api_client.dart` — `_handleItemDeletedResponse`, `_isItemDeletedHandling`, `resetItemDeletedFlag`, `ITEM_DELETED_NOTICE` 관련 코드 전부 제거. `item_deleted_exception.dart` 삭제. `ItemDeletedScreen`의 `ApiClient.resetItemDeletedFlag()` 호출부도 단순 `Navigator.pop`으로 정리.

4. **`ItemDeletedScreen` 유지**
   화면 자체는 디자인 3번과 일치하므로 그대로 사용. 단 인터셉터 의존(`resetItemDeletedFlag`) 제거에 따른 `_handleClose` 정리만 반영.

### BE 변경 사항 (별도 이슈)

현재 BE는 물품명·사유를 **FCM body 문자열에만** 담는다. FE가 전용 화면에 구조화해 표시하려면 **data payload에 분리 필드가 필요**하다.

`ItemDeletedByAdminEvent.payload`에 다음 키 추가 요청:
- `deepLink`: `"romrom://item-deleted"` (FE 라우팅 트리거)
- `itemTitle`: 삭제된 물품명 (`deletedItemName`)
- `deleteReason`: 사유 카테고리 description (`adminDeleteReason.getDescription()`)

> `adminDeleteDetail`(상세 사유)은 "사용자 비공개" 정책이므로 payload에 포함하지 않는다. 화면에는 카테고리 description만 표시한다.

---

## 범위 밖 (YAGNI)

- **"내 제재내역 조회" 전용 API**: 알림을 놓친 경우 나중에 다시 보는 기능은 본 이슈 범위 밖. 디자인은 "알림 받은 순간 1건 안내" 화면이므로 FCM payload만으로 충분. (필요 시 후속 이슈)
- **계정 제재 화면(1·2번)**: 이미 구현됨, 건드리지 않음.
- **포그라운드 수신 시 자동 화면 전환**: 사용자가 사용 중일 때 강제 전환은 UX 침해. 알림 클릭(`onMessageOpenedApp`) / 콜드스타트 경로로만 진입. 포그라운드는 기존 인앱 알림 표시에 위임.

---

## 테스트 관점

- FCM data에 `deepLink=romrom://item-deleted` + `itemTitle` + `deleteReason` 포함 시 알림 클릭 → `ItemDeletedScreen` 진입
- 화면에 게시글 제목 / 삭제 사유 정확히 바인딩
- 콜드스타트(앱 종료 상태)에서 알림 클릭 시 `ColdStartDeepLinkData` 경유 진입
- `ITEM_DELETED_NOTICE` 인터셉터 제거 후 기존 API 흐름 정상 (회귀 없음)
- 문의하기 버튼 mailto 동작
