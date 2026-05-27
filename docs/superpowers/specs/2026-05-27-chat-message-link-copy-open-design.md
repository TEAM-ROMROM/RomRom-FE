# 채팅 메시지 링크 복사 및 열기 (#873)

- **이슈**: https://github.com/TEAM-ROMROM/RomRom-FE/issues/873
- **작성일**: 2026-05-27
- **브랜치**: `20260527_#873_채팅_메시지_링크_복사_및_열기_불가`

## 문제

채팅 텍스트 메시지가 일반 `Text` 위젯으로만 렌더링된다 (`lib/widgets/chat_message_item.dart:273`, `_buildBubble`).

- `SelectableText`가 아니라 길게 눌러 텍스트 선택/복사 불가
- URL 자동 링크화 + 탭 핸들러가 없어 메시지 내 링크를 눌러도 브라우저가 열리지 않음
- iOS/Android 공통

## 예상 동작

- 채팅 메시지 텍스트를 길게 눌러 **부분 선택 복사** 가능 (OS 네이티브 선택 메뉴)
- 메시지 내 URL이 자동 링크화되어, 탭하면 **외부 브라우저**로 열림

## 결정 사항

### 링크화 방식: `flutter_linkify` 패키지

- `SelectableLinkify` 위젯 하나로 **부분 선택 복사 + URL 자동 링크화 + 탭 핸들러**를 모두 처리한다.
- `url_launcher`는 이미 의존성에 존재 (`pubspec.yaml:53`). 추가로 `flutter_linkify`만 도입.
- **내부망 제약**: 이 PC는 폐쇄망이라 `flutter pub get`이 불가하다. 코드(pubspec 추가 + 위젯 교체 + dart format)만 작성하고, 패키지 설치/빌드/분석은 사용자가 외부망 환경에서 직접 수행한다.

### 복사 방식: `SelectableLinkify` 부분 선택

- `long-press → 메시지 전체 복사` 방식이 아니라, OS 네이티브 텍스트 선택 핸들을 노출해 사용자가 원하는 범위만 드래그 선택 후 복사한다.

### `maxHeight: 264.h` 제거 (양쪽 버블 통일)

- 현재 내 메시지 버블에만 `maxHeight: 264.h`가 붙어 있고 상대 메시지 버블에는 없다 (`constraints: BoxConstraints(maxWidth: 264.w, maxHeight: isMine ? 264.h : double.infinity)`).
- **근거 추적 결과**: 위젯 분리 리팩토링 커밋(`5533bf2`) 이전 원본(`chat_room_screen.dart`)에서도 처음부터 내 메시지 버블에만 `maxHeight: 264.h`가 있었고 상대 버블에는 없었다. 리팩토링은 이 비대칭을 `isMine ? 264.h : double.infinity`로 그대로 옮긴 것일 뿐, 새로 생긴 의도가 아니다.
- 명확한 디자인 의도가 없고 **비대칭 + 텍스트 잘림(스크롤 없음) 부작용**만 존재한다. `maxHeight`를 제거해 양쪽 버블 동작을 통일한다 (`maxWidth: 264.w`만 유지). 긴 텍스트/긴 URL은 세로로 늘어난다 (카카오톡 동일 동작).
- CLAUDE.md의 "고정 height 컨테이너 지양" 가이드와도 일치.

## 변경 범위

### 1. `pubspec.yaml`

`url_launcher: ^6.3.2` 인근에 의존성 추가:

```yaml
  flutter_linkify: ^6.0.0
```

> `flutter_linkify`가 `linkify`를 transitive dependency로 끌어오므로 `linkify`를 직접 명시할 필요는 없다. `Linkify` 패턴(`onOpen`의 `link.url`)만 사용한다.

### 2. `lib/widgets/chat_message_item.dart`

#### `_buildBubble` 텍스트 버블 교체

`Container`의 `constraints`에서 `maxHeight` 제거:

```dart
constraints: BoxConstraints(maxWidth: 264.w),
```

`child`의 `Text` → `SelectableLinkify`:

```dart
child: SelectableLinkify(
  text: message.content ?? '',
  options: const LinkifyOptions(humanize: false), // URL 원본 그대로 표시
  style: CustomTextStyles.p2.copyWith(
    color: isMine ? AppColors.textColorBlack : AppColors.textColorWhite,
    fontWeight: FontWeight.w400,
    height: 1.2,
  ),
  linkStyle: CustomTextStyles.p2.copyWith(
    // 링크 전용 색이 디자인 시스템에 없어 본문 글자색을 유지하고 밑줄로만 링크를 구분한다.
    color: isMine ? AppColors.textColorBlack : AppColors.textColorWhite,
    fontWeight: FontWeight.w400,
    height: 1.2,
    decoration: TextDecoration.underline,
  ),
  onOpen: (link) => _openUrl(context, link.url),
),
```

- **링크 색**: 디자인 시스템에 링크 전용 색(파랑 등)이 없다. 내 버블(노랑 배경)엔 노랑 링크가 묻히고, 임의의 파랑을 직접 박으면 `AppColors` 규칙(직접 Color 금지)에 어긋난다. 그래서 **양쪽 버블 모두 본문 글자색을 유지하고 `underline`으로만 링크를 구분**한다 (내 버블=검정 밑줄, 상대 버블=흰 밑줄). 디자이너가 추후 링크 색을 정하면 `linkStyle.color`만 교체하면 된다.

#### URL 열기 헬퍼 추가

`chat_location_bubble.dart:101-103` 패턴을 따른다:

```dart
Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      CommonSnackBar.show(context: context, message: '링크를 열 수 없습니다.', type: SnackBarType.error);
    }
  } catch (_) {
    if (context.mounted) {
      CommonSnackBar.show(context: context, message: '링크를 열 수 없습니다.', type: SnackBarType.error);
    }
  }
}
```

#### import 추가

```dart
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
```

> `ChatMessageItem`은 `StatelessWidget`이고 `build`에 `context`가 있으므로 `_openUrl(context, ...)`로 전달한다. `_buildBubble`은 이미 `context`를 받는다.

## 영향 범위

- 텍스트 메시지 버블만 변경. system/trade/image/location 메시지 분기는 건드리지 않음.
- `maxHeight` 제거는 내 메시지 텍스트 버블에만 영향 (상대 버블은 원래 무제한).

## 검증 (사용자 외부망 환경)

- `flutter pub get` 후 빌드
- 채팅방에서 링크 포함 메시지 수신/송신
  - 길게 눌러 부분 선택 → 복사 동작 확인
  - URL 탭 → 외부 브라우저 열림 확인
  - 잘못된 URL/열기 실패 시 스낵바 노출 확인
- 긴 텍스트 메시지가 잘리지 않고 세로로 늘어나는지 확인 (내/상대 양쪽)
- iPad에서 버블 레이아웃 정상 확인

## YAGNI (이번 범위 제외)

- 인앱 브라우저(webview) — 외부 브라우저로 충분
- 이메일/전화번호 linkify — 이슈는 URL만 요구
- long-press 커스텀 컨텍스트 메뉴 — SelectableLinkify 네이티브 메뉴로 충분
