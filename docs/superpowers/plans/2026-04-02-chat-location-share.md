# 채팅 위치 공유 기능 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 채팅방에서 위치를 선택해 지도 말풍선으로 전송하고, 수신자는 탭하여 네이버지도에서 해당 위치를 확인할 수 있다.

**Architecture:** `ChatLocationPickerScreen`(위치 선택)이 `LocationAddress`를 반환하면 `ChatRoomScreen`이 WebSocket으로 LOCATION 타입 메시지를 전송한다. 수신 측은 `ChatLocationBubble`이 Naver Static Maps API 이미지 + 주소 텍스트 + 딥링크 버튼으로 렌더링한다.

**Tech Stack:** flutter_naver_map, geolocator, url_launcher, http, flutter_dotenv, flutter_screenutil

---

## 파일 맵

| 역할 | 파일 | 신규/수정 |
|---|---|---|
| MessageType enum | `lib/enums/message_type.dart` | 수정 |
| ChatMessage 모델 | `lib/models/apis/objects/chat_message.dart` | 수정 |
| ChatMessage generated | `lib/models/apis/objects/chat_message.g.dart` | 수정 |
| App URL 상수 | `lib/models/app_urls.dart` | 수정 |
| WebSocket 전송 | `lib/services/chat_websocket_service.dart` | 수정 |
| 위치 선택 화면 | `lib/screens/chat_location_picker_screen.dart` | 신규 |
| 위치 말풍선 위젯 | `lib/widgets/chat_location_bubble.dart` | 신규 |
| 채팅 입력 바 | `lib/widgets/chat_input_bar.dart` | 수정 |
| 메시지 아이템 | `lib/widgets/chat_message_item.dart` | 수정 |
| 채팅방 화면 | `lib/screens/chat_room_screen.dart` | 수정 |

---

## Task 1: MessageType + ChatMessage 모델 업데이트

**Files:**
- Modify: `lib/enums/message_type.dart`
- Modify: `lib/models/apis/objects/chat_message.dart`
- Modify: `lib/models/apis/objects/chat_message.g.dart`
- Modify: `lib/models/app_urls.dart`

- [ ] **Step 1: MessageType에 LOCATION 추가**

`lib/enums/message_type.dart` 전체 교체:
```dart
import 'package:json_annotation/json_annotation.dart';

/// 채팅 메시지 타입 (백엔드 MessageType Enum)
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('SYSTEM')
  system,
  @JsonValue('LOCATION')
  location,
}
```

- [ ] **Step 2: ChatMessage 모델에 위치 필드 추가**

`lib/models/apis/objects/chat_message.dart`에서 필드·생성자·copyWith 수정:
```dart
// lib/models/apis/objects/chat_message.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'chat_message.g.dart';

/// 채팅 메시지 모델 (MongoDB)
@JsonSerializable()
class ChatMessage extends BaseEntity {
  final String? chatMessageId;
  final String? chatRoomId;
  final String? senderId;
  final String? recipientId;
  final String? content;
  final List<String>? imageUrls;
  final MessageType? type;
  final bool? isProfanityDetected;
  final double? latitude;
  final double? longitude;
  final String? address;

  ChatMessage({
    super.createdDate,
    super.updatedDate,
    this.chatMessageId,
    this.chatRoomId,
    this.senderId,
    this.recipientId,
    this.content,
    this.imageUrls,
    this.type,
    this.isProfanityDetected,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

/// ChatMessage 복사 및 수정용 확장 메서드
extension ChatMessageCopy on ChatMessage {
  ChatMessage copyWith({
    String? chatMessageId,
    String? chatRoomId,
    String? senderId,
    String? recipientId,
    String? content,
    List<String>? imageUrls,
    MessageType? type,
    bool? isProfanityDetected,
    DateTime? createdDate,
    DateTime? updatedDate,
    double? latitude,
    double? longitude,
    String? address,
  }) => ChatMessage(
    chatMessageId: chatMessageId ?? this.chatMessageId,
    chatRoomId: chatRoomId ?? this.chatRoomId,
    senderId: senderId ?? this.senderId,
    recipientId: recipientId ?? this.recipientId,
    content: content ?? this.content,
    imageUrls: imageUrls ?? this.imageUrls,
    type: type ?? this.type,
    isProfanityDetected: isProfanityDetected ?? this.isProfanityDetected,
    createdDate: createdDate ?? this.createdDate,
    updatedDate: updatedDate ?? this.updatedDate,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    address: address ?? this.address,
  );
}
```

- [ ] **Step 3: .g.dart 파일 수동 업데이트**

`lib/models/apis/objects/chat_message.g.dart` 전체 교체:
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  chatMessageId: json['chatMessageId'] as String?,
  chatRoomId: json['chatRoomId'] as String?,
  senderId: json['senderId'] as String?,
  recipientId: json['recipientId'] as String?,
  content: json['content'] as String?,
  imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
  type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']),
  isProfanityDetected: json['isProfanityDetected'] as bool?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  address: json['address'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'chatMessageId': instance.chatMessageId,
  'chatRoomId': instance.chatRoomId,
  'senderId': instance.senderId,
  'recipientId': instance.recipientId,
  'content': instance.content,
  'imageUrls': instance.imageUrls,
  'type': _$MessageTypeEnumMap[instance.type],
  'isProfanityDetected': instance.isProfanityDetected,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address': instance.address,
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'TEXT',
  MessageType.image: 'IMAGE',
  MessageType.system: 'SYSTEM',
  MessageType.location: 'LOCATION',
};
```

- [ ] **Step 4: AppUrls에 Static Maps URL 추가**

`lib/models/app_urls.dart`에 한 줄 추가:
```dart
static const String naverStaticMapApiUrl =
    'https://naveropenapi.apigw.ntruss.com/map-static/v2/raster';
```

- [ ] **Step 5: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 6: 커밋**

```bash
git add lib/enums/message_type.dart \
        lib/models/apis/objects/chat_message.dart \
        lib/models/apis/objects/chat_message.g.dart \
        lib/models/app_urls.dart
git commit -m "feat: ChatMessage에 LOCATION 타입 및 위치 필드 추가 (#이슈번호)"
```

---

## Task 2: ChatWebSocketService 위치 전송 지원

**Files:**
- Modify: `lib/services/chat_websocket_service.dart:241-272`

- [ ] **Step 1: sendMessage 시그니처 및 payload 확장**

`sendMessage` 메서드를 아래로 교체:
```dart
/// 메시지 전송
void sendMessage({
  required String chatRoomId,
  required String content,
  MessageType type = MessageType.text,
  List<String>? imageUrls,
  double? latitude,
  double? longitude,
  String? address,
}) {
  if (type == MessageType.image && (imageUrls == null || imageUrls.isEmpty)) {
    throw Exception('imageUrls is required for image messages');
  }
  if (type == MessageType.location && (latitude == null || longitude == null)) {
    throw Exception('latitude and longitude are required for location messages');
  }
  if (!_isConnected || _stompClient == null) {
    debugPrint('[WebSocket] Cannot send message: Not connected');
    throw Exception('STOMP not connected');
  }

  final Map<String, dynamic> payload = {
    'chatRoomId': chatRoomId,
    'content': content,
    'type': type.toString().split('.').last.toUpperCase(),
  };

  if (type == MessageType.image && imageUrls != null) {
    payload['imageUrls'] = imageUrls;
  }

  if (type == MessageType.location) {
    payload['latitude'] = latitude;
    payload['longitude'] = longitude;
    payload['address'] = address;
  }

  debugPrint('[WebSocket] Sending message to /app/chat.send\n$payload');
  _stompClient!.send(
    destination: '/app/chat.send',
    body: jsonEncode(payload),
    headers: {'content-type': 'application/json'},
  );
}
```

- [ ] **Step 2: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 커밋**

```bash
git add lib/services/chat_websocket_service.dart
git commit -m "feat: WebSocket sendMessage에 LOCATION 타입 지원 추가 (#이슈번호)"
```

---

## Task 3: ChatLocationPickerScreen 구현

**Files:**
- Create: `lib/screens/chat_location_picker_screen.dart`

- [ ] **Step 1: 화면 파일 생성**

`lib/screens/chat_location_picker_screen.dart` 신규 생성:
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:shadex/shadex.dart';

/// 채팅 위치 보내기 - 위치 선택 화면
/// 선택 완료 시 Navigator.pop(context, LocationAddress)로 반환
class ChatLocationPickerScreen extends StatefulWidget {
  const ChatLocationPickerScreen({super.key});

  @override
  State<ChatLocationPickerScreen> createState() => _ChatLocationPickerScreenState();
}

class _ChatLocationPickerScreenState extends State<ChatLocationPickerScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  NLatLng? _selectedPosition;
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() => _currentPosition = seoulCityHall);
      await _updateAddress(seoulCityHall);
      return;
    }
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      final latLng = _locationService.positionToLatLng(position);
      setState(() => _currentPosition = latLng);
      await _updateAddress(latLng);
    } else {
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() => _currentPosition = seoulCityHall);
      await _updateAddress(seoulCityHall);
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final address = await _locationService.getAddressFromCoordinates(position);
    if (address != null && mounted) {
      setState(() {
        _selectedPosition = position;
        _selectedAddress = address;
      });
    }
  }

  Future<void> _onSend() async {
    if (_isSending || _selectedAddress == null || _selectedPosition == null) return;
    setState(() => _isSending = true);
    try {
      final result = LocationAddress(
        siDo: _selectedAddress!.siDo,
        siGunGu: _selectedAddress!.siGunGu,
        eupMyoenDong: _selectedAddress!.eupMyoenDong,
        ri: _selectedAddress!.ri,
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: '위치 전송에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '위치 보내기'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // 네이버 지도
                Positioned.fill(
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                      : NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(target: _currentPosition!, zoom: 15),
                            logoAlign: NLogoAlign.leftBottom,
                            logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 137.h)),
                            indoorEnable: true,
                            locationButtonEnable: false,
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                              controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                            }
                          },
                          onCameraIdle: () async {
                            final controller = await _mapControllerCompleter.future;
                            final position = await controller.getCameraPosition();
                            await _updateAddress(position.target);
                          },
                        ),
                ),
                // 중앙 핀
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 40.h),
                    child: Shadex(
                      shadowColor: AppColors.opacity20Black,
                      shadowBlurRadius: 2.0,
                      shadowOffset: const Offset(2, 2),
                      child: SvgPicture.asset('assets/images/location-pin.svg'),
                    ),
                  ),
                ),
                // 보내기 버튼
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 57.h,
                  child: CompletionButton(
                    isEnabled: _selectedAddress != null,
                    isLoading: _isSending,
                    buttonText: '보내기',
                    enabledOnPressed: _onSend,
                  ),
                ),
                // 현재 위치 버튼
                Positioned(
                  bottom: isTablet ? 200 : 160.h,
                  left: 24.w,
                  child: CurrentLocationButton(
                    onTap: () async {
                      final controller = await _mapControllerCompleter.future;
                      final position = await _locationService.getCurrentPosition();
                      if (position != null && mounted) {
                        final newPosition = _locationService.positionToLatLng(position);
                        await controller.updateCamera(
                          NCameraUpdate.fromCameraPosition(NCameraPosition(target: newPosition, zoom: 15)),
                        );
                        controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                        setState(() => _currentPosition = newPosition);
                        await _updateAddress(newPosition);
                      }
                    },
                    iconSize: 24.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 커밋**

```bash
git add lib/screens/chat_location_picker_screen.dart
git commit -m "feat: 채팅 위치 선택 화면(ChatLocationPickerScreen) 추가 (#이슈번호)"
```

---

## Task 4: ChatLocationBubble 위젯 구현

**Files:**
- Create: `lib/widgets/chat_location_bubble.dart`

- [ ] **Step 1: 위젯 파일 생성**

`lib/widgets/chat_location_bubble.dart` 신규 생성:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:url_launcher/url_launcher.dart';

/// LOCATION 타입 메시지 말풍선
/// - Static Maps API 이미지 (264w × 160h)
/// - 주소 텍스트
/// - "지도에서 보기" 버튼 → 네이버지도 앱 or 웹 폴백
class ChatLocationBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatLocationBubble({super.key, required this.message});

  String? _buildStaticMapUrl() {
    final lat = message.latitude;
    final lng = message.longitude;
    if (lat == null || lng == null) return null;
    final center = '$lng,$lat';
    final markerPos = Uri.encodeComponent('$lng $lat');
    return '${AppUrls.naverStaticMapApiUrl}'
        '?w=264&h=160'
        '&center=$center'
        '&level=15'
        '&markers=type:d|size:mid|pos:$markerPos';
  }

  Future<void> _openNaverMap() async {
    final lat = message.latitude;
    final lng = message.longitude;
    if (lat == null || lng == null) return;

    final appUri = Uri.parse('nmap://map?lat=$lat&lng=$lng&zoom=15&appname=com.alom.romrom');
    final webUri = Uri.parse('https://map.naver.com/v5/?c=$lng,$lat,15,0,0,0,dh');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staticMapUrl = _buildStaticMapUrl();
    final address = message.address ?? '위치';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 지도 이미지
            SizedBox(
              width: 220,
              height: 130,
              child: staticMapUrl != null
                  ? Image.network(
                      staticMapUrl,
                      width: 220,
                      height: 130,
                      fit: BoxFit.cover,
                      headers: {
                        'X-NCP-APIGW-API-KEY-ID': dotenv.get('NMF_CLIENT_ID'),
                        'X-NCP-APIGW-API-KEY': dotenv.get('NMF_CLIENT_SECRET'),
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.secondaryBlack2,
                        child: const Center(
                          child: Icon(Icons.map_outlined, color: AppColors.opacity50White, size: 32),
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.secondaryBlack2,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.secondaryBlack2,
                      child: const Center(
                        child: Icon(Icons.map_outlined, color: AppColors.opacity50White, size: 32),
                      ),
                    ),
            ),
            // 주소 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                address,
                style: CustomTextStyles.p3.copyWith(
                  color: AppColors.textColorWhite,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 구분선
            Container(height: 1, color: AppColors.opacity10White),
            // 지도에서 보기 버튼
            GestureDetector(
              onTap: _openNaverMap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  '지도에서 보기',
                  style: CustomTextStyles.p3.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 커밋**

```bash
git add lib/widgets/chat_location_bubble.dart
git commit -m "feat: 채팅 위치 말풍선(ChatLocationBubble) 위젯 추가 (#이슈번호)"
```

---

## Task 5: ChatInputBar 위치 메뉴 항목 추가

**Files:**
- Modify: `lib/widgets/chat_input_bar.dart`

- [ ] **Step 1: onSendLocation 콜백 파라미터 추가 및 메뉴 항목 추가**

`ChatInputBar` 클래스 수정:

생성자 파라미터에 추가:
```dart
final VoidCallback onSendLocation;
```

`const ChatInputBar({...})` required 목록에 추가:
```dart
required this.onSendLocation,
```

`items` 리스트에 위치 항목 추가 (기존 `select_photo` 항목 다음):
```dart
ContextMenuItem(
  id: 'send_location',
  icon: AppIcons.location,
  iconColor: AppColors.opacity60White,
  title: '위치 보내기',
  onTap: () => onSendLocation(),
),
```

- [ ] **Step 2: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 커밋**

```bash
git add lib/widgets/chat_input_bar.dart
git commit -m "feat: ChatInputBar에 위치 보내기 메뉴 항목 추가 (#이슈번호)"
```

---

## Task 6: ChatMessageItem LOCATION 타입 처리

**Files:**
- Modify: `lib/widgets/chat_message_item.dart`

- [ ] **Step 1: import 추가 + _buildBubble에 LOCATION 분기 추가**

파일 상단 import에 추가:
```dart
import 'package:romrom_fe/widgets/chat_location_bubble.dart';
```

`_buildBubble` 메서드 내 `if (message.type == MessageType.image)` 블록 바로 위에 추가:
```dart
if (message.type == MessageType.location) {
  return ChatLocationBubble(message: message);
}
```

- [ ] **Step 2: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: 커밋**

```bash
git add lib/widgets/chat_message_item.dart
git commit -m "feat: ChatMessageItem에 LOCATION 타입 말풍선 렌더링 추가 (#이슈번호)"
```

---

## Task 7: ChatRoomScreen 연결

**Files:**
- Modify: `lib/screens/chat_room_screen.dart`

- [ ] **Step 1: import 추가**

`chat_room_screen.dart` import 목록에 추가:
```dart
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/screens/chat_location_picker_screen.dart';
```

- [ ] **Step 2: _onSendLocation 핸들러 추가**

`_onPickImage` 메서드 바로 아래에 추가:
```dart
Future<void> _onSendLocation() async {
  if (_isInputDisabled) return;
  FocusScope.of(context).unfocus();

  final LocationAddress? result = await context.navigateTo<LocationAddress>(
    screen: const ChatLocationPickerScreen(),
  );

  if (result == null || !mounted) return;

  final lat = result.latitude;
  final lng = result.longitude;
  if (lat == null || lng == null) return;

  final address = [result.siDo, result.siGunGu, result.eupMyoenDong]
      .where((s) => s.isNotEmpty)
      .join(' ');

  _wsService.sendMessage(
    chatRoomId: widget.chatRoomId,
    content: address,
    type: MessageType.location,
    latitude: lat,
    longitude: lng,
    address: address,
  );
}
```

- [ ] **Step 3: ChatInputBar에 onSendLocation 연결**

`build` 메서드 내 `ChatInputBar(...)` 위젯에 파라미터 추가:
```dart
onSendLocation: _onSendLocation,
```

- [ ] **Step 4: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze
```
Expected: No issues found.

- [ ] **Step 5: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 .
```

- [ ] **Step 6: 최종 커밋**

```bash
git add lib/screens/chat_room_screen.dart
git commit -m "feat: 채팅방 위치 보내기 기능 연결 완료 (#이슈번호) [skip ci]"
```

---

## 수동 검증 체크리스트

구현 완료 후 기기에서 직접 확인:

- [ ] `+` 버튼 탭 → "위치 보내기" 메뉴 항목 노출
- [ ] "위치 보내기" 탭 → 전체화면 지도 진입, 현재 위치로 초기화
- [ ] 지도 이동 → 하단 주소 텍스트 업데이트
- [ ] 현재 위치 버튼 → 지도가 현재 위치로 이동
- [ ] "보내기" 탭 → 채팅방으로 복귀, 위치 말풍선 노출
- [ ] 말풍선에 Static Maps 이미지 + 주소 텍스트 표시
- [ ] "지도에서 보기" 탭 → 네이버지도 앱 실행 (앱 있을 때)
- [ ] "지도에서 보기" 탭 → 웹 브라우저 열림 (앱 없을 때)
- [ ] 상대방 수신 측에서도 말풍선 정상 렌더링
- [ ] 위치 권한 거부 시 서울시청 폴백 후 정상 동작
- [ ] iPad에서 말풍선 overflow 없음
