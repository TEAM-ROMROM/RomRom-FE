# 프로젝트 구조

## 디렉토리 구조
- `/lib/enums/` - 모든 enum 정의 (enum은 반드시 이 폴더에 개별 파일로 관리)
- `/lib/models/` - 데이터 모델 및 상수 정의
  - `app_colors.dart` - 모든 색상 상수
  - `app_theme.dart` - 테마 및 텍스트 스타일
- `/lib/widgets/` - 재사용 가능한 위젯
  - `/common/` - 공통 위젯
- `/lib/screens/` - 화면 구성 파일
- `/prompts/` - 개발 가이드라인 문서

## 주요 참고 파일
- `prompts/코드_스타일_가이드라인.md` - 필수 참고
- `lib/models/app_theme.dart` - 텍스트 스타일 정의
- `lib/models/app_colors.dart` - 색상 상수 정의
