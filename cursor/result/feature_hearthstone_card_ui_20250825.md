### 기능 요약
- **기능명**: 하스스톤 스타일 카드 UI 구현 및 버그 수정
- **목적/가치**: 사용자 물품을 카드 형태로 시각화하여 직관적인 거래 요청 인터페이스 제공
- **타입**: 기능 개선
- **버전/릴리즈**: v1.0.0
- **관련 링크**: [이슈 #143](https://github.com/TEAM-ROMROM/RomRom-FE/issues/143)

### 구현 내용
- 하스스톤 스타일 부채꼴 카드 배치 (최대 10개 카드 지원)
- 터치/드래그 인터랙션 (호버 시 카드 상승, 드래그 앤 드롭으로 거래 요청)
- ItemCard 오버플로우 버그 수정 및 드래그 방향 반전 문제 해결

### 기술적 접근
- **도입 기술/라이브러리**: Flutter Animation API, GestureDetector, HapticFeedback
- **핵심 알고리즘/패턴**: 부채꼴 배치 알고리즘 (삼각함수 활용), 스태거드 애니메이션
- **성능 고려사항**: AnimatedBuilder로 리렌더링 최적화, 최대 카드 개수 제한(10개)

### 변경사항
- **생성/수정 파일**: `lib/widgets/hearthstone_card_hand.dart`, `lib/widgets/item_card.dart`
- **핵심 코드 설명**:

```101:102:lib/widgets/item_card.dart
child: Column(
  mainAxisSize: MainAxisSize.min,  // 오버플로우 방지를 위한 최소 크기 설정
```

```200:207:lib/widgets/hearthstone_card_hand.dart
// 드래그 효과
if (isDragged) {
  x = _dragOffset.dx;
  y = _dragOffset.dy + _dragLift;  // 드래그 방향 수정 (위로 드래그 시 y는 음수)
  angle = _dragOffset.dx * 0.001;
  scale = 1.25;
  opacity = 0.9;
}
```

```216:218:lib/widgets/hearthstone_card_hand.dart
return Positioned(
  left: MediaQuery.of(context).size.width / 2 - _cardWidth / 2 + x,
  bottom: 60.h + y,  // y 좌표 계산 수정 (양수면 위로, 음수면 아래로)
```

### 설정 및 환경
- **환경 요구사항**: Flutter 3.0+, flutter_screenutil
- **설정 변경**: 없음
- **배포 고려사항**: 햅틱 피드백 권한 필요 (iOS/Android)

### 테스트 방법 및 QA 가이드
- **테스트 범위**: UI 인터랙션 테스트, 애니메이션 성능 테스트
- **테스트 방법**:
  1. 카드를 짧게 탭 → 카드가 위로 상승하며 노란색 글로우 효과 확인
  2. 카드를 위로 드래그 → 카드가 실제로 위쪽으로 이동하는지 확인
  3. 카드를 상단 드롭 영역까지 드래그 → 거래 요청 트리거 확인
- **예상 결과**: 모든 인터랙션이 자연스럽고 드래그 방향이 올바르게 작동

### API 명세(필요 시)
- 해당사항 없음 (프론트엔드 UI 컴포넌트)

### 비고/주의사항
- 카드 개수가 10개 초과 시 자동으로 10개까지만 표시
- 실제 API 데이터 연동 시 `cards` prop으로 물품 데이터 전달 필요
- 드래그 앤 드롭 영역은 카드 위 250px 위치에 고정

### 체크리스트
- [x] 문서/인용 정확성
- [x] 테스트 케이스 커버리지
- [x] 성능 검증
- [x] 접근성/보안 검토

### 수정 내역 상세
**문제 1: ItemCard 오버플로우 에러**
- 원인: Column 위젯의 높이가 부모 컨테이너보다 0.0645px 초과
- 해결: `mainAxisSize: MainAxisSize.min` 속성 추가로 Column이 필요한 만큼만 공간 차지

**문제 2: 드래그 방향 반전**
- 원인: y 좌표 계산 시 부호 반전 (-_dragOffset.dy)
- 해결: 
  - 드래그 오프셋: `y = _dragOffset.dy + _dragLift` (음수 제거)
  - 위치 계산: `bottom: 60.h + y` (- 를 + 로 변경)
  - 호버 효과: `y += _hoverLift * hoverValue` (-= 를 += 로 변경)