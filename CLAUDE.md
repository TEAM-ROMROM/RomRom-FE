# RomRom Flutter 프로젝트

Flutter 기반 중고거래 플랫폼. iOS/Android 전용 (웹 불필요).

## 절대 규칙
- 텍스트 스타일: `CustomTextStyles` 사용 (직접 TextStyle 금지)
- 색상: `AppColors` 사용 (직접 Color 코드 금지)
- 화면 이동: `context.navigateTo()` 사용 (MaterialPageRoute 금지)
- Enum 분리: 모든 enum은 `lib/enums/` 폴더에 개별 파일로 관리
- CLI: 모든 명령어 앞에 `source ~/.zshrc &&` 필수
- Git: 사용자 허락 없이 절대 커밋 금지

## UI 패턴 규칙
- **API 중복 요청 방지**: 버튼/액션에서 API를 호출할 때 `Set<T> _pendingRequests` 패턴으로 진행 중인 요청 추적. 요청 시작 시 Set에 추가, `finally`에서 제거. 이미 Set에 있으면 early return.

```dart
// ✅ 올바른 예시
final Set<NotificationType> _pendingMuteRequests = {};

Future<void> _onToggle(NotificationType type) async {
  if (_pendingMuteRequests.contains(type)) return; // 중복 클릭 무시
  setState(() => _pendingMuteRequests.add(type));
  try {
    await api.call();
    setState(() { /* 상태 업데이트 */ });
  } finally {
    if (mounted) setState(() => _pendingMuteRequests.remove(type));
  }
}
```

## 모듈별 상세 가이드
| 작업 | 참조 파일 |
|------|----------|
| 코드 스타일 & 예시 | `.claude/instructions/code-style.md` |
| 빌드, 린트, 포매팅 | `.claude/instructions/build-lint.md` |
| 프로젝트 구조 | `.claude/instructions/project-structure.md` |
| Git & 커밋 규칙 | `.claude/instructions/git-rules.md` |
| 코드 수정 후 자동 프로세스 | `.claude/instructions/auto-process.md` |
