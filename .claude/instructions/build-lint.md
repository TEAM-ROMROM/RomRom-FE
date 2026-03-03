# 빌드, 린트, 포매팅 가이드

## CLI 명령어 필수 prefix
모든 명령어 앞에 반드시 `source ~/.zshrc &&`를 붙여서 실행해야 작동함.

## 코드 변경 후 마지막에 꼭 실행
```bash
# 1. 코드 포매팅 (line-length 120 기준)
source ~/.zshrc && dart format --line-length=120 .

# 2. 린트 분석
source ~/.zshrc && flutter analyze
```

## 코드 포매팅 규칙
- **line-length**: 120 (팀 표준)
- **포매팅 도구**: `dart format` (Prettier와 동등한 공식 포매터)
- **코드 수정 후 반드시 포맷 적용**: 모든 dart 파일 변경 시 `dart format` 실행 필수
- **CI에서 자동 체크**: PR 시 포맷 미준수 코드는 자동 실패

## 포매팅 명령어 모음
```bash
# 전체 프로젝트 포맷 적용
source ~/.zshrc && dart format --line-length=120 .

# 특정 파일만 포맷 적용
source ~/.zshrc && dart format --line-length=120 lib/screens/example_screen.dart

# 포맷 체크만 (변경 없이 확인)
source ~/.zshrc && dart format --line-length=120 --set-exit-if-changed .
```
