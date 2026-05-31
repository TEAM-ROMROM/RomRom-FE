# 내 프로필 인라인 편집 설계

**날짜:** 2026-05-11  
**이슈 배경:** 내 프로필 화면에서 "프로필 수정" 버튼을 눌러 별도 화면으로 이동하는 UX를 제거하고, 프로필 화면에서 바로 인라인 편집 가능하도록 변경

---

## 목표

- `MemberProfileScreen`에서 내 프로필 조회 시 별도 편집 화면(MyProfileEditScreen)으로 이동하지 않고 인라인 편집 가능
- "프로필 수정" 버튼 제거
- 변경 사항 발생 시 앱바 우측에 "저장" 버튼 표시

---

## 변경 범위

### 수정 대상

#### `lib/screens/profile/member_profile_screen.dart`

**상태 추가 (내 프로필 전용):**
- `bool _showSaveButton` — 저장 버튼 노출 여부 (기본: false)
- `bool _isProfileEdited` — 변경 여부 추적 (기본: false)
- `bool _isSaving` — 저장 중 여부, 중복 호출 방지 (기본: false)

**앱바 actions 변경:**
- 현재: 내 프로필이면 actions=null, 타인 프로필이면 컨텍스트 메뉴
- 변경: 내 프로필 + `_showSaveButton`이면 "저장" 텍스트 버튼 표시

**저장 로직:**
- `MemberApi().updateMemberProfile(_nickname, _imageUrl)` 호출
- `UgcViolationException` 포함한 예외 처리 (MyProfileEditScreen과 동일)
- 저장 성공 시: SnackBar 표시, `_showSaveButton = false`, `_isProfileEdited = false`

**뒤로가기 처리 (`_handleBackPressed`):**
- `_isProfileEdited == true`이면 confirm 모달: "변경 사항이 저장되지 않았습니다.\n저장하지 않고 나가시겠습니까?"
- 확인 시 pop, 취소 시 유지
- 기존 차단 상태 변경 결과 반환 로직은 그대로 유지

**`ProfileOverviewSection` 렌더링 변경:**
- 내 프로필 시 `isEditable: true`로 변경 (현재 `false`)
- 콜백 연결:
  - `onShowSaveButton`: `_showSaveButton = true`
  - `onImageUploaded`: `_imageUrl = url`, `_isProfileEdited = true`
  - `onNicknameChanged`: `_nickname = nickname`, `_isProfileEdited = true`, `_showSaveButton = true`
  - `onUploadFailed`: `_isProfileEdited`가 false면 `_showSaveButton = false`

**제거:**
- `_buildEditButton()` 메서드
- `_navigateToEditScreen()` 메서드
- `if (_isMyProfile) _buildEditButton()` 위젯

### 삭제 대상

- `lib/screens/my_page/my_profile_edit_screen.dart` — 더 이상 사용되지 않음

### 유지 대상

- `lib/screens/my_page/profile_image_crop_screen.dart` — `ProfileOverviewSection`이 직접 사용

---

## 데이터 흐름

```
사용자 인터랙션
  └─ 닉네임 편집 → onNicknameChanged → _nickname 업데이트, 저장 버튼 표시
  └─ 이미지 변경 → onShowSaveButton → 업로드 완료 → onImageUploaded → _imageUrl 업데이트
  └─ 저장 버튼 탭 → updateMemberProfile(_nickname, _imageUrl) → 성공/실패 처리
  └─ 뒤로가기 → _isProfileEdited 확인 → 모달 or pop
```

---

## 예외 처리

| 상황 | 처리 |
|------|------|
| UGC 위반 닉네임 | `UgcViolationException` catch → `CommonModal.error` |
| 이미지 업로드 실패 | `onUploadFailed` → 미편집 상태면 저장 버튼 숨김 |
| 저장 중 중복 탭 | `_isSaving` 체크로 early return |
| 닉네임 비어있을 때 저장 | `_isProfileEdited && _nickname.isNotEmpty` 조건 확인 |
| 뒤로가기(미저장 변경 있음) | confirm 모달 → 확인 시 pop |

---

## 제약사항

- 차단 상태 변경(`_blockStatusChanged`) 결과 반환 로직은 기존과 동일하게 유지
- `ProfileOverviewSection`의 `isEditable` 인터페이스는 변경하지 않음
- iPad 대응: `ProfileOverviewSection` 내부에서 이미 처리됨
