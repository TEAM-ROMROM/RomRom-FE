# 프로젝트 컨텍스트

## 주요 디자인 요소
- 기본 배경색: `AppColors.primaryBlack` (#131419)
- 강조색: `AppColors.primaryYellow` (#FFC300)
- 기본 폰트: Pretendard

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
/// 뒤로가기 버튼과 중앙 정렬된 제목을 기본 제공
class CommonAppBar {...}

/// 앱바에 표시될 제목
final String title;

backgroundColor: Colors.transparent, // 투명 배경으로 설정