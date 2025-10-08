# 🎯 ROMROM - AI 기반 스마트 중고거래 플랫폼

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.3.13 (2025-10-08)

[전체 업데이트 내역 보기](CHANGELOG.md)

<div align="center">
  
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Version](https://img.shields.io/badge/version-1.3.3-blue?style=for-the-badge)
  ![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey?style=for-the-badge)
  
</div>

## 📱 프로젝트 소개

**RomRom**은 AI 기술을 활용한 혁신적인 중고거래 플랫폼입니다. 카드 게임 UX를 통해 재미있고 직관적인 거래 경험을 제공하며, AI가 추천하는 최적의 매칭으로 효율적인 중고거래를 지원합니다.

### ✨ 핵심 특징

- **🎴 카드 게임 UX**: 스와이프 기반의 직관적이고 재미있는 인터페이스
- **🤖 AI 매칭 시스템**: 사용자의 선호도를 학습하여 최적의 상품 추천
- **📍 위치 기반 서비스**: 동네 인증을 통한 안전한 지역 거래
- **💬 실시간 채팅**: 구매자와 판매자 간 원활한 소통
- **🔄 물물교환 지원**: 현금 거래뿐만 아니라 물물교환도 가능


## 📂 프로젝트 구조

<table>
<tr>
<th>디렉토리</th>
<th>설명</th>
<th>주요 파일/모듈</th>
</tr>
<tr>
<td><code>lib/</code></td>
<td>메인 소스 코드</td>
<td>Flutter 애플리케이션 코어</td>
</tr>
<tr>
<td><code>├── screens/</code></td>
<td>화면 구성 요소</td>
<td>
  • <code>home_tab_screen.dart</code> - 홈 피드<br>
  • <code>register_tab_screen.dart</code> - 물품 등록<br>
  • <code>request_management_tab_screen.dart</code> - 요청 관리<br>
  • <code>my_page_tab_screen.dart</code> - 마이페이지<br>
  • <code>item_detail_description_screen.dart</code> - 상품 상세
</td>
</tr>
<tr>
<td><code>├── widgets/</code></td>
<td>재사용 가능 컴포넌트</td>
<td>
  • <code>home_feed_item_widget.dart</code> - 피드 아이템<br>
  • <code>home_tab_card_hand.dart</code> - 카드 핸드 UI<br>
  • <code>item_card.dart</code> - 상품 카드<br>
  • <code>register_input_form.dart</code> - 등록 폼<br>
  • <code>common/</code> - 공통 위젯 모음
</td>
</tr>
<tr>
<td><code>├── models/</code></td>
<td>데이터 모델 & 상수</td>
<td>
  • <code>app_colors.dart</code> - 컬러 팔레트<br>
  • <code>app_theme.dart</code> - 테마 설정<br>
  • <code>user_info.dart</code> - 사용자 모델<br>
  • <code>home_feed_item.dart</code> - 피드 아이템 모델
</td>
</tr>
<tr>
<td><code>├── services/</code></td>
<td>비즈니스 로직 & API</td>
<td>
  • <code>api_client.dart</code> - HTTP 클라이언트<br>
  • <code>auth_service.dart</code> - 인증 서비스<br>
  • <code>location_service.dart</code> - 위치 서비스<br>
  • <code>token_manager.dart</code> - 토큰 관리<br>
  • <code>apis/</code> - API 엔드포인트
</td>
</tr>
<tr>
<td><code>├── enums/</code></td>
<td>열거형 상수</td>
<td>
  • <code>item_categories.dart</code> - 카테고리<br>
  • <code>trade_status.dart</code> - 거래 상태<br>
  • <code>login_platforms.dart</code> - 로그인 플랫폼
</td>
</tr>
<tr>
<td><code>├── utils/</code></td>
<td>유틸리티 함수</td>
<td>
  • <code>common_utils.dart</code> - 공통 유틸<br>
  • <code>navigation_extension.dart</code> - 네비게이션
</td>
</tr>
<tr>
<td><code>assets/</code></td>
<td>리소스 파일</td>
<td>
  • <code>images/</code> - 이미지 리소스<br>
  • <code>fonts/</code> - 폰트 파일<br>
  • <code>terms/</code> - 약관 텍스트
</td>
</tr>
<tr>
<td><code>ios/</code></td>
<td>iOS 플랫폼 설정</td>
<td>Xcode 프로젝트 파일</td>
</tr>
<tr>
<td><code>android/</code></td>
<td>Android 플랫폼 설정</td>
<td>Gradle 빌드 파일</td>
</tr>
</table>

## 🛠️ 기술 스택

### 📦 주요 패키지

<table>
<tr>
<th>카테고리</th>
<th>패키지</th>
<th>용도</th>
</tr>
<tr>
<td rowspan="3"><b>상태 관리</b></td>
<td><code>flutter_riverpod</code></td>
<td>상태 관리 솔루션</td>
</tr>
<tr>
<td><code>provider</code></td>
<td>의존성 주입</td>
</tr>
<tr>
<td><code>shared_preferences</code></td>
<td>로컬 데이터 저장</td>
</tr>
<tr>
<td rowspan="3"><b>인증</b></td>
<td><code>kakao_flutter_sdk</code></td>
<td>카카오 로그인</td>
</tr>
<tr>
<td><code>google_sign_in</code></td>
<td>구글 로그인</td>
</tr>
<tr>
<td><code>flutter_secure_storage</code></td>
<td>보안 토큰 저장</td>
</tr>
<tr>
<td rowspan="3"><b>위치 서비스</b></td>
<td><code>flutter_naver_map</code></td>
<td>네이버 지도</td>
</tr>
<tr>
<td><code>geolocator</code></td>
<td>GPS 위치 정보</td>
</tr>
<tr>
<td><code>geocoding</code></td>
<td>주소 변환</td>
</tr>
<tr>
<td rowspan="3"><b>UI/UX</b></td>
<td><code>flutter_screenutil</code></td>
<td>반응형 디자인</td>
</tr>
<tr>
<td><code>skeletonizer</code></td>
<td>스켈레톤 로딩</td>
</tr>
<tr>
<td><code>playing_cards_layouts</code></td>
<td>카드 레이아웃</td>
</tr>
<tr>
<td rowspan="2"><b>미디어</b></td>
<td><code>image_picker</code></td>
<td>이미지 선택</td>
</tr>
<tr>
<td><code>flutter_svg</code></td>
<td>SVG 이미지</td>
</tr>
</table>

## 🎨 디자인 시스템

### 컬러 팔레트
- **Primary Black**: `#1D1E27` - 메인 다크 컬러
- **Primary Yellow**: `#FFC300` - 브랜드 시그니처 컬러
- **Secondary Colors**: 다양한 UI 상태 표현을 위한 보조 색상

### 폰트 시스템
- **Pretendard**: 메인 본문 폰트 (Weight: 100-900)
- **NEXON Lv2 Gothic**: 디스플레이 폰트
- **Custom Icons**: 앱 전용 아이콘 폰트

## 🚦 시작하기

### 요구사항
- Flutter SDK: ^3.3.0
- Dart SDK: ^3.3.0
- iOS: 12.0 이상
- Android: API 21 이상

### 설치 및 실행

```bash
# 1. 의존성 설치

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.3.13 (2025-10-08)
flutter pub get

# 2. 코드 생성 (필요시)

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.3.13 (2025-10-08)
flutter pub run build_runner build

# 3. 실행

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.3.13 (2025-10-08)
flutter run

# 4. 빌드

<!-- 수정하지마세요 자동으로 동기화 됩니다 -->
## 최신 버전 : v1.3.13 (2025-10-08)
flutter build ios  # iOS
flutter build apk  # Android
```

## 📝 개발 가이드

### 코드 스타일
- [코드 스타일 가이드라인](prompts/코드_스타일_가이드라인.md) 참고
- `CustomTextStyles` 사용 필수
- `AppColors` 상수 활용
- iOS 스와이프 제스처 지원을 위한 `context.navigateTo()` 사용

### 커밋 컨벤션
- `feat:` 새로운 기능 추가
- `fix:` 버그 수정
- `refactor:` 코드 리팩토링
- `style:` UI/스타일 변경
- `docs:` 문서 수정
- `chore:` 빌드, 설정 변경

## 📊 프로젝트 현황

- **현재 버전**: 1.3.3
- **지원 플랫폼**: iOS, Android
- **최소 SDK**: Flutter 3.3.0
- **타겟 사용자**: 20-30대 모바일 중고거래 이용자

## 🤝 기여하기

프로젝트 기여를 환영합니다! [GitHub Issues](https://github.com/TEAM-ROMROM/RomRom-FE/issues)에서 이슈를 확인하고 PR을 제출해주세요.

## 📄 라이선스

이 프로젝트는 비공개 소프트웨어입니다. 무단 복제 및 배포를 금지합니다.

