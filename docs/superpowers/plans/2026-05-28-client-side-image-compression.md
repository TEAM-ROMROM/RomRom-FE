# 클라이언트 측 이미지 압축 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물품 등록·프로필 이미지를 업로드 전 기기에서 WebP(가로 1280, Q80)로 압축하여 백엔드 압축 부하·대기시간을 줄인다.

**Architecture:** 공통 유틸 `ImageCompressor.toWebp(XFile) → Future<XFile>` 하나가 압축 책임을 전담한다(실패 시 원본 반환). 물품 등록은 "선택 즉시 백그라운드 압축" 패턴(`Map<path, Future<XFile>>`)으로 사용자에게 압축을 숨기고, 등록 시 `Future.wait` 로 모은다. 프로필은 단일 이미지라 업로드 직전 1회 await.

**Tech Stack:** Flutter, `flutter_image_compress`(신규), `image_picker`(기존), `path_provider`(임시파일 경로).

---

## 환경 제약 (중요 — 모든 Task 공통)

- **내부망 환경**: `flutter pub get`·`flutter test`·`flutter analyze`·`flutter build` 는 외부 의존성 다운로드가 필요하여 **이 환경에서 실행 불가**. 코드·테스트 코드는 작성하되, 실행/검증은 사용자가 외부 환경에서 수행한다.
- 따라서 각 Task 의 "Run test" 스텝은 **사용자 환경 실행용**으로 명시한다. 에이전트는 명령을 실행하지 말고, 코드 작성 완료 후 `dart format --line-length=120 .` 만 적용한다(포매팅은 외부 연결 불필요).
- **커밋 금지**: 사용자 명시 승인 없이 `git add`/`git commit` 절대 실행 금지(프로젝트 절대 규칙). 각 Task 의 "Commit" 스텝은 **사용자가 직접 실행**하거나 `/cassiiopeia:commit` 으로 처리. 에이전트는 커밋하지 않는다.
- 작업 디렉터리: worktree `D:\0-suh\project\RomRom-FE-Worktree\20260528_887_기능개선_물품등록_프로필_이미지_클라이언트_측_압축`.

---

## File Structure

| 파일 | 책임 | 종류 |
|------|------|------|
| `pubspec.yaml` | `flutter_image_compress` 의존성 선언 | 수정 |
| `lib/utils/image_compressor.dart` | WebP 압축 단일 책임 유틸 (`toWebp`) | 생성 |
| `lib/widgets/register_input_form.dart` | 물품 등록: 선택 즉시 백그라운드 압축, 등록 시 await | 수정 |
| `lib/widgets/profile/profile_overview_section.dart` | 프로필: 크롭 결과 업로드 직전 압축 | 수정 |
| `test/utils/image_compressor_test.dart` | `ImageCompressor` 단위 테스트 | 생성 |

`ImageApi.uploadImages` 및 업로드 API 계약은 변경하지 않는다(멀티파트 key `images`, `POST /api/image/upload`).

---

## Task 1: 패키지 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: `flutter_image_compress` 의존성 추가**

`pubspec.yaml` 의 `dependencies:` 섹션에서 `image_picker` 항목 바로 아래에 추가한다.

```yaml
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
```

> 버전 `^2.3.0` 은 작성 시점 안정 버전. 사용자 환경 pub 캐시에 맞는 버전이 다르면 사용자가 조정한다.

- [ ] **Step 2: (사용자 환경) 의존성 설치**

Run (사용자 외부 환경): `flutter pub get`
Expected: `flutter_image_compress` 해석 성공, `Got dependencies!`

- [ ] **Step 3: Commit (사용자 승인 후)**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "물품 등록·프로필 이미지 클라이언트 측 압축 : chore : flutter_image_compress 의존성 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/887"
```

---

## Task 2: 공통 압축 유틸 `ImageCompressor`

**Files:**
- Create: `lib/utils/image_compressor.dart`
- Test: `test/utils/image_compressor_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/utils/image_compressor_test.dart` 생성. `flutter_image_compress` 는 네이티브 플러그인이라 순수 단위 테스트에서 인코딩이 동작하지 않으므로, **실패 fallback 동작**(존재하지 않는 경로 → 원본 XFile 그대로 반환, throw 안 함)을 검증 대상으로 한다. 이 동작이 안전망의 핵심이다.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/utils/image_compressor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressor.toWebp', () {
    test('존재하지 않는 파일이면 원본 XFile을 그대로 반환하고 throw하지 않는다', () async {
      const sourcePath = '/non/existent/path/fake.jpg';
      final source = XFile(sourcePath);

      final result = await ImageCompressor.toWebp(source);

      expect(result.path, sourcePath);
    });

    test('상수값이 BE와 동일하다 (가로 1280, Q80)', () {
      expect(ImageCompressor.targetWidth, 1280);
      expect(ImageCompressor.quality, 80);
    });
  });
}
```

- [ ] **Step 2: (사용자 환경) 테스트 실패 확인**

Run (사용자 외부 환경): `flutter test test/utils/image_compressor_test.dart`
Expected: FAIL — `image_compressor.dart` 없음 / `ImageCompressor` 미정의로 컴파일 에러.

- [ ] **Step 3: `ImageCompressor` 구현**

`lib/utils/image_compressor.dart` 생성.

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 이미지를 WebP로 압축하는 공통 유틸.
///
/// 산출물은 현 백엔드(ImageCompressionService)와 동일: 가로 1280 축소(비율 유지),
/// WebP Q80. 압축 실패 시 원본 XFile을 그대로 반환한다(백엔드 조건부 압축이 안전망).
class ImageCompressor {
  ImageCompressor._();

  /// 백엔드 scaleToWidth(1280)와 동일한 가로 기준값.
  static const int targetWidth = 1280;

  /// 백엔드 QUALITY=80과 동일.
  static const int quality = 80;

  /// 단일 이미지를 WebP로 압축. 실패하면 원본 [source]를 그대로 반환(throw 안 함).
  static Future<XFile> toWebp(XFile source) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'cmp_${DateTime.now().microsecondsSinceEpoch}.webp';
      final targetPath = '${dir.path}/$fileName';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        format: CompressFormat.webp,
        quality: quality,
        // 긴 변 기준 비율 유지 축소. 가로/세로 모두 targetWidth 이하로 맞춰지며
        // 원본이 더 작으면 확대하지 않는다(비율 보존).
        minWidth: targetWidth,
        minHeight: targetWidth,
      );

      if (result == null) {
        debugPrint('ImageCompressor: 압축 결과 null, 원본 사용 (${source.path})');
        return source;
      }
      return XFile(result.path);
    } catch (e) {
      debugPrint('ImageCompressor: 압축 실패, 원본 사용 ($e)');
      return source;
    }
  }
}
```

> `path_provider` 는 RomRom-FE 에 이미 포함되어 있다(크롭 화면 등에서 사용 중). 미포함 시 Task 1 에 `path_provider` 추가.

- [ ] **Step 4: (사용자 환경) 테스트 통과 확인**

Run (사용자 외부 환경): `flutter test test/utils/image_compressor_test.dart`
Expected: PASS (2 tests). 존재하지 않는 경로 → catch → 원본 반환.

- [ ] **Step 5: 포매팅**

Run: `dart format --line-length=120 lib/utils/image_compressor.dart test/utils/image_compressor_test.dart`

- [ ] **Step 6: Commit (사용자 승인 후)**

```bash
git add lib/utils/image_compressor.dart test/utils/image_compressor_test.dart
git commit -m "물품 등록·프로필 이미지 클라이언트 측 압축 : feat : WebP 압축 공통 유틸 ImageCompressor 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/887"
```

---

## Task 3: 물품 등록 — 선택 즉시 백그라운드 압축

**Files:**
- Modify: `lib/widgets/register_input_form.dart`
  - 상태 필드 추가: line 94 인근(`_newImageFiles` 선언 아래)
  - 압축 시작: `onPickImage` 카메라(line 135) / 갤러리(line 146)
  - 압축 결과 정리: `onDeleteImage`(line 172), `_initControllers` clear(line 232)
  - 등록 시 await: 제출 핸들러(line 833~838)

`ImageCompressor` 가 이미 단위 테스트로 검증되었으므로, 이 Task 는 호출부 배선 변경이다. 위젯 통합 테스트는 내부망에서 image_picker 네이티브 호출 모킹이 어려워 수동 QA 로 검증한다(테스트케이스는 Phase 5 에서 작성).

- [ ] **Step 1: import 추가**

`register_input_form.dart` 상단 import 블록에 추가(기존 import 정렬에 맞춰 알파벳 순 위치).

```dart
import 'package:romrom_fe/utils/image_compressor.dart';
```

- [ ] **Step 2: 백그라운드 압축 상태 필드 추가**

line 94 `final List<XFile> _newImageFiles = [];` 바로 아래에 추가.

```dart
  final List<XFile> _newImageFiles = []; // 새로 선택된 로컬 이미지 파일 (아직 업로드 안 됨)
  // 선택 즉시 시작한 백그라운드 압축 Future. key=원본 XFile.path, value=압축된 XFile.
  // 등록 시 await로 수거. 삭제되면 맵에서 빠져 결과가 버려진다(취소 API 없음).
  final Map<String, Future<XFile>> _compressing = {};
```

- [ ] **Step 3: 카메라 선택 시 백그라운드 압축 시작**

`onPickImage` 카메라 케이스(line 133-136):

```dart
          if (!mounted) return;
          setState(() {
            _newImageFiles.add(shot);
          });
```

를 아래로 교체.

```dart
          if (!mounted) return;
          setState(() {
            _newImageFiles.add(shot);
          });
          _compressing[shot.path] = ImageCompressor.toWebp(shot);
```

- [ ] **Step 4: 갤러리 선택 시 백그라운드 압축 시작**

`onPickImage` 갤러리 케이스(line 144-147):

```dart
          if (!mounted) return;
          setState(() {
            _newImageFiles.addAll(toAdd);
          });
```

를 아래로 교체.

```dart
          if (!mounted) return;
          setState(() {
            _newImageFiles.addAll(toAdd);
          });
          for (final x in toAdd) {
            _compressing[x.path] = ImageCompressor.toWebp(x);
          }
```

- [ ] **Step 5: 삭제 시 압축 결과 버리기**

`onDeleteImage` 의 로컬 이미지 삭제 분기(line 170-173):

```dart
      } else {
        // 새로 추가된 로컬 이미지 삭제
        _newImageFiles.removeAt(index - existingCount);
      }
```

를 아래로 교체(삭제 대상의 path 를 먼저 구해 맵에서 제거).

```dart
      } else {
        // 새로 추가된 로컬 이미지 삭제
        final removed = _newImageFiles.removeAt(index - existingCount);
        _compressing.remove(removed.path); // 진행 중 압축 결과 버림
      }
```

- [ ] **Step 6: 수정 모드 초기화 시 맵도 clear**

`_initControllers` 의 line 232:

```dart
      _newImageFiles.clear();
```

를 아래로 교체.

```dart
      _newImageFiles.clear();
      _compressing.clear();
```

- [ ] **Step 7: 등록/수정 제출 시 압축본 수거 후 업로드**

제출 핸들러(line 831-838):

```dart
                        // 새 로컬 이미지가 있으면 서버에 업로드
                        List<String> newImageUrls = [];
                        if (_newImageFiles.isNotEmpty) {
                          newImageUrls = await ImageApi().uploadImages(_newImageFiles);
                          if (newImageUrls.length != _newImageFiles.length) {
                            throw Exception('일부 이미지 업로드에 실패했습니다 (${newImageUrls.length}/${_newImageFiles.length})');
                          }
                        }
```

를 아래로 교체. `_newImageFiles` 순회로 압축 Future 를 매핑하여 **순서를 보존**한다. 이미 끝난 Future 는 즉시 반환(추가 대기 0), 진행 중이면 남은 만큼만 대기. 맵에 없으면(엣지) 그 자리에서 압축.

```dart
                        // 새 로컬 이미지가 있으면 압축본을 수거해 서버에 업로드
                        List<String> newImageUrls = [];
                        if (_newImageFiles.isNotEmpty) {
                          // 선택 시 시작한 백그라운드 압축을 순서 보존하여 수거.
                          // 보통 이미 완료되어 대기 0, 미완료분만 짧게 대기.
                          final List<XFile> compressed = await Future.wait(
                            _newImageFiles.map(
                              (x) => _compressing[x.path] ?? ImageCompressor.toWebp(x),
                            ),
                          );
                          newImageUrls = await ImageApi().uploadImages(compressed);
                          if (newImageUrls.length != compressed.length) {
                            throw Exception('일부 이미지 업로드에 실패했습니다 (${newImageUrls.length}/${compressed.length})');
                          }
                        }
```

- [ ] **Step 8: (사용자 환경) 분석·수동 QA**

Run (사용자 외부 환경): `flutter analyze`
Expected: No issues (또는 기존 대비 신규 경고 0).
수동 QA: 다중 이미지 선택 → 즉시 등록(압축 미완료) → 정상 등록, URL 개수=이미지 개수, 순서 유지. 압축 중 1장 삭제 → 그 장 제외 등록.

- [ ] **Step 9: 포매팅**

Run: `dart format --line-length=120 lib/widgets/register_input_form.dart`

- [ ] **Step 10: Commit (사용자 승인 후)**

```bash
git add lib/widgets/register_input_form.dart
git commit -m "물품 등록·프로필 이미지 클라이언트 측 압축 : feat : 물품 등록 시 선택 즉시 백그라운드 WebP 압축 후 업로드 https://github.com/TEAM-ROMROM/RomRom-FE/issues/887"
```

---

## Task 4: 프로필 이미지 — 업로드 직전 압축

**Files:**
- Modify: `lib/widgets/profile/profile_overview_section.dart`
  - import 추가
  - 업로드 직전 압축: line 111

프로필은 단일 이미지이고 크롭 화면 이후 한 번만 업로드하므로 백그라운드 패턴이 불필요하다. 크롭 산출 PNG 를 업로드 직전에 `ImageCompressor.toWebp` 1회 통과시킨다. 500x500 이라 리사이즈는 사실상 미적용(1280 미만), WebP Q80 변환만 적용되어 무손실 PNG 대비 용량 감소.

- [ ] **Step 1: import 추가**

`profile_overview_section.dart` 상단 import 블록에 추가.

```dart
import 'package:romrom_fe/utils/image_compressor.dart';
```

- [ ] **Step 2: 업로드 직전 압축 적용**

line 110-111:

```dart
      try {
        final List<String> urls = await ImageApi().uploadImages([croppedFile]);
```

를 아래로 교체.

```dart
      try {
        final XFile compressed = await ImageCompressor.toWebp(croppedFile);
        final List<String> urls = await ImageApi().uploadImages([compressed]);
```

> `croppedFile` 은 이미 `XFile?` 의 non-null 분기(line 99-102 가드 통과 후) 이므로 `XFile` 로 사용 가능.

- [ ] **Step 3: (사용자 환경) 분석·수동 QA**

Run (사용자 외부 환경): `flutter analyze`
Expected: No issues.
수동 QA: 프로필 이미지 변경 → 크롭 → 저장 → 업로드 성공, 프로필 이미지 정상 표시.

- [ ] **Step 4: 포매팅**

Run: `dart format --line-length=120 lib/widgets/profile/profile_overview_section.dart`

- [ ] **Step 5: Commit (사용자 승인 후)**

```bash
git add lib/widgets/profile/profile_overview_section.dart
git commit -m "물품 등록·프로필 이미지 클라이언트 측 압축 : feat : 프로필 이미지 업로드 직전 WebP 압축 적용 https://github.com/TEAM-ROMROM/RomRom-FE/issues/887"
```

---

## Self-Review

**Spec coverage:**
- 패키지 추가 → Task 1 ✓
- 공통 유틸 `ImageCompressor.toWebp`(WebP/1280/Q80, 실패 시 원본) → Task 2 ✓
- 물품 선택 즉시 백그라운드 압축(`Map<path,Future>`) / 등록 시 `Future.wait` / 삭제 시 결과 버림 / 순서 보존 → Task 3 ✓
- 프로필 크롭 PNG → 업로드 직전 WebP → Task 4 ✓
- 실패 fallback(원본 전송) → Task 2 구현 + Task 2 테스트로 검증 ✓
- 비율 보존 → `minWidth/minHeight` 비율 유지 축소(Task 2 주석 명시) ✓
- BE 조건부 압축 → 본 plan 범위 밖(별도 이슈), spec 에 명시 ✓

**Placeholder scan:** "TBD"/"적절히 처리"/"비슷하게" 등 없음. 모든 코드 스텝에 실제 코드 포함. ✓

**Type consistency:** `ImageCompressor.toWebp(XFile) → Future<XFile>`, `targetWidth`/`quality` 상수, `_compressing: Map<String, Future<XFile>>` — Task 2~4 전체에서 동일 시그니처·이름 사용. ✓

**환경 제약 반영:** 모든 test/analyze 스텝에 "(사용자 외부 환경)" 명시, 에이전트 커밋 금지 명시. ✓
