# 게시글 삭제 제재 알림 화면 설계

**이슈**: #786  
**브랜치**: `20260420_#786_서비스_제재_페이지_추가`  
**작성일**: 2026-04-20

---

## 요구사항

관리자가 유저의 게시글을 삭제 제재했을 때, 해당 유저에게 삭제 사실과 사유를 안내하는 전용 화면을 표시한다.

---

## 설계 방향

계정 제재(`AccountSuspendedScreen`)와 동일한 글로벌 인터셉터 패턴을 사용한다.

```
API 호출
  └─ api_client.dart 응답 처리
       └─ 특정 에러코드 감지 (ITEM_DELETED_NOTICE)
            └─ ItemDeletedException throw
                 └─ ItemDeletedScreen으로 전환
```

**계정 제재와의 차이점**:
- 계정 제재: 403 + `SUSPENDED_MEMBER` → 토큰 삭제 후 스택 초기화
- 게시글 삭제: 2xx or 특정 코드 + `ITEM_DELETED_NOTICE` → **토큰 유지**, 화면만 표시 후 닫기 가능

---

## 백엔드 요청 스펙 (백엔드 전달용)

프론트가 감지할 응답 형식:

```json
{
  "errorCode": "ITEM_DELETED_NOTICE",
  "itemTitle": "게시글 제목",
  "deleteReason": "삭제 사유"
}
```

- 어떤 API 응답에서든 `errorCode == "ITEM_DELETED_NOTICE"` 이면 프론트가 감지
- 계정 제재처럼 **중복 처리 방지 플래그** 적용 (한 번만 표시)
- 화면 닫기 후 플래그 리셋 → 다음 삭제 시 다시 표시 가능

---

## 신규 파일 목록

| 파일 | 설명 |
|------|------|
| `lib/exceptions/item_deleted_exception.dart` | 게시글 삭제 예외 클래스 |
| `lib/screens/item_deleted_screen.dart` | 게시글 삭제 안내 화면 |

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/services/api_client.dart` | `ITEM_DELETED_NOTICE` 에러코드 감지 핸들러 추가 |
| `lib/enums/error_code.dart` | `itemDeletedNotice` 에러코드 추가 |

---

## UI 스펙 (Figma node: 8867:8812)

### 레이아웃

```
Scaffold (배경: AppColors.primaryBlack)
├── SafeArea
│   ├── [좌상단] X 닫기 버튼 (44x44 터치영역, 화면 닫기)
│   ├── [상단 여백] SizedBox(height: 40)
│   ├── 제목 RichText
│   │   "게시글이 커뮤니티 가이드라인\n위반으로 "
│   │   + "삭제" (색상: AppColors.warningRed #FF5656)
│   │   + "되었습니다"
│   ├── SizedBox(height: 40)
│   ├── 정보 박스 (Container, 배경: AppColors.secondaryBlack1 #34353D, radius: 10)
│   │   ├── • 콘텐츠 정보 : {itemTitle}
│   │   ├── • 삭제 사유 : {deleteReason}
│   │   └── * 반복적인 가이드라인 위반 시 서비스 이용이 제한될 수 있습니다.
│   ├── Spacer
│   └── 문의하기 버튼 (AppColors.primaryYellow, height: 56, radius: 10)
│       └── mailto: romrom.noreply@gmail.com
```

### 텍스트 스타일

| 요소 | 스타일 |
|------|--------|
| 제목 | `CustomTextStyles.h1`, height: 1.2 |
| "삭제" 강조 | 위 동일 + `AppColors.warningRed` |
| 정보 항목 | `CustomTextStyles.p1`, weight: w500, height: 1.2 |
| 경고 문구 | `CustomTextStyles.p3`, weight: w500, `AppColors.opacity60White` |
| 버튼 텍스트 | `CustomTextStyles.p1`, weight: w600, `AppColors.textColorBlack` |

---

## ItemDeletedException

```dart
class ItemDeletedException implements Exception {
  final String itemTitle;
  final String deleteReason;
  // ...
}
```

---

## api_client.dart 처리 로직

`AccountSuspendedScreen` 핸들러 직후에 추가:

```dart
static bool _isItemDeletedHandling = false;

static void resetItemDeletedFlag() {
  _isItemDeletedHandling = false;
}

static ItemDeletedException? _handleItemDeletedResponse(http.Response response) {
  if (_isItemDeletedHandling) return null;
  // body에서 errorCode == 'ITEM_DELETED_NOTICE' 감지
  // navigatorKey로 ItemDeletedScreen push (스택 유지)
  // 플래그 set
}
```

**계정 제재와의 차이**: `clearStackImmediate` 대신 일반 `push` — 유저가 X 버튼으로 닫고 돌아올 수 있음.

---

## 백엔드 전달 메모

> Spring Security에서 인증된 요청에 대해 해당 유저의 삭제된 게시글이 있으면  
> `ITEM_DELETED_NOTICE` 에러코드와 `itemTitle`, `deleteReason` 필드를 응답에 포함시켜 주세요.  
> 프론트는 모든 API 응답에서 이 코드를 감지해 자동으로 알림 화면을 표시합니다.
