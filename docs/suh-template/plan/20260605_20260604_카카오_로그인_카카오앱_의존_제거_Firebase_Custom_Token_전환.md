# 🎯 카카오 로그인 카카오앱 의존 제거 + Firebase Custom Token 전환 전략 문서

> 관련 이슈: [#911](https://github.com/TEAM-ROMROM/RomRom-FE/issues/911)

---

## 1. 요약

카카오 로그인을 카카오톡 앱 설치 여부와 무관하게 동작하도록 **인앱 웹 로그인 폴백**을 추가하고,
Firebase 인증 방식을 기존 OIDC Provider에서 **백엔드 발급 Custom Token** 방식으로 전환한다.
두 변경은 `kakao_auth_service.dart` 하나와 신규 API 메서드 하나로 처리 가능하며, 로그인 이후 흐름(`signInWithSocial`)은 그대로 유지된다.

---

## 2. 배경 및 목적

### 문제/필요성
| 문제 | 내용 |
|------|------|
| Apple App Store 반려 | Guideline 4.2.3(i) 위반 — 카카오톡 앱 없으면 로그인 불가 |
| OIDC 방식 한계 | 카카오 웹 로그인 시 `idToken.aud`가 REST API 키 → 네이티브 앱 키와 불일치, OIDC audience 오류 발생 |
| UID 불일치 위험 | 앱 로그인 vs 웹 로그인 경로에 따라 Firebase UID가 달라질 수 있음 |

### 목표
1. 카카오톡 미설치 환경에서 카카오 계정 웹 로그인(`loginWithKakaoAccount`) 지원
2. Firebase 인증을 백엔드 Custom Token으로 통일 → UID = `kakao:{카카오회원번호}`로 고정
3. Apple App Store 재심사 통과

### 범위
- **포함**: `kakao_auth_service.dart`, `rom_auth_api.dart` (또는 신규 API 파일)
- **제외**: Google/Apple 로그인, 로그아웃/회원탈퇴 플로우, `login_button.dart` UI

---

## 3. 요구사항

### 필수 (P0)
- [ ] 카카오톡 미설치 시 인앱 웹 로그인(`loginWithKakaoAccount`)으로 자동 전환
- [ ] `accessToken`을 백엔드로 전달하여 Firebase `customToken` 발급
- [ ] `FirebaseAuth.instance.signInWithCustomToken(customToken)` 호출
- [ ] 기존 `signInWithSocial` → `firebaseIdToken` 전달 방식 유지
- [ ] `providerId` 파라미터 확인 및 필요 시 수정

### 중요 (P1)
- [ ] 에러 처리: 백엔드 에러코드(`EMPTY_SOCIAL_AUTH_TOKEN`, `KAKAO_API_ERROR` 등) 대응
- [ ] 웹 로그인 취소(`PlatformException(CANCELED)`) 조용히 처리
- [ ] `dart format` + `flutter analyze` 통과

### 선택 (P2)
- [ ] 기존 OIDC 관련 주석/코드 완전 제거 (코드베이스 정리)

---

## 4. 선택한 접근 방식

**방식**: `loginWithKakaoAccount` 폴백 + 백엔드 Custom Token API 연동 (단일 서비스 파일 수정)

**이유**:
- 웹 로그인은 카카오 SDK가 내부적으로 인앱 브라우저(SFSafariViewController / Chrome Custom Tabs)를 사용 → 별도 웹뷰 패키지 불필요
- Custom Token 방식은 aud 불일치 문제 원천 차단 + 앱/웹 로그인 모두 동일 UID 보장
- 기존 `_handleLoginSuccess` 구조를 유지하면서 `_signInWithFirebase` 내부만 교체 → 변경 범위 최소화

**대안 및 미선택 이유**:
| 대안 | 미선택 이유 |
|------|------------|
| `flutter_inappwebview` 직접 구현 | 카카오 SDK `loginWithKakaoAccount`가 이미 동일 기능 제공, 추가 의존성 불필요 |
| OIDC Provider 유지 + REST API 키 분기 | audience 불일치 근본 해결 안 됨, UID 불일치 위험 잔존 |

---

## 5. 주요 결정사항

| 결정 | 선택 | 이유 |
|------|------|------|
| 웹 로그인 방식 | `UserApi.instance.loginWithKakaoAccount()` | 카카오 SDK 내장, 별도 패키지 불필요 |
| 폴백 조건 | `isKakaoTalkInstalled()` false 시 자동 전환 | 기존 로직 패턴 유지 |
| Firebase 인증 방식 | `signInWithCustomToken(customToken)` | 백엔드 발급, UID 고정 |
| 신규 API 위치 | `rom_auth_api.dart`에 메서드 추가 | 기존 Auth API 집합체에 귀속, 파일 분산 최소화 |
| `providerId` | `'oidc.kakao'` → **`'kakao'`** 로 변경 | 백엔드 `mapProviderIdToSocialPlatform()`에 `"kakao"` case 추가 확인됨 |

---

## 6. 변경 대상 파일 및 세부 작업

### Task 1: 신규 API 메서드 추가 — `rom_auth_api.dart`

```
POST /api/auth/kakao/firebase-token   ✅ 엔드포인트 확정
Body: { "accessToken": "<카카오 accessToken>" }
Response: { "customToken": "<Firebase Custom Token>" }
인증: 불필요 (isAuthRequired: false)
```

- `getKakaoFirebaseToken(String accessToken)` 메서드 추가
- 에러코드 대응 (HTTP 4xx/5xx):
  - `EMPTY_SOCIAL_AUTH_TOKEN`: 카카오 AccessToken 없음
  - `KAKAO_API_ERROR` (502): 카카오 사용자 정보 조회 실패
  - `INVALID_SOCIAL_MEMBER_INFO`: 카카오 회원 ID 조회 실패
  - `FIREBASE_CUSTOM_TOKEN_ISSUE_FAILED` (500): Firebase Custom Token 발급 실패

### Task 2: `kakao_auth_service.dart` 수정

#### 2-1. `loginWithKakao()` — 웹 로그인 폴백 추가
```
기존: 카카오톡 미설치 → 설치 유도 다이얼로그 → 스토어 이동
변경: 카카오톡 미설치 → loginWithKakaoAccount() 자동 실행
```

#### 2-2. `_signInWithFirebase()` → `_signInWithFirebaseCustomToken()` 교체
```
기존: OAuthProvider('oidc.kakao').credential(idToken, accessToken) → signInWithCredential
변경: romAuthApi.getKakaoFirebaseToken(accessToken) → signInWithCustomToken(customToken)
```

#### 2-3. `_handleLoginSuccess()` 수정
```
기존: _signInWithFirebase(token) → firebaseIdToken → signInWithSocial(firebaseIdToken, 'oidc.kakao')
변경: _signInWithFirebaseCustomToken(token.accessToken) → firebaseIdToken → signInWithSocial(firebaseIdToken, 'kakao')
     * providerId = 'kakao' 확정 (백엔드 mapProviderIdToSocialPlatform에 "kakao" case 추가됨)
```

#### 2-4. 불필요한 코드 제거
- `_showKakaoTalkInstallDialog()` 메서드 제거
- OIDC 관련 주석 및 `OAuthProvider`, `OAuthCredential` 사용 코드 제거

---

## 7. 변경 플로우 비교

### Before
```
loginWithKakao()
  └─ isKakaoTalkInstalled()
      ├─ true  → loginWithKakaoTalk() → OAuthToken
      │            └─ _signInWithFirebase(token)
      │                 └─ OAuthProvider('oidc.kakao').credential(idToken, accessToken)
      │                 └─ signInWithCredential(credential)
      │                 └─ getIdToken() → signInWithSocial(idToken, 'oidc.kakao')
      └─ false → _showKakaoTalkInstallDialog() → 스토어 이동
```

### After
```
loginWithKakao()
  └─ isKakaoTalkInstalled()
      ├─ true  → loginWithKakaoTalk() → OAuthToken
      └─ false → loginWithKakaoAccount() → OAuthToken  ← NEW

OAuthToken 획득 후 공통:
  └─ _handleLoginSuccess(token)
       └─ romAuthApi.getKakaoFirebaseToken(token.accessToken)  ← NEW
            └─ { customToken }
            └─ signInWithCustomToken(customToken)             ← NEW
            └─ getIdToken() → signInWithSocial(firebaseIdToken, 'kakao')  ✅ providerId 확정
```

---

## 8. 고려사항 및 위험요소

| 구분 | 위험 | 대응 방안 |
|------|------|-----------|
| 기술 | 웹 로그인 시 `idToken` 없음 | Custom Token 방식은 `accessToken`만 사용 → 문제 없음 ✅ |
| 기술 | 기존 Firebase OIDC 설정 의존 | 백엔드 서버 배포 후 프론트 배포 순서 지킬 것 |
| 비즈니스 | 기존 oidc.kakao 회원 UID 불일치 | ✅ 백엔드에서 자동 처리 — email 1차 조회 후 `firebaseUid` null이면 자동 세팅 |
| 기술 | `KAKAO_API_ERROR` (502) 에러 | 사용자에게 "잠시 후 다시 시도" 메시지 표시 (기존 catch 블록 처리) |

---

## 9. 성공 기준

- [ ] 카카오톡 미설치 환경(시뮬레이터)에서 웹 로그인으로 정상 회원가입/로그인 완료
- [ ] 카카오톡 설치 환경에서 앱 로그인 정상 동작 (기존 동작 유지)
- [ ] Firebase Custom Token으로 로그인 후 `currentUser.uid == 'kakao:{카카오회원번호}'` 확인
- [ ] `flutter analyze` 에러 0건
- [ ] Apple App Store 재심사 통과

---

## 10. 다음 단계

> ✅ 백엔드 구현 완료 — 모든 미확정 사항 확인됨

1. `/implement` 로 바로 구현 진행
   - Task 1: `rom_auth_api.dart` — `getKakaoFirebaseToken()` 추가
   - Task 2: `kakao_auth_service.dart` — 웹 폴백 + Custom Token 교체 + OIDC 코드 제거
