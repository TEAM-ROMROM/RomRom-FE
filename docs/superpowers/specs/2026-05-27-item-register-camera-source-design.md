# 상품 등록 사진 추가 — 카메라/갤러리 소스 선택 설계

작성일: 2026-05-27
관련 화면: `lib/widgets/register_input_form.dart`

## 배경

상품 등록 화면에서 사진 칸을 누르면 **곧바로 로컬 갤러리 다중선택**(`pickMultiImage`)으로 진입한다. 사용자가 그 자리에서 바로 사진을 **촬영**하는 경로가 없다. 카메라 촬영과 앨범 선택을 사용자가 고를 수 있게 개선한다.

## 목표

- 사진 칸 탭 시 "사진 촬영하기 / 앨범에서 선택하기" 중 선택 가능
- 기존 갤러리 다중선택 흐름은 그대로 유지
- 카메라/앨범 권한을 기업 표준 방식(사전 체크 + 거부 안내 + 설정 이동)으로 처리
- iPad/대형기기 대응 규칙 준수 (모달은 고정 픽셀값)

## 비목표 (YAGNI)

- 채팅 입력바 / 프로필 이미지 변경의 소스 선택 추가 (이번 범위 아님)
- 촬영 후 크롭/편집 (상품 사진은 크롭 불필요)
- 카메라 연속 촬영 (1장씩 촬영 후 목록 추가로 충분)

## 결정 요약

| 항목 | 결정 |
|------|------|
| 선택 UI | 바텀시트 (`showModalBottomSheet`) |
| 촬영 후 동작 | 1장 즉시 `_newImageFiles`에 추가 (크롭 없음, 갤러리와 동일) |
| 권한 처리 | `permission_handler` 사전 체크 → 거부 안내 스낵바 → 영구거부 시 `openAppSettings()` |
| 적용 범위 | 상품 등록(`register_input_form.dart`)만 |
| 구조 | 공통 바텀시트 위젯 + 권한/픽 헬퍼 분리 |

## 아키텍처 / 컴포넌트

### 1. `lib/widgets/common/image_source_bottom_sheet.dart` (신규)

소스 선택 바텀시트. UI만 책임진다.

```dart
/// 사진 소스 선택 바텀시트. 선택된 ImageSource 반환, 취소 시 null.
Future<ImageSource?> showImageSourceBottomSheet(BuildContext context)
```

- `showModalBottomSheet`로 2개 항목 표시: 카메라(촬영) / 갤러리(앨범)
- 각 항목: 아이콘 + 라벨. `AppIcons`, `AppColors`, `CustomTextStyles` 사용
- **iPad 대응**: 항목 높이/패딩 고정 픽셀값 사용 (`.w`/`.h` 금지 — CLAUDE.md 모달 규칙)
- 내부 콘텐츠는 `Column(mainAxisSize: MainAxisSize.min)`로 고정 높이 미사용
- 항목 탭 시 `Navigator.pop(context, ImageSource.camera | gallery)`

### 2. `lib/utils/camera_permission_helper.dart` (신규 또는 기존 권한 유틸 합류)

카메라 권한 사전 체크 헬퍼. `permission_handler` 사용.

```dart
/// 카메라 권한 확보. 허용되면 true.
/// 거부 시 스낵바 안내, 영구거부 시 설정 이동 제안 후 false.
Future<bool> ensureCameraPermission(BuildContext context)
```

- `Permission.camera.status` 확인
- `denied` → `request()` 호출
- `granted` → true
- `permanentlyDenied` → CommonSnackBar 안내 + `openAppSettings()` 제안 → false
- 갤러리는 `image_picker`가 시스템 picker를 띄우므로 별도 권한 사전 체크 불필요 (기존 동작 유지)

> 기존 `lib/services/notification_permission_service.dart` 등 권한 처리 패턴을 참고해 일관성 유지.

### 3. `register_input_form.dart` 수정 (`onPickImage`)

```
onPickImage():
  _hasImageBeenTouched = true
  10장 한도 체크 (기존)
  source = await showImageSourceBottomSheet(context)
  if source == null: return            // 취소
  if source == camera:
    if !await ensureCameraPermission(context): return
    XFile? shot = await _picker.pickImage(source: camera)
    if shot == null: return            // 촬영 취소
    _newImageFiles.add(shot); setState
  else (gallery):
    기존 pickMultiImage 흐름 그대로
```

- 카메라 더블탭 방지: `bool _isPickingImage` 가드 또는 `Set` 패턴 (CLAUDE.md UI 규칙)
- 한도 체크는 바텀시트 진입 전에 1회

## 데이터 흐름

```
사진 칸 탭
  → 10장 한도 체크
  → showImageSourceBottomSheet
       ├ [촬영] → ensureCameraPermission → pickImage(camera) → _newImageFiles.add → setState
       ├ [앨범] → pickMultiImage(gallery) → toAdd 계산 → _newImageFiles.addAll → setState
       └ [취소/바깥탭] → return
```

## 권한 / 플랫폼 설정

- **iOS** `ios/Runner/Info.plist`: `NSCameraUsageDescription` 키 추가 (촬영 사유 문구). 누락 시 iOS 크래시.
- **Android** `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.CAMERA"/>` 추가.
- `permission_handler` 패키지가 pubspec에 이미 있는지 확인. 없으면 추가 (내부망 — 사용자가 별도 pub get 필요).

## 에러 처리

| 상황 | 처리 |
|------|------|
| 바텀시트 취소 | 조용히 return |
| 카메라 권한 거부 | 스낵바 안내, return |
| 카메라 권한 영구거부 | 스낵바 + 설정 이동 제안, return |
| 촬영 취소 (`pickImage` null) | 조용히 return |
| 10장 초과 | 기존 info 스낵바 |
| 기타 예외 | 기존 `ErrorUtils.getErrorMessage` + error 스낵바 |

## 테스트

- **위젯 단위**: `showImageSourceBottomSheet` — 카메라 탭 → `ImageSource.camera` 반환, 앨범 탭 → `gallery`, 바깥 탭 → null
- **헬퍼 단위**: `ensureCameraPermission` — granted/denied/permanentlyDenied 분기 (mock)
- **실기기 검증**: 권한 첫 요청 / 거부 / 영구거부 후 설정이동 / 촬영 1장 추가 / 촬영 취소 / 갤러리 다중선택 / 10장 한도 / iPad 바텀시트 레이아웃

## 구현 순서 (개요)

1. 플랫폼 설정 (Info.plist, AndroidManifest, pubspec 확인)
2. `image_source_bottom_sheet.dart` 작성
3. `camera_permission_helper.dart` 작성
4. `register_input_form.dart` `onPickImage` 분기 적용
5. `dart format` + 실기기 검증
