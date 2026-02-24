# 코드 수정 후 자동 프로세스

## 코드 수정 후 필수 실행 (자동)
모든 코드 수정 작업 완료 후, Claude는 반드시 다음 순서로 실행합니다:

1. **코드 포매팅**
   ```bash
   source ~/.zshrc && dart format --line-length=120 .
   ```

2. **린트 분석**
   ```bash
   source ~/.zshrc && flutter analyze
   ```

3. **에러 발생 시**: 에러 수정 후 1-2번 재실행

## lefthook 통과 보장
- 위 단계를 모두 통과해야 작업 완료로 간주
- `flutter analyze`에서 에러 발생 시 반드시 수정
- 작업 완료 전 lefthook이 통과되는지 확인 필수
