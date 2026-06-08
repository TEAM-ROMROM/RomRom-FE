---
name: ❗[버그][로그인] 카카오 firebase-token 요청 오류 시 에러 처리 미흡
description: 카카오 로그인 고유 단계인 /kakao/firebase-token 요청 실패 시 이메일 중복·계정 정지 등 에러를 다른 소셜 로그인과 동일하게 처리하지 못하는 버그
type: bug
labels: 작업전
---

🗒️ 설명
---

카카오 로그인은 다른 소셜 로그인과 달리 `/api/auth/kakao/firebase-token` 요청을 한 단계 더 거친다.
이 단계에서 서버가 에러를 반환하면(이메일 중복 409, 정지 계정 등), 구글·애플 로그인과 달리 에러가 `EmailAlreadyRegisteredException` / `AccountSuspendedException` 타입으로 변환되지 않고 일반 `Exception`으로 처리된다.

결과적으로 UI에서 "다른 소셜 플랫폼으로 이미 가입된 이메일입니다"나 "정지된 계정입니다" 다이얼로그가 표시되지 않고, 에러가 핸들링되지 않는다.

- 관련 파일:
  - `lib/services/kakao_auth_service.dart` — `_signInWithFirebaseCustomToken()`
  - `lib/services/apis/rom_auth_api.dart` — `getKakaoFirebaseToken()`

🔄 재현 방법
---

1. 카카오 계정으로 로그인 시도 (구글/애플로 이미 가입된 이메일 계정 사용)
2. 카카오 로그인 버튼 클릭
3. 카카오 계정 인증 완료
4. `/kakao/firebase-token` 요청 단계에서 409 또는 에러 응답 수신
5. 이메일 중복 안내 모달이 표시되지 않고 에러가 사라지거나 예상치 못한 동작 발생 확인

📸 참고 자료
---

- 관련 파일:
  - `lib/services/kakao_auth_service.dart` — `loginWithKakaoTalk()`, `loginWithKakaoAccount()`, `_signInWithFirebaseCustomToken()`
  - `lib/services/apis/rom_auth_api.dart` — `getKakaoFirebaseToken()`
  - `lib/exceptions/email_already_registered_exception.dart`
  - `lib/exceptions/account_suspended_exception.dart`
  - `lib/widgets/login_button.dart` — 소셜 로그인 공통 에러 처리 위치

✅ 예상 동작
---

- `/kakao/firebase-token` 요청에서 이메일 중복(409) 에러 발생 시 → `EmailAlreadyRegisteredException` throw → 다른 소셜 로그인과 동일하게 "다른 소셜 플랫폼으로 이미 가입된 이메일" 안내 모달 표시
- 정지 계정 에러 발생 시 → `AccountSuspendedException` throw → "정지된 계정입니다" 안내 모달 표시
- 구글·애플 로그인의 에러 처리 흐름과 동일하게 동작해야 한다.

⚙️ 환경 정보
---

- **OS**: iOS / Android
- **브라우저**: -
- **기기**: 전 기기

🙋‍♂️ 담당자
---

- **백엔드**: 미정
- **프론트엔드**: 미정
- **디자인**: -
