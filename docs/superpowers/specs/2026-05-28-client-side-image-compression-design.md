# 클라이언트 측 이미지 압축 설계

- 날짜: 2026-05-28
- 대상 레포: RomRom-FE (이번 구현). RomRom-BE 는 별도 이슈만 생성.
- 관련 배경: 물품 등록/프로필 이미지 업로드 시 BE 가 모든 이미지를 동기 순차로 WebP 압축(`ImageCompressionService`, scrimage-webp→네이티브 cwebp). 이미지 N장이 직렬 처리되어 업로드 응답이 느림.

## 목표

이미지 압축을 **기기(클라이언트)** 에서 수행하여 BE 압축 부하·대기시간을 줄인다.

- FE 가 업로드 전에 WebP 로 압축(현 BE 와 동일한 산출물: 가로 1280 축소, Q80).
- 사용자에게 압축 과정을 **숨긴다**: 이미지 선택 즉시 백그라운드 압축을 시작하고, 미리보기는 원본으로 즉시 표시. 사용자가 폼을 채우는 동안 압축이 끝나므로 등록 시점엔 보통 이미 완료되어 추가 대기가 없다.
- 압축 결과물·파라미터를 **공통 유틸 함수**로 추출하여 물품 등록과 프로필 이미지에 함께 사용.

## 비목표 (이번 범위 밖)

- BE 압축 로직 변경 — 별도 이슈로 트래킹(동일 PAT, `/cassiiopeia:github`). 이번 PR 은 FE 만.
- 업로드 API 계약(`POST /api/image/upload`, multipart key `images`) 변경 없음.
- 이미지 크롭 UX 변경 없음(프로필 크롭 화면 동작 유지).

## 압축 스펙

| 항목 | 값 | 근거 |
|------|----|----|
| 출력 포맷 | WebP | 현 BE 산출물과 동일. BE 조건부 압축이 "이미 WebP면 스킵" 판단 쉬움 |
| 리사이즈 | 가로 1280 기준 축소(비율 유지, 긴 변 기준) | 현 BE `scaleToWidth(1280)` 와 동일. 1280 이하 원본은 리사이즈 생략 |
| 품질 | Q80 | 현 BE `QUALITY=80` 과 동일 |
| 비율 | **원본 그대로** | 리사이즈는 비율 유지 축소만, Q80 은 화질만 조정 → 왜곡 없음 |
| 예상 용량 | 원본의 5~15% (4MB 사진 → 약 250KB) | 1280 다운스케일(~1/9 픽셀) + WebP(JPEG 대비 -30%) |

리사이즈 매핑: `flutter_image_compress` 는 가로/세로를 직접 지정하지 않고 `minWidth`/`minHeight` 로 "긴 변이 이 값 이상이면 그 비율로 축소"한다. 가로 1280 동작을 재현하려면 `minWidth: 1280, minHeight: 1280` 으로 두고 비율 유지에 맡긴다(세로가 더 긴 사진도 긴 변이 1280 으로 맞춰짐 — BE 의 "가로만 1280" 과 미세하게 다를 수 있으나, 둘 다 비율 유지 축소이고 용량 목표는 동일하므로 허용). 정확히 가로 기준만 제한해야 하면 `minHeight` 를 매우 크게(예: 100000) 두어 가로만 제약하는 방식으로 조정한다.

## 패키지

- `flutter_image_compress` 추가(pubspec.yaml).
- iOS/Android 모두 네이티브 스레드에서 WebP 인코딩 → UI 멈춤 없음. 별도 `Isolate` 불필요.
- **내부망 제약**: `flutter pub get` 은 사용자가 외부 환경에서 직접 수행. 구현 중 패키지 미설치로 analyze 실패할 수 있음 — 코드 작성은 진행하되 빌드/analyze 는 사용자 환경에서 검증.

## 컴포넌트

### 1) 공통 유틸 — `ImageCompressor`

위치: `lib/utils/image_compressor.dart` (신규)

```
class ImageCompressor {
  static const int targetWidth = 1280;
  static const int quality = 80;

  /// 단일 이미지를 WebP로 압축. 실패 시 원본 XFile 그대로 반환(throw 안 함).
  static Future<XFile> toWebp(XFile source) async { ... }
}
```

- 입력 `XFile` → `flutter_image_compress` 로 WebP 압축 → 임시 디렉터리에 산출(`getTemporaryDirectory`) → 압축본 경로의 새 `XFile` 반환.
- **실패 fallback**: 압축이 예외를 던지거나 결과가 null 이면 **원본 `XFile` 을 그대로 반환**(로그만 남김). BE 조건부 압축이 안전망이므로 원본이 가도 BE 가 압축한다. 업로드 실패 0, 사용자 끊김 없음.
- 한 가지 책임만 가짐: "XFile 하나 → 압축된 XFile 하나". 호출부가 단일/다중·동기/백그라운드를 결정.

### 2) 물품 등록 적용 — `register_input_form.dart`

선택 즉시 백그라운드 압축, 등록 시 await 패턴.

상태:
```
final List<XFile> _newImageFiles = [];                 // 기존: 원본(미리보기용)
final Map<String, Future<XFile>> _compressing = {};    // 신규: key=XFile.path, value=압축 Future
```

- **선택 시점**(`onPickImage`, line 135/146): `_newImageFiles.add(x)` 직후 `_compressing[x.path] = ImageCompressor.toWebp(x)` 로 백그라운드 압축 시작(await 하지 않음). 미리보기는 기존대로 `_newImageFiles` 의 원본 경로 사용 → 0 지연.
- **삭제 시점**(`onDeleteImage`, line 159~): `_newImageFiles.removeAt` 과 함께 `_compressing.remove(path)`. 진행 중인 Future 는 취소 API 가 없으므로 **결과를 버리는 방식**(맵에서 빠지면 등록 시 참조 안 됨).
- **등록/수정 제출**(line 833 직전): 업로드 전에 압축본 모음.
  ```
  if (_newImageFiles.isNotEmpty) {
    final compressed = await Future.wait(
      _newImageFiles.map((x) => _compressing[x.path] ?? ImageCompressor.toWebp(x)),
    );
    newImageUrls = await ImageApi().uploadImages(compressed);
  }
  ```
  - 이미 끝난 Future → 즉시 반환(추가 대기 0). 진행 중 → 남은 만큼만 대기. 맵에 없으면(엣지) 그 자리에서 압축.
  - 순서 보존: `_newImageFiles` 순회로 Future 매핑하므로 업로드 URL 순서 = 표시 순서 유지.
  - 기존 로딩(`_isLoading` 스피너, line 827)이 이미 떠 있어 짧은 대기를 자연 흡수. 새 로딩 UI 불필요.
- **clear 시점**(line 232): `_compressing.clear()` 동반.

### 3) 프로필 이미지 적용 — `profile_overview_section.dart` / `profile_image_crop_screen.dart`

- 현 흐름: 갤러리 선택 → 크롭 화면에서 500x500 **PNG**(무손실) → `ImageApi().uploadImages([croppedFile])`.
- 변경: 크롭 산출 PNG(`XFile`)를 업로드 직전에 `ImageCompressor.toWebp` 통과.
  - 500x500 이므로 리사이즈는 사실상 미적용(1280 미만) → WebP Q80 변환만 적용. PNG 무손실(수백 KB~1MB+) → WebP 약 30~80KB 로 감소.
  - 단일 이미지라 백그라운드 패턴 불필요. 업로드 직전 1회 await 로 충분.
- 적용 지점: `profile_overview_section.dart:111` `uploadImages([croppedFile])` 직전에 `final c = await ImageCompressor.toWebp(croppedFile);` → `uploadImages([c])`.

## 데이터 흐름 (물품)

```
[갤러리/카메라 선택]
   → _newImageFiles.add(원본)          (미리보기 = 원본, 즉시)
   → _compressing[path] = toWebp(원본)  (백그라운드 시작, await 안 함)
[사용자가 제목·설명·가격 입력]            (이 사이에 압축 완료됨)
[등록 버튼]
   → _isLoading = true (기존 스피너)
   → await Future.wait(압축 Future들)    (보통 이미 완료 → 대기 0)
   → uploadImages(압축본 List)           (key 'images', /api/image/upload)
   → 반환 URL → itemImageUrls → postItem/updateItem
```

## 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| 압축 실패(권한/메모리/손상) | `toWebp` 가 원본 XFile 반환. 원본 업로드 → BE 가 압축. 사용자 영향 없음 |
| 압축 중 이미지 삭제 | `_compressing.remove(path)`. Future 결과 버림(취소 API 없음) |
| 등록 시 압축 미완료 | `Future.wait` 가 남은 분만 대기. 기존 로딩 스피너로 흡수 |
| 맵에 Future 없음(예외 상황) | 제출 시점에 `?? toWebp(x)` 로 즉석 압축 |
| 원본이 이미 1280 이하 | 리사이즈 생략, WebP 변환만(여전히 용량 감소) |
| 화면 dispose 중 압축 콜백 | `mounted` 가드 — `_newImageFiles`/`_compressing` 는 setState 없이 갱신, await 후 `mounted` 확인 |

## 테스트 관점

- `ImageCompressor.toWebp`: 정상 이미지 → 더 작은 WebP XFile, 비율 보존(가로:세로 비 동일), 1280 초과 시 가로 ≤ 1280.
- 실패 입력(손상 파일/없는 경로) → 원본 XFile 그대로 반환, throw 안 함.
- 물품 등록: 다중 선택 후 즉시 등록(압축 미완료) → 정상 완료, URL 개수 = 이미지 개수, 순서 보존.
- 압축 중 1장 삭제 → 등록 시 그 이미지 제외, 나머지 정상.
- 프로필: 크롭 PNG → WebP 업로드, 프로필 URL 갱신 정상.
- (내부망) analyze/빌드/실기기 테스트는 사용자 환경에서 수행.

## BE 후속 이슈 (이번 PR 아님)

별도 이슈로 등록(동일 PAT):
- 조건부 압축 가드: 입력이 이미 WebP 거나 충분히 작으면 cwebp 스킵, 큰 경우만 압축.
- `StorageService` for 루프 병렬화(`@Async`/`CompletableFuture` 또는 `parallelStream`) 검토 — 안전망 압축 경로의 지연 완화.
- 목적: FE 압축본은 빠르게 통과시키고, 구버전 앱/원본 fallback 만 BE 가 압축하는 하이브리드.
