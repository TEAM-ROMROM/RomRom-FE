# 프로젝트 컨텍스트

## 주요 디자인 요소
- 기본 배경색: `AppColors.primaryBlack` (#131419)
- 강조색: `AppColors.primaryYellow` (#FFC300)

## 주요 파일 관계
- `AppColors`: 색상 상수 정의
- `AppTheme`: 앱 전체 테마 및 텍스트 스타일 정의
- `AppIcons`: 커스텀 아이콘 정의
- `AppUrls`: API 엔드포인트 정의

## 주석 스타일
- 한글 주석 사용 (팀원의 코드 이해를 돕는 경우에만 추가)
- 간결하고 핵심만 담은 주석 작성
- 클래스 주석: 한 줄로 요약하고 기능 설명
- 속성/필드 주석: 간결하게 한 줄로 설명
- import문, 생성자에는 주석 필요없음
- 인라인 주석 선호 (코드 우측에 짧게 설명)
- TODO/FIXME: 간결하게 핵심만 설명

### 주석 예시:
```dart
/// 공통 앱바 위젯
/// 뒤로가기 버튼, 중앙 정렬된 제목 기본 제공
class CommonAppBar {...}

/// 앱바에 표시될 제목
final String title;

backgroundColor: Colors.transparent, // 투명 배경으로 설정
```

### 변수명 규칙:
- 일반적/모호한 이름 대신 구체적이고 명확한 변수명 사용
    - 안좋은 예시: data, info, manager, utils
    - 좋은 예시: userProfileData, itemDetailInfo, authManager, dateFormatUtils
- Boolean 변수는 항상 'is' 접두사 사용
    - 안좋은 예시: valid, loading, selected
    - 좋은 예시: isValid, isLoading, isSelected
- 복수형 표현 시 'List' 접미사 대신 's' 사용
    - 안좋은 예시: itemList, userList, messageList
    - 좋은 예시: items, users, messages
- 약어 사용 자제 (특히 잘 알려지지 않은 약어)
    - 안좋은 예시: pwd, doc, idx, tmp
    - 좋은 예시: password, document, index, temporary
- 함수명은 동사로 시작하여 행동 명확하게 표현
    - 안좋은 예시: userLogin(), dataValidation()
    - 좋은 예시:loginUser(), validateData()
- 속성 접근자나 변환 함수는 get 접두사 사용
    - 안좋은 예시: userName(), totalPrice()
    - 좋은 예시:getUserName(), getTotalPrice()

## 에러 처리 가이드라인

### 에러 유형별 표시 방법
1. **경고성 에러 (Warning) → SnackBar**
   - 네트워크 일시적 오류
   - 입력 검증 오류

2. **중요한 에러 (Critical) → AlertDialog**
   - 인증 실패
   - 서버 오류
   - 데이터 저장 실패

3. **시스템 에러 (System) → 에러 페이지 이동**
   - 앱 크래시
   - 권한 문제

### 에러 처리 구현 원칙
- **일관성 유지**: 동일한 유형의 에러는 항상 동일한 방식으로 처리
- **명확한 메시지**: 사용자가 이해할 수 있는 간결하고 명확한 에러 메시지 제공
- **해결 방법 제시**: 가능한 경우 사용자가 에러를 해결할 수 있는 방법 안내
- **로깅**: 심각한 에러는 로깅하여 추후 분석 가능하게 함

### 구현 패턴
```dart
// 에러 처리 유틸리티 클래스 사용 예시
class ErrorHandler {
  /// 경고성 에러 표시
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3))
    );
  }

  /// 중요 에러 표시
  static Future<void> showCritical(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 시스템 에러 처리
  static void handleSystemError(BuildContext context, Exception error) {
    // 로깅
    logError(error);
    
    // 에러 페이지로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ErrorPage(error: error)),
    );
  }
}
```

### 에러 처리 모범 사례
- **try-catch 블록**: API 호출, 파일 조작 등 실패 가능성이 있는 작업에 사용
- **Result 패턴**: API 응답이나 작업 결과를 성공/실패로 명확히 구분하여 반환
- **Repository 레이어**: 데이터 소스 오류를 앱 도메인 오류로 변환하여 처리
- **에러 전파 제한**: 적절한 레벨에서 에러를 처리하고 불필요한 전파 방지
- **테스트**: 에러 처리 로직에 대한 단위 테스트 및 통합 테스트 작성

### 에러 메시지 작성 요령
- 기술적 세부사항보다 사용자 관점에서 문제 설명
- 오류의 원인과 해결 방법을 간결하게 제시
- 부정적 표현보다 긍정적/중립적 어조 사용
- 필요 시 재시도 또는 다른 방법 안내

## 네비게이션 가이드라인

### 화면 전환 표준 방식
모든 화면 전환은 `common_utils.dart`에 정의된 `navigateTo()` 확장 메서드를 사용합니다.
직접 `Navigator.push()` 등의 메서드를 사용하지 않고, 항상 확장 메서드를 사용하세요.

```dart
// 기본 화면 이동 (push)
context.navigateTo(
  screen: TargetScreen(),
  type: NavigationTypes.push,
);

// 이전 화면 대체 (pushReplacement)
context.navigateTo(
  screen: TargetScreen(),
  type: NavigationTypes.pushReplacement,
);

// 모든 이전 화면 제거 후 이동 (pushAndRemoveUntil)
context.navigateTo(
  screen: TargetScreen(),
  type: NavigationTypes.pushAndRemoveUntil,
);