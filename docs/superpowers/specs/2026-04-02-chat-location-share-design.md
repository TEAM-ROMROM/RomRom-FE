# 채팅 위치 공유 기능 설계

**날짜:** 2026-04-02  
**이슈:** 채팅방 위치 보내기 기능

---

## 개요

채팅방에서 본인의 위치를 지도 말풍선 형태로 전송하는 기능.  
백엔드와 `MessageType.LOCATION`으로 소통하며, Naver Static Maps API로 지도 썸네일을 렌더링한다.

---

## 유저 플로우

1. 채팅 입력 바 `+` 버튼 탭 → 컨텍스트 메뉴 "위치 보내기" 선택
2. `ChatLocationPickerScreen` 진입 — 현재 위치로 초기화된 전체 화면 네이버 지도
3. 지도를 움직여 원하는 위치 선택 → "보내기" 버튼
4. `Navigator.pop`으로 `LocationAddress` 반환 → `ChatRoomScreen`에서 WebSocket 전송
5. 채팅창에 위치 말풍선 노출
6. 말풍선 "지도에서 보기" 버튼 → 네이버지도 앱 실행 (없으면 웹)

---

## 데이터 변경

### `MessageType` (lib/enums/message_type.dart)
```dart
@JsonValue('LOCATION')
location,
```

### `ChatMessage` (lib/models/apis/objects/chat_message.dart)
필드 3개 추가:
```dart
final double? latitude;
final double? longitude;
final String? address;
```
`build_runner`로 `.g.dart` 재생성 필요.

### `ChatWebSocketService.sendMessage`
LOCATION 타입일 때 payload에 포함:
```json
{
  "chatRoomId": "...",
  "type": "LOCATION",
  "latitude": 37.5665,
  "longitude": 126.9780,
  "address": "서울특별시 광진구 능동로 209"
}
```

---

## 새 파일

### 1. `lib/screens/chat_location_picker_screen.dart`

`ItemRegisterLocationScreen`과 동일한 패턴:
- 초기 위치: 현재 위치 (권한 없으면 서울시청 폴백)
- 중앙 핀 SVG + 카메라 idle 시 역지오코딩
- 하단 "보내기" 버튼: `Navigator.pop(context, selectedAddress)`
- 커스텀 `CurrentLocationButton`

### 2. `lib/widgets/chat_location_bubble.dart`

말풍선 구조 (264.w 고정폭):
```
┌────────────────────────┐
│   Naver Static Map     │  Image.network (264w × 160h)
│   이미지 (마커 포함)    │
├────────────────────────┤
│  주소 텍스트            │  padding 12w/10h
├────────────────────────┤
│    지도에서 보기         │  GestureDetector 버튼
└────────────────────────┘
```

**Static Maps API:**
```
URL: https://naveropenapi.apigw.ntruss.com/map-static/v2/raster
  ?w=264&h=160
  &center={lng},{lat}
  &level=15
  &markers=type:d|size:mid|pos:{lng}%20{lat}
Headers:
  X-NCP-APIGW-API-KEY-ID: {NMF_CLIENT_ID}
  X-NCP-APIGW-API-KEY: {NMF_CLIENT_SECRET}
```
`Image.network`의 `headers` 파라미터로 인증.  
로딩 중: shimmer 또는 Container(color: AppColors.secondaryBlack1)  
에러 시: 주소 텍스트만 표시

**"지도에서 보기" 딥링크:**
```dart
// 앱
nmap://map?lat={lat}&lng={lng}&zoom=15&appname=com.alom.romrom
// 웹 폴백
https://map.naver.com/v5/?c={lng},{lat},15,0,0,0,dh
```

---

## 수정 파일

### `lib/widgets/chat_input_bar.dart`
- `onSendLocation: VoidCallback` 파라미터 추가
- `ContextMenuItem` 리스트에 위치 항목 추가

### `lib/widgets/chat_message_item.dart`
- `_buildBubble`에 LOCATION 타입 분기:
  ```dart
  if (message.type == MessageType.location) {
    return ChatLocationBubble(message: message);
  }
  ```

### `lib/screens/chat_room_screen.dart`
- `_onSendLocation()` 핸들러 추가
- `ChatLocationPickerScreen` push 후 결과 받아 WebSocket 전송

---

## 고려사항

- **Static Maps API**: NCP 콘솔에서 "Maps Static API" 서비스 활성화 필요
- **iPad 대응**: 말풍선 고정 픽셀값 사용 (`.w` 최소화)
- **에러 처리**: 위치 권한 거부 시 서울시청 폴백 (기존 패턴 동일)
- **중복 전송 방지**: `_pendingRequests` 패턴 적용
