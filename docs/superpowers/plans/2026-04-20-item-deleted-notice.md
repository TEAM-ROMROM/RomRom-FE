# 게시글 삭제 제재 알림 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 관리자가 게시글을 삭제 제재했을 때 API 응답에서 `ITEM_DELETED_NOTICE` 에러코드를 글로벌 인터셉터로 감지해 삭제 안내 화면을 표시한다.

**Architecture:** `api_client.dart`의 기존 `_handleSuspendedResponse` 패턴을 그대로 따라 `_handleItemDeletedResponse` 핸들러를 추가한다. 계정 제재와 달리 토큰은 유지하고 스택을 보존한 채 화면을 push한다. 화면은 `AccountSuspendedScreen` 구조를 재활용해 `ItemDeletedScreen`으로 신규 작성한다.

**Tech Stack:** Flutter, Dart, flutter_screenutil, url_launcher

---

## 파일 맵

| 작업 | 경로 |
|------|------|
| 신규 생성 | `lib/exceptions/item_deleted_exception.dart` |
| 신규 생성 | `lib/screens/item_deleted_screen.dart` |
| 수정 | `lib/enums/error_code.dart` |
| 수정 | `lib/services/api_client.dart` |

---

### Task 1: ItemDeletedException 예외 클래스 생성

**Files:**
- Create: `lib/exceptions/item_deleted_exception.dart`

- [ ] **Step 1: 파일 생성**

`lib/exceptions/item_deleted_exception.dart`를 생성한다:

```dart
/// 게시글 삭제 제재 알림 예외
/// api_client.dart에서 ITEM_DELETED_NOTICE 에러코드 감지 시 발생
class ItemDeletedException implements Exception {
  final String itemTitle;
  final String deleteReason;

  ItemDeletedException({required this.itemTitle, required this.deleteReason});

  @override
  String toString() => 'ItemDeletedException: title=$itemTitle, reason=$deleteReason';
}
```

- [ ] **Step 2: error_code.dart에 에러코드 추가**

`lib/enums/error_code.dart`의 `// NOTIFICATION` 섹션 바로 위에 아래 항목을 추가한다:

```dart
  // ITEM DELETED NOTICE
  itemDeletedNotice(code: 'ITEM_DELETED_NOTICE', koMessage: '게시글이 삭제되었습니다.'),
```

- [ ] **Step 3: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/exceptions/item_deleted_exception.dart lib/enums/error_code.dart
```

---

### Task 2: ItemDeletedScreen UI 구현

**Files:**
- Create: `lib/screens/item_deleted_screen.dart`

- [ ] **Step 1: 파일 생성**

`lib/screens/item_deleted_screen.dart`를 생성한다. `AccountSuspendedScreen` 구조를 그대로 따르되 제목·정보박스·닫기 동작이 다르다:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 게시글 삭제 제재 안내 화면
/// 관리자가 게시글을 삭제했을 때 표시되는 알림 화면
class ItemDeletedScreen extends StatefulWidget {
  final String itemTitle;
  final String deleteReason;

  const ItemDeletedScreen({super.key, required this.itemTitle, required this.deleteReason});

  @override
  State<ItemDeletedScreen> createState() => _ItemDeletedScreenState();
}

class _ItemDeletedScreenState extends State<ItemDeletedScreen> {
  /// X 버튼: 화면 닫기 + 플래그 리셋 (계정 제재와 달리 로그아웃 없음)
  void _handleClose() {
    ApiClient.resetItemDeletedFlag();
    Navigator.of(context).pop();
  }

  /// 문의하기 mailto 링크 실행
  Future<void> _launchContactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'romrom.noreply@gmail.com',
      queryParameters: {'subject': '[롬롬 게시글 삭제 문의] 게시글: ${widget.itemTitle}'},
    );

    final launched = await canLaunchUrl(uri);
    if (launched) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        CommonSnackBar.show(
          context: context,
          message: '메일 앱이 없습니다. romrom.noreply@gmail.com 으로 문의해 주세요.',
          type: SnackBarType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // X 닫기 버튼 (44x44 터치 영역)
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 16.h),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleClose,
                child: SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: Center(
                    child: Icon(AppIcons.cancel, size: 24.sp, color: AppColors.textColorWhite),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 제목
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: RichText(
                text: TextSpan(
                  style: CustomTextStyles.h1.copyWith(height: 1.2),
                  children: [
                    TextSpan(text: '게시글이 커뮤니티 가이드라인\n위반으로 '.noBreak),
                    TextSpan(
                      text: '삭제'.noBreak,
                      style: CustomTextStyles.h1.copyWith(height: 1.2, color: AppColors.warningRed),
                    ),
                    TextSpan(text: '되었습니다'.noBreak),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 정보 박스
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlack1,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('콘텐츠 정보', widget.itemTitle),
                    SizedBox(height: 8.h),
                    _buildInfoRow('삭제 사유', widget.deleteReason),
                    SizedBox(height: 16.h),
                    Text(
                      '* 반복적인 가이드라인 위반 시 서비스 이용이 제한될 수 있습니다.'.noBreak,
                      style: CustomTextStyles.p3.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: AppColors.opacity60White,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 문의하기 버튼
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Material(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: _launchContactEmail,
                    borderRadius: BorderRadius.circular(10.r),
                    child: Center(
                      child: Text(
                        '문의하기',
                        style: CustomTextStyles.p1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorBlack,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯 (• 라벨 : 값)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 7.h),
          child: Container(
            width: 4.w,
            height: 4.w,
            decoration: const BoxDecoration(color: AppColors.textColorWhite, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: 8.w),
        Text('$label : '.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        Expanded(
          child: Text(value.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_deleted_screen.dart
```

---

### Task 3: api_client.dart 글로벌 인터셉터 추가

**Files:**
- Modify: `lib/services/api_client.dart`

- [ ] **Step 1: import 추가**

`lib/services/api_client.dart` 상단 import 블록에 아래 두 줄을 추가한다 (기존 import 순서 유지):

```dart
import 'package:romrom_fe/exceptions/item_deleted_exception.dart';
import 'package:romrom_fe/screens/item_deleted_screen.dart';
```

- [ ] **Step 2: 플래그 및 리셋 메서드 추가**

`_isSessionExpiredHandling` 필드 선언 바로 아래(32번째 줄 근처)에 추가:

```dart
  /// 게시글 삭제 알림 중복 처리 방지 플래그
  static bool _isItemDeletedHandling = false;

  /// 게시글 삭제 플래그 리셋 (화면 닫을 때 ItemDeletedScreen에서 호출)
  static void resetItemDeletedFlag() {
    _isItemDeletedHandling = false;
  }
```

- [ ] **Step 3: _handleItemDeletedResponse 핸들러 추가**

`_handleUgcViolationResponse` 메서드(86번째 줄) 바로 아래에 추가:

```dart
  /// ITEM_DELETED_NOTICE 응답 글로벌 처리
  /// 반환값: ItemDeletedException(감지됨) 또는 null(해당 없음)
  static ItemDeletedException? _handleItemDeletedResponse(http.Response response) {
    if (_isItemDeletedHandling) return null;
    if (response.body.isEmpty) return null;
    try {
      final data = jsonDecode(response.body);
      if (data['errorCode'] == 'ITEM_DELETED_NOTICE') {
        _isItemDeletedHandling = true;
        final itemTitle = data['itemTitle'] as String? ?? '';
        final deleteReason = data['deleteReason'] as String? ?? '';
        debugPrint('게시글 삭제 알림 감지 (ITEM_DELETED_NOTICE)');

        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDeletedScreen(itemTitle: itemTitle, deleteReason: deleteReason),
            ),
          );
        }
        return ItemDeletedException(itemTitle: itemTitle, deleteReason: deleteReason);
      }
    } catch (e) {
      debugPrint('ITEM_DELETED_NOTICE 응답 파싱 실패: $e');
    }
    return null;
  }
```

- [ ] **Step 4: sendMultipartRequest에 핸들러 호출 추가**

`sendMultipartRequest` 내부의 UGC 체크 직후(143번째 줄 근처)에 추가:

```dart
      // 게시글 삭제 알림 체크 (ITEM_DELETED_NOTICE)
      _handleItemDeletedResponse(response);
```

- [ ] **Step 5: sendRequest(HTTP)에 핸들러 호출 추가**

`sendMultipartRequest`와 동일하게 `sendRequest` 내부의 UGC 체크 직후(238번째 줄 근처)에 추가:

```dart
      // 게시글 삭제 알림 체크 (ITEM_DELETED_NOTICE)
      _handleItemDeletedResponse(response);
```

- [ ] **Step 6: reissue 토큰 갱신 경로에도 핸들러 호출 추가**

414번째 줄 근처 `_handleSuspendedResponse` 호출 직후에 추가:

```dart
      _handleItemDeletedResponse(response);
```

- [ ] **Step 7: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/services/api_client.dart
```

---

### Task 4: flutter analyze 및 최종 검증

- [ ] **Step 1: flutter analyze 실행**

```bash
source ~/.zshrc && flutter analyze
```

에러가 없어야 한다. 경고가 있으면 수정 후 재실행.

- [ ] **Step 2: 동작 시나리오 확인 (개발자 검증)**

실제 디바이스/에뮬레이터에서 아래를 확인한다:
1. 앱 실행 후 임의 API 호출 시 서버가 `ITEM_DELETED_NOTICE` 응답을 주면 `ItemDeletedScreen`이 push되어야 함
2. X 버튼 클릭 시 화면이 닫히고 이전 화면으로 돌아와야 함 (로그아웃 없음)
3. 화면 닫은 후 다시 `ITEM_DELETED_NOTICE` 응답 오면 화면이 다시 뜨는지 확인 (플래그 리셋 확인)
4. "문의하기" 버튼 클릭 시 메일 앱이 열려야 함
