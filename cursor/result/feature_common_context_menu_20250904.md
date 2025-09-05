### 기능 요약
- **기능명**: 공통 컨텍스트 메뉴 컴포넌트 (`RomRomContextMenu`)
- **목적/가치**: PopupMenuButton의 한계를 극복하고, 일관된 UX/UI로 프로젝트 전체의 컨텍스트 메뉴를 통합 관리
- **타입**: 신규 기능 (공통 컴포넌트)
- **버전/릴리즈**: v1.2.14+
- **관련 링크**: [이슈](https://github.com/TEAM-ROMROM/RomRom-FE/issues/261)

### 구현 내용
- **Overlay 기반 컨텍스트 메뉴**: PopupMenuButton을 대체하여 더 세밀한 제어 가능
- **4가지 애니메이션 타입**: cornerExpand(기본), scale, fade, slideDown 지원
- **스마트 위치 계산**: 화면 경계를 자동 감지하여 최적 위치에 메뉴 표시
- **향상된 UX**: 메뉴 외 클릭, 스와이프, 아이콘 재클릭 등 다양한 닫기 동작 지원
- **기존 컴포넌트 마이그레이션**: `ItemOptionsMenuButton`, `ReportMenuButton` 교체 완료

### 기술적 접근
- **도입 기술/라이브러리**: Flutter Overlay, AnimationController, GestureDetector, HapticFeedback
- **핵심 알고리즘/패턴**: Overlay 기반 커스텀 메뉴, RenderBox를 통한 동적 위치 계산, Strategy 패턴(애니메이션 타입)
- **성능 고려사항**: SingleTickerProviderStateMixin으로 애니메이션 최적화, 메모리 누수 방지를 위한 dispose 처리

### 변경사항
- **생성/수정 파일**: 
  - `lib/widgets/common/romrom_context_menu.dart` (신규)
  - `lib/widgets/common/item_options_menu.dart` (리팩토링)
  - `lib/widgets/common/report_menu_button.dart` (리팩토링)
- **핵심 코드 설명**:

```1:52:lib/widgets/common/romrom_context_menu.dart
class ContextMenuItem {
  final String id;
  final String title;
  final IconData? icon;
  final Color? textColor;
  final VoidCallback onTap;
  final bool showDividerAfter;

  const ContextMenuItem({
    required this.id,
    required this.title,
    required this.onTap,
    this.icon,
    this.textColor,
    this.showDividerAfter = false,
  });
}

class RomRomContextMenu extends StatefulWidget {
  final List<ContextMenuItem> items;
  final Widget? customTrigger;
  final ContextMenuAnimation animation;
  final ContextMenuPosition position;
  final Function(String)? onItemSelected;
  final double? menuWidth;
  final EdgeInsets menuPadding;
  final BorderRadius? menuBorderRadius;
  final Color? menuBackgroundColor;
  final double itemHeight;
  final bool enableHapticFeedback;

  const RomRomContextMenu({
    super.key,
    required this.items,
    this.customTrigger,
    this.animation = ContextMenuAnimation.cornerExpand,
    this.position = ContextMenuPosition.auto,
    this.onItemSelected,
    this.menuWidth,
    this.menuPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.menuBorderRadius,
    this.menuBackgroundColor,
    this.itemHeight = 46,
    this.enableHapticFeedback = true,
  });
  
  // ... implementation
}
```

### 설정 및 환경
- **환경 요구사항**: Flutter SDK, flutter_screenutil ^5.0.0
- **설정 변경**: 없음 (기존 의존성만 사용)
- **배포 고려사항**: 기존 PopupMenuButton 사용 컴포넌트들이 새로운 UX로 변경됨

### 테스트 방법 및 QA 가이드
- **테스트 범위**: 위젯 테스트, 통합 테스트 (UI 상호작용)
- **테스트 방법**:
  1. **기본 메뉴 표시**: 세로 점 아이콘 탭 → 컨텍스트 메뉴 표시 확인
  2. **애니메이션 확인**: 메뉴 열기/닫기 시 cornerExpand 애니메이션 동작 확인
  3. **다양한 닫기 방법**: 메뉴 외 클릭, 스와이프, 아이콘 재클릭으로 메뉴 닫힘 확인
  4. **위치 자동 조정**: 화면 경계 근처에서 메뉴 위치 자동 조정 확인
  5. **햅틱 피드백**: 메뉴 열기 시 진동, 항목 선택 시 선택 진동 확인 (iOS/Android)
  6. **기존 기능 호환**: 수정/삭제, 신고하기 기능이 정상 동작하는지 확인
- **예상 결과**: 
  - 메뉴가 부드럽게 열리고 닫힘
  - 화면 경계에서 메뉴가 잘리지 않음
  - 모든 닫기 방법이 즉시 반응
  - 기존 기능이 동일하게 작동

### 사용 예시 및 케이스

#### **기본 사용법**
```dart
RomRomContextMenu(
  items: [
    ContextMenuItem(
      id: 'edit',
      title: '수정',
      onTap: () => _handleEdit(),
    ),
    ContextMenuItem(
      id: 'delete',
      title: '삭제',
      textColor: AppColors.itemOptionsMenuDeleteText,
      onTap: () => _handleDelete(),
    ),
  ],
)
```

#### **다양한 사용 케이스**

**1. 구분선이 있는 복합 메뉴**
```dart
RomRomContextMenu(
  items: [
    ContextMenuItem(
      id: 'complete',
      title: '거래완료로 변경',
      onTap: () => _markAsCompleted(),
      showDividerAfter: true,
    ),
    ContextMenuItem(
      id: 'edit',
      title: '수정',
      onTap: () => _editItem(),
      showDividerAfter: true,
    ),
    ContextMenuItem(
      id: 'delete',
      title: '삭제',
      textColor: AppColors.itemOptionsMenuDeleteText,
      onTap: () => _deleteItem(),
    ),
  ],
)
```

**2. 아이콘이 있는 메뉴**
```dart
RomRomContextMenu(
  items: [
    ContextMenuItem(
      id: 'share',
      title: '공유하기',
      icon: Icons.share,
      onTap: () => _shareItem(),
    ),
    ContextMenuItem(
      id: 'bookmark',
      title: '북마크',
      icon: Icons.bookmark,
      onTap: () => _bookmarkItem(),
    ),
  ],
)
```

**3. 커스텀 트리거 버튼**
```dart
RomRomContextMenu(
  customTrigger: Container(
    padding: EdgeInsets.all(8),
    child: Text('더보기', style: TextStyle(color: Colors.blue)),
  ),
  items: [...],
)
```

**4. 애니메이션 타입 변경**
```dart
RomRomContextMenu(
  animation: ContextMenuAnimation.slideDown,  // 슬라이드 다운
  items: [...],
)
```

**5. 위치 고정**
```dart
RomRomContextMenu(
  position: ContextMenuPosition.above,  // 트리거 위쪽에 표시
  items: [...],
)
```

**6. 완전 커스터마이징**
```dart
RomRomContextMenu(
  menuWidth: 200.w,
  menuBackgroundColor: Colors.black87,
  menuBorderRadius: BorderRadius.circular(12.r),
  itemHeight: 50,
  enableHapticFeedback: false,
  items: [...],
)
```

### API 명세
#### **ContextMenuItem 클래스**
```dart
ContextMenuItem({
  required String id,           // 고유 식별자
  required String title,        // 표시될 텍스트
  required VoidCallback onTap,  // 탭 이벤트 핸들러
  IconData? icon,              // 선택적 아이콘
  Color? textColor,            // 텍스트 색상 (기본: 흰색)
  bool showDividerAfter,       // 해당 항목 뒤 구분선 표시 여부
})
```

#### **RomRomContextMenu 주요 파라미터**
```dart
RomRomContextMenu({
  required List<ContextMenuItem> items,  // 메뉴 항목 리스트
  Widget? customTrigger,                // 커스텀 트리거 버튼
  ContextMenuAnimation animation,       // 애니메이션 타입
  ContextMenuPosition position,         // 메뉴 표시 위치
  Function(String)? onItemSelected,     // 항목 선택 콜백
  double? menuWidth,                    // 메뉴 너비
  // ... 기타 스타일 옵션들
})
```

#### **열거형 타입**
```dart
enum ContextMenuAnimation { scale, fade, slideDown, cornerExpand }
enum ContextMenuPosition { auto, above, below, left, right }
```

### 비고/주의사항
- **PopupMenuButton과의 차이점**: 더 세밀한 제어 가능하지만 복잡도 증가
- **성능**: Overlay 사용으로 메모리 사용량이 약간 증가할 수 있음
- **플랫폼별 동작**: 햅틱 피드백은 iOS/Android에서만 작동
- **향후 개선 계획**: 
  - 키보드 네비게이션 지원
  - 서브메뉴 지원 
  - 더 많은 애니메이션 옵션

### 체크리스트
- [x] 문서/인용 정확성
- [x] 테스트 케이스 커버리지 
- [x] 성능 검증
- [x] 접근성/보안 검토

### Flutter/Dart 핵심 문법 설명

**Overlay 사용법**: Flutter에서 떠있는 위젯을 표시할 때 사용
```dart
_overlayEntry = OverlayEntry(
  builder: (context) => CustomWidget(),
);
Overlay.of(context).insert(_overlayEntry!);  // 화면에 추가
_overlayEntry?.remove();                     // 화면에서 제거
```

**GestureDetector 고급 사용**: 다양한 제스처를 감지
```dart
GestureDetector(
  onTap: () => _handleTap(),
  onVerticalDragStart: (_) => _handleClose(),    // 세로 드래그 시작 시 닫기
  onHorizontalDragStart: (_) => _handleClose(),  // 가로 드래그 시작 시 닫기
  child: Container(color: Colors.transparent),   // 투명한 배경으로 터치 영역 확보
)
```

**RenderBox를 통한 위치 계산**: 위젯의 화면상 위치와 크기를 가져옴
```dart
final RenderBox renderBox = context.findRenderObject() as RenderBox;
final Size size = renderBox.size;                    // 위젯 크기
final Offset position = renderBox.localToGlobal(Offset.zero);  // 화면상 위치
```