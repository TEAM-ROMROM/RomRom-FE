### 기능 요약
- **기능명**: 물품 등록 화면 유효성 검증 버그 수정
- **목적/가치**: 물품 등록 시 잘못된 데이터 입력 방지 및 UX 개선
- **타입**: 버그 수정
- **버전/릴리즈**: v1.2.6
- **관련 링크**: [이슈 #223](https://github.com/TEAM-ROMROM/RomRom-FE/issues/223) · [이슈 #239](https://github.com/TEAM-ROMROM/RomRom-FE/issues/239)

### 구현 내용
- TextField 위젯을 StatefulWidget으로 변환하여 포커스 상태 추적
- 입력값 유효성 검증 로직 강화 (공백 제거, 최소 글자 수 체크)
- 조건부 에러 표시로 첫 진입 시 불필요한 에러 메시지 제거
- 등록 버튼 활성화 조건을 실제 유효성과 일치하도록 수정

### 기술적 접근
- **도입 기술/라이브러리**: Flutter FocusNode, ValueListenableBuilder
- **핵심 알고리즘/패턴**: State 관리 패턴, 조건부 렌더링
- **성능 고려사항**: ValueListenableBuilder를 통한 효율적인 리렌더링

### 변경사항
- **생성/수정 파일**: `lib/widgets/register_text_field.dart`, `lib/widgets/register_input_form.dart`
- **핵심 코드 설명**:

#### 버그 1: 첫 진입 시 errorBorder 표시
**문제**: 화면 첫 진입 시 아무것도 입력하지 않았는데 에러 표시
**해결**: FocusNode로 포커스 이력 추적

```61:75:lib/widgets/register_text_field.dart
class _RegisterCustomTextFieldState extends State<RegisterCustomTextField> {
  bool _hasBeenFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_hasBeenFocused) {
        setState(() {
          _hasBeenFocused = true;
        });
      }
    });
  }
```

```167:174:lib/widgets/register_text_field.dart
  bool shouldShowError = false;
  if (_hasBeenFocused) {
    if (widget.phrase == ItemTextFieldPhrase.description) {
      shouldShowError = value.text.trim().length < 30;
    } else {
      shouldShowError = value.text.trim().isEmpty;
    }
  }
```

#### 버그 2: 공백만 입력해도 등록되는 문제
**문제**: 제목/본문에 공백만 입력해도 유효한 것으로 처리
**해결**: trim() 메소드로 공백 제거 후 검증

```314:329:lib/widgets/register_input_form.dart
  bool get isFormValid {
    // 가격 변환 (콤마 제거 후 숫자로 변환)
    final priceText = priceController.text.replaceAll(',', '').trim();
    final price = int.tryParse(priceText) ?? 0;
    
    return titleController.text.trim().isNotEmpty && // 공백만 있는 경우 제외
        selectedCategory != null &&
        descriptionController.text.trim().length >= 30 && // 최소 30자 이상, 공백만 있는 경우 제외
        selectedItemConditionTypes.isNotEmpty &&
        selectedTradeOptions.isNotEmpty &&
        price > 0 && // 0원 초과
        locationController.text.isNotEmpty &&
        _latitude != null &&
        _longitude != null &&
        imageFiles.isNotEmpty;
  }
```

#### 버그 3: 본문 30자 미만도 등록되는 문제
**문제**: 설명 필드 30자 미만 입력 시에도 등록 가능
**해결**: 유효성 검사에 최소 글자 수 조건 추가

```232:239:lib/widgets/register_text_field.dart
  if (widget.phrase == ItemTextFieldPhrase.description) {
    if (value.text.trim().isEmpty) {
      shouldShowError = true;
      errorMessage = widget.phrase.errorText;
    } else if (value.text.trim().length < 30) {
      shouldShowError = true;
      errorMessage = '설명은 최소 30자 이상 입력해주세요';
    }
```

#### 버그 4: 0원으로 등록되는 문제
**문제**: 가격 필드에 0원 입력해도 등록 가능
**해결**: 가격이 0원 초과인지 검증

```316:317:lib/widgets/register_input_form.dart
    final priceText = priceController.text.replaceAll(',', '').trim();
    final price = int.tryParse(priceText) ?? 0;
```

```324:324:lib/widgets/register_input_form.dart
        price > 0 && // 0원 초과
```

#### 버그 5: 물건 상태/거래 방식 첫 진입 시 에러 표시
**문제**: 아무것도 선택하지 않았는데 첫 진입 시 에러 표시
**해결**: 사용자가 터치한 후부터만 에러 표시

```57:59:lib/widgets/register_input_form.dart
  // 처음 포커스 받았는지 추적을 위한 변수
  bool _hasConditionBeenTouched = false;
  bool _hasTradeOptionBeenTouched = false;
```

```619:625:lib/widgets/register_input_form.dart
    (_hasConditionBeenTouched && selectedItemConditionTypes.isEmpty)
        ? Text(
            ItemTextFieldPhrase.condition.errorText,
            style: CustomTextStyles.p3
                .copyWith(color: AppColors.errorBorder),
          )
        : Text('', style: CustomTextStyles.p3),
```

### 설정 및 환경
- **환경 요구사항**: Flutter 3.x, Dart 3.x
- **설정 변경**: 없음
- **배포 고려사항**: 기존 등록 화면 사용자에게 영향 없음

### 테스트 방법 및 QA 가이드
- **테스트 범위**: 물품 등록 화면 유효성 검증
- **테스트 방법**:
  1. 물품 등록 화면 진입 → errorBorder가 표시되지 않는지 확인
  2. 제목/본문에 공백만 입력 → 등록 버튼 비활성화 확인
  3. 본문 30자 미만 입력 → 에러 메시지 표시 및 버튼 비활성화 확인
  4. 가격 0원 입력 → 등록 버튼 비활성화 확인
  5. 모든 필드 올바르게 입력 → 등록 버튼 활성화 및 등록 성공 확인
- **예상 결과**: 유효하지 않은 데이터로는 물품 등록 불가

### 비고/주의사항
- 수정 모드에서도 동일한 유효성 검증 적용됨
- AI 가격 추천 기능 사용 시에도 trim() 적용
- 포커스를 한 번이라도 받은 필드만 에러 표시 (UX 개선)

### 체크리스트
- [x] 문서/인용 정확성
- [x] 테스트 케이스 커버리지
- [x] 성능 검증
- [x] 접근성/보안 검토