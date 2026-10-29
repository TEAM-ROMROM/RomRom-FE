# 상품 등록 사진 추가 — 카메라/갤러리 소스 선택 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 상품 등록 화면에서 사진 칸을 탭하면 "촬영 / 앨범 선택" 바텀시트가 떠 카메라 촬영과 기존 갤러리 다중선택 중 고를 수 있게 한다.

**Architecture:** 소스 선택 UI를 재사용 가능한 공통 바텀시트(`showImageSourceBottomSheet`)로 분리하고, 카메라 권한 사전 체크를 헬퍼(`ensureCameraPermission`)로 분리한다. `register_input_form.dart`의 `onPickImage`는 두 헬퍼를 조립해 분기만 담당한다. 갤러리 흐름(`pickMultiImage`)은 그대로 유지한다.

**Tech Stack:** Flutter, `image_picker ^1.1.2`, `permission_handler ^12.0.1` (둘 다 설치됨). `flutter_test` 위젯 테스트.

> 워크트리: `D:/0-suh/project/RomRom-FE-Worktree/20260527_#870_기능개선_상품등록_사진_추가_시_카메라_촬영_앨범_선택_지원`
> 상세 설계: `docs/superpowers/specs/2026-05-27-item-register-camera-source-design.md`

---

## File Structure

| 파일 | 책임 | 작업 |
|------|------|------|
| `lib/enums/image_pick_source.dart` | 소스 선택 결과 enum (camera/gallery) | Create |
| `lib/widgets/common/image_source_bottom_sheet.dart` | 소스 선택 바텀시트 UI. `ImagePickSource?` 반환 | Create |
| `lib/utils/camera_permission_helper.dart` | 카메라 권한 사전 체크 + 거부 안내 | Create |
| `lib/widgets/register_input_form.dart` | `onPickImage`에 소스 선택 분기 추가 | Modify (`onPickImage`, 현재 99-131) |
| `android/app/src/main/AndroidManifest.xml` | CAMERA 권한 추가 | Modify (16행 뒤) |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription` 추가 | Modify (`NSPhotoLibraryUsageDescription` 뒤, 현재 70-71) |
| `test/widgets/common/image_source_bottom_sheet_test.dart` | 바텀시트 반환값 위젯 테스트 | Create |

**enum 분리 규칙(CLAUDE.md)**: 모든 enum은 `lib/enums/`에 개별 파일로. `ImageSource`(image_picker 제공)를 직접 반환하면 위젯 테스트에서 image_picker 의존성이 끼므로, 화면 의도를 나타내는 자체 enum `ImagePickSource`를 두고 `onPickImage`에서 `ImageSource`로 매핑한다.

---

### Task 1: ImagePickSource enum

**Files:**
- Create: `lib/enums/image_pick_source.dart`

- [ ] **Step 1: enum 파일 작성**

```dart
/// 상품 사진 추가 시 사용자가 고른 입력 소스
enum ImagePickSource {
  /// 카메라로 직접 촬영
  camera,

  /// 갤러리(앨범)에서 선택
  gallery,
}
```

- [ ] **Step 2: 포맷 확인**

Run: `source ~/.zshrc && dart format --line-length=120 lib/enums/image_pick_source.dart`
Expected: `1 file ... (formatted/unchanged)` — 에러 없음

- [ ] **Step 3: 커밋하지 않음**

> 프로젝트 규칙: 커밋은 사용자 명시 승인 시에만. 여기서는 커밋하지 말고 다음 Task로 진행한다. (이 규칙은 모든 Task에 동일 적용 — 이후 Task에서 "커밋" 스텝 없음)

---

### Task 2: 소스 선택 바텀시트 위젯 (TDD)

**Files:**
- Create: `lib/widgets/common/image_source_bottom_sheet.dart`
- Test: `test/widgets/common/image_source_bottom_sheet_test.dart`

기존 `notification_bottom_sheet.dart`의 패턴을 따른다: `showModalBottomSheet<T>`, `backgroundColor: Colors.transparent`, 핸들바, `AppColors.primaryBlack` 배경, 라운드 상단(`Radius.circular(40.r)`), 하단 `SizedBox(height: MediaQuery.of(context).padding.bottom)`. 항목 높이/패딩은 **고정 픽셀값** (CLAUDE.md 모달 규칙 — `.w`/`.h` 금지). 단 라운드 반경 `.r`은 기존 바텀시트와 동일하게 허용.

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/widgets/common/image_source_bottom_sheet.dart';

void main() {
  // 바텀시트를 띄우고 반환값을 받기 위한 헬퍼
  Future<ImagePickSource?> openSheet(WidgetTester tester) async {
    ImagePickSource? result;
    late BuildContext ctx;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      ),
    );

    // 버튼 탭 없이 직접 호출
    final future = showImageSourceBottomSheet(ctx).then((v) => result = v);
    await tester.pumpAndSettle();
    // 테스트별로 항목 탭 후 future 완료
    await future;
    return result;
  }

  testWidgets('카메라 항목 탭 → ImagePickSource.camera 반환', (tester) async {
    ImagePickSource? result;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => result = await showImageSourceBottomSheet(c),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('사진 촬영하기'), findsOneWidget);
    expect(find.text('앨범에서 선택하기'), findsOneWidget);

    await tester.tap(find.text('사진 촬영하기'));
    await tester.pumpAndSettle();

    expect(result, ImagePickSource.camera);
  });

  testWidgets('앨범 항목 탭 → ImagePickSource.gallery 반환', (tester) async {
    ImagePickSource? result;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => result = await showImageSourceBottomSheet(c),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 선택하기'));
    await tester.pumpAndSettle();

    expect(result, ImagePickSource.gallery);
  });

  // openSheet 헬퍼는 위 두 테스트에서 직접 인라인으로 대체했으므로 참고용으로만 둔다.
  // ignore: unused_element
  final _ = openSheet;
}
```

> 위 `openSheet`/`final _`는 lint 경고를 피하려고 둔 참고 코드. 실제로는 두 `testWidgets`만 동작한다. 거슬리면 `openSheet`와 `final _` 라인을 삭제해도 무방하다 (테스트 동작 영향 없음).

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `source ~/.zshrc && flutter test test/widgets/common/image_source_bottom_sheet_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '...image_source_bottom_sheet.dart'` (위젯 미작성)

- [ ] **Step 3: 바텀시트 위젯 구현**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 상품 사진 추가 시 입력 소스(촬영/앨범)를 고르는 공용 바텀시트.
///
/// 선택된 [ImagePickSource]를 반환하고, 취소(바깥 탭/뒤로가기) 시 null을 반환한다.
Future<ImagePickSource?> showImageSourceBottomSheet(BuildContext context) {
  return showModalBottomSheet<ImagePickSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ImageSourceSheet(),
  );
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  static TextStyle get _itemTextStyle =>
      CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: AppColors.textColorWhite);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          // 핸들 바
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondaryBlack2,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SourceItem(
            icon: AppIcons.camera,
            label: '사진 촬영하기',
            textStyle: _itemTextStyle,
            onTap: () => Navigator.pop(context, ImagePickSource.camera),
          ),
          _SourceItem(
            icon: AppIcons.itmeRegisterImage,
            label: '앨범에서 선택하기',
            textStyle: _itemTextStyle,
            onTap: () => Navigator.pop(context, ImagePickSource.gallery),
          ),
          const SizedBox(height: 8),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  const _SourceItem({
    required this.icon,
    required this.label,
    required this.textStyle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 고정 픽셀값 (모달 iPad 대응 규칙)
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.opacity60White, size: 22),
              const SizedBox(width: 14),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

Run: `source ~/.zshrc && flutter test test/widgets/common/image_source_bottom_sheet_test.dart`
Expected: PASS — 2 tests passed (카메라/앨범 반환)

- [ ] **Step 5: 포맷 + 린트**

Run: `source ~/.zshrc && dart format --line-length=120 lib/widgets/common/image_source_bottom_sheet.dart lib/enums/image_pick_source.dart test/widgets/common/image_source_bottom_sheet_test.dart && flutter analyze lib/widgets/common/image_source_bottom_sheet.dart lib/enums/image_pick_source.dart`
Expected: `No issues found!`

---

### Task 3: 카메라 권한 헬퍼

**Files:**
- Create: `lib/utils/camera_permission_helper.dart`

`permission_handler`의 `Permission.camera`를 사용한다. 갤러리는 image_picker가 시스템 picker로 처리하므로 여기서 다루지 않는다. 거부 안내는 기존 `CommonSnackBar.show(context:, message:, type:)` 시그니처를 그대로 사용한다. 영구거부 시 `openAppSettings()`(permission_handler 전역 함수)로 설정 이동 — `notification_permission_service.dart`의 `openAppSettings()` 사용과 동일.

- [ ] **Step 1: 헬퍼 구현**

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 카메라 권한을 확보한다.
///
/// - 허용되면 true.
/// - 거부되면 안내 스낵바를 띄우고 false.
/// - 영구 거부(다시 묻지 않음)면 안내 스낵바 + 설정 화면 이동 후 false.
///
/// 호출 측은 반환값이 false면 촬영을 진행하지 않는다.
Future<bool> ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;

  if (status.isGranted || status.isLimited) {
    return true;
  }

  if (status.isPermanentlyDenied) {
    if (context.mounted) {
      CommonSnackBar.show(
        context: context,
        message: '카메라 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.',
        type: SnackBarType.info,
      );
    }
    await openAppSettings();
    return false;
  }

  // denied / restricted → 권한 요청
  final result = await Permission.camera.request();
  if (result.isGranted || result.isLimited) {
    return true;
  }

  if (context.mounted) {
    if (result.isPermanentlyDenied) {
      CommonSnackBar.show(
        context: context,
        message: '카메라 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.',
        type: SnackBarType.info,
      );
      await openAppSettings();
    } else {
      CommonSnackBar.show(
        context: context,
        message: '카메라 권한이 필요해요.',
        type: SnackBarType.info,
      );
    }
  }
  return false;
}
```

- [ ] **Step 2: 포맷 + 린트**

Run: `source ~/.zshrc && dart format --line-length=120 lib/utils/camera_permission_helper.dart && flutter analyze lib/utils/camera_permission_helper.dart`
Expected: `No issues found!`

> 단위 테스트는 생략한다 — `Permission.camera`는 플랫폼 채널에 직접 의존해 위젯 테스트에서 모킹 비용이 크고, 권한 분기는 실기기 검증(Task 6)으로 커버한다. 로직은 단순 if-분기라 위험이 낮다.

---

### Task 4: register_input_form 분기 적용

**Files:**
- Modify: `lib/widgets/register_input_form.dart` (`onPickImage`, 현재 99-131 / import 추가)

현재 `onPickImage`는 곧바로 `_picker.pickMultiImage`를 호출한다. 진입부의 `_hasImageBeenTouched`/10장 한도 체크는 유지하고, 그 뒤에 소스 선택 분기를 끼운다. 카메라 더블탭 방지를 위해 진행 가드 `bool _isPickingSource`를 추가한다.

- [ ] **Step 1: import 추가**

`register_input_form.dart` 상단 import 블록(현재 6행 `image_picker` import 부근)에 추가:

```dart
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/utils/camera_permission_helper.dart';
import 'package:romrom_fe/widgets/common/image_source_bottom_sheet.dart';
```

- [ ] **Step 2: 가드 플래그 필드 추가**

`final ImagePicker _picker = ImagePicker();`(현재 88행) 바로 아래에 추가:

```dart
  // 소스 선택 바텀시트~촬영/선택 완료까지 진행 중 가드 (더블탭 방지)
  bool _isPickingSource = false;
```

- [ ] **Step 3: onPickImage 전체 교체**

현재 `onPickImage`(99-131) 전체를 아래로 교체:

```dart
  // 상품사진 추가: 소스(촬영/앨범) 선택 후 처리
  Future<void> onPickImage() async {
    if (_isPickingSource) return; // 중복 진입 방지

    setState(() {
      _hasImageBeenTouched = true;
    });

    final int totalCount = _totalImageCount;
    if (totalCount >= kMaxImages) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지는 최대 10장까지 등록할 수 있습니다.', type: SnackBarType.info);
      }
      return;
    }

    final ImagePickSource? source = await showImageSourceBottomSheet(context);
    if (source == null) return; // 바텀시트 취소

    _isPickingSource = true;
    try {
      switch (source) {
        case ImagePickSource.camera:
          if (!context.mounted) return;
          final bool granted = await ensureCameraPermission(context);
          if (!granted) return;

          final XFile? shot = await _picker.pickImage(source: ImageSource.camera);
          if (shot == null) return; // 촬영 취소

          setState(() {
            _newImageFiles.add(shot);
          });

        case ImagePickSource.gallery:
          final int remain = (kMaxImages - _totalImageCount).clamp(0, kMaxImages);
          final List<XFile> picked = await _picker.pickMultiImage(limit: remain);
          if (picked.isEmpty) return; // 선택 없음/취소

          final List<XFile> toAdd = picked.length > remain ? picked.sublist(0, remain) : picked;
          setState(() {
            _newImageFiles.addAll(toAdd);
          });
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) _isPickingSource = false;
    }
  }
```

- [ ] **Step 4: 린트로 통합 검증**

Run: `source ~/.zshrc && dart format --line-length=120 lib/widgets/register_input_form.dart && flutter analyze lib/widgets/register_input_form.dart`
Expected: `No issues found!` — 미사용 import 없음, switch 망라성(enum 2개 모두 처리) 경고 없음

- [ ] **Step 5: 바텀시트 위젯 테스트 회귀 확인**

Run: `source ~/.zshrc && flutter test test/widgets/common/image_source_bottom_sheet_test.dart`
Expected: PASS — 2 tests passed

---

### Task 5: 플랫폼 권한 설정

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (16행 `WAKE_LOCK` 권한 뒤)
- Modify: `ios/Runner/Info.plist` (`NSPhotoLibraryUsageDescription` 값 뒤, 현재 70-71)

- [ ] **Step 1: Android CAMERA 권한 추가**

`android/app/src/main/AndroidManifest.xml`의 `<uses-permission ... WAKE_LOCK />`(16행) 바로 아래에 추가:

```xml
    <!-- 카메라 촬영 권한 (image_picker 카메라 소스) -->
    <uses-permission android:name="android.permission.CAMERA" />
```

- [ ] **Step 2: iOS NSCameraUsageDescription 추가**

`ios/Runner/Info.plist`의 아래 두 줄(현재 70-71):

```xml
	<key>NSPhotoLibraryUsageDescription</key>
	<string>교환할 물건의 사진을 게시글에 등록하거나 채팅으로 보내기 위해 접근합니다.</string>
```

바로 뒤에 추가:

```xml
	<key>NSCameraUsageDescription</key>
	<string>교환할 물건의 사진을 직접 촬영해 게시글에 등록하기 위해 카메라를 사용합니다.</string>
```

- [ ] **Step 3: 변경 확인**

Run: `git diff android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist`
Expected: 두 파일에 위 추가 라인만 보임. 들여쓰기는 주변(Info.plist는 탭, Manifest는 4-space) 일치.

---

### Task 6: 전체 검증 (실기기 / 통합)

**Files:** 없음 (검증 전용)

- [ ] **Step 1: 전체 analyze**

Run: `source ~/.zshrc && flutter analyze`
Expected: `No issues found!` (기존 무관 경고 외 신규 0)

- [ ] **Step 2: 관련 테스트 실행**

Run: `source ~/.zshrc && flutter test test/widgets/common/image_source_bottom_sheet_test.dart`
Expected: PASS

- [ ] **Step 3: 실기기 수동 검증 체크리스트**

> 내부망 환경 — 빌드/실기기는 사용자가 별도 환경에서 수행. 아래를 사용자에게 체크리스트로 전달한다.

- [ ] 사진 칸 탭 → 바텀시트에 "사진 촬영하기 / 앨범에서 선택하기" 표시
- [ ] "앨범에서 선택하기" → 기존 다중선택 동작 (변동 없음)
- [ ] "사진 촬영하기" 최초 → 카메라 권한 요청 팝업
- [ ] 권한 허용 → 카메라 → 촬영 1장 → 사진 목록에 추가
- [ ] 촬영 중 취소 → 목록 변화 없음
- [ ] 권한 거부 → 안내 스낵바
- [ ] 권한 영구거부 후 촬영 시도 → 안내 스낵바 + 설정 앱 이동
- [ ] 10장 채운 상태에서 탭 → "최대 10장" 스낵바 (바텀시트 안 뜸)
- [ ] iPad에서 바텀시트 항목 레이아웃 정상 (overflow 없음)
- [ ] 바텀시트 빠르게 연속 탭해도 카메라 1회만 진입 (가드 동작)

---

## Self-Review

**1. Spec coverage:**
- 바텀시트 UI → Task 2 ✓
- 촬영 1장 즉시 목록 추가(크롭 없음) → Task 4 camera 분기 ✓
- 갤러리 기존 흐름 유지 → Task 4 gallery 분기 ✓
- 권한 사전 체크 + 거부 스낵바 + 영구거부 설정 이동 → Task 3 ✓
- 상품 등록만 적용 → Task 4 (register_input_form만 수정) ✓
- 공통 위젯 + 헬퍼 분리 → Task 2/3 ✓
- iOS Info.plist / Android Manifest → Task 5 ✓
- 10장 한도/중복요청 방지 → Task 4 (`kMaxImages` 체크 + `_isPickingSource` 가드) ✓
- iPad 고정 픽셀값 → Task 2 (`EdgeInsets` 고정값) ✓

**2. Placeholder scan:** 모든 코드 스텝에 실제 코드 포함. "적절한 에러 처리" 류 없음 — catch 블록 구체 코드 명시. ✓

**3. Type consistency:**
- `ImagePickSource { camera, gallery }` — Task 1 정의, Task 2 반환, Task 4 switch 소비. 일치 ✓
- `showImageSourceBottomSheet(BuildContext) → Future<ImagePickSource?>` — Task 2 정의, Task 4 호출. 일치 ✓
- `ensureCameraPermission(BuildContext) → Future<bool>` — Task 3 정의, Task 4 호출. 일치 ✓
- `CommonSnackBar.show(context:, message:, type:)` — 기존 시그니처(common_snack_bar.dart:99) 일치 ✓
- `_picker.pickImage(source:)`, `_picker.pickMultiImage(limit:)` — image_picker API 일치 ✓
- `AppIcons.camera`, `AppIcons.itmeRegisterImage` — app_icons.dart 존재 확인 ✓
