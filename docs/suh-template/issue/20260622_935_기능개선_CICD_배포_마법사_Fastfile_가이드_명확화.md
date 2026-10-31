---
제목: 🚀[기능개선][CICD] 배포 마법사·Fastfile 가이드 명확화 (심사 Notes 초기화 명시 등)
라벨: 작업전
담당자: Cassiiopeia
연관 이슈: #934
---

📝 현재 문제점
---

- iOS 배포(testflight) Fastfile 헤더 가이드 주석이 **심사 정보(`review_information`) 폴더의 동작을 일부만 설명**해 오해 소지가 있다.
  - 같은 `review_information` 폴더 안에서도 항목별로 동작이 **의도적으로 다르다**:
    - **연락처·데모계정(`app_review_information`)**: 파일을 만들지 않아 App Store Connect 기존값을 **보존**한다.
    - **심사 Notes(`review_information/notes.txt`)**: 매 배포마다 빈 값으로 덮어써 **초기화(삭제)** 한다. (이전 버전 거절 소명서가 ASC에서 자동 승계되어 다음 심사까지 남는 문제를 막기 위함)
  - 그런데 기존 주석은 "연락처·데모계정은 ASC 기존값 보존"만 강조해, 읽는 사람이 **Notes도 보존된다고 오해**할 수 있었다.
- 처음 배포를 세팅하는 사용자가 배포 마법사 완료 화면만 보고는 **배포 모드 3종의 차이·신규 앱 최초 수동 제출 필요성·모드 변경 위치**를 알기 어려웠다.

🛠️ 해결 방안 / 제안 기능
---

- testflight Fastfile 헤더 가이드 주석에 **「심사 Notes」 초기화 항목을 추가**해, Notes는 보존이 아니라 매 배포마다 초기화된다는 점과 그 이유(거절 소명서 자동 승계 방지)를 명시한다.
- 배포 마법사 완료 단계에 **"배포 모드 & 출시 로드맵" 안내 카드**를 추가한다.
  - 배포 모드 3종(`store_only` / `store_prepare` / `store_submit`)의 차이를 한눈에 설명.
  - 출시 로드맵 3단계(테스트 트랙 검증 → 최초 1회 수동 심사 제출/출시 → 자동화 전환)를 안내.
  - 모드 변경 위치(저장소 Settings → Variables의 `IOS_DEPLOY_MODE` / `ANDROID_DEPLOY_MODE`)와 상세 동작 참조 파일을 안내.
- 템플릿 옵션별 가이드 주석(배포 모드·신규 앱 최초 수동 제출·로케일 `ko` 제약·개인정보 미하드코딩)을 보강한다.

⚙️ 작업 내용
---

- `testflight-wizard/templates/Fastfile` 헤더 주석에 「심사 Notes」 초기화 항목 추가 및 가이드 주석 보강
- `testflight-wizard/testflight-wizard.html`, `playstore-wizard/playstore-wizard.html` 완료 단계에 배포 모드·출시 로드맵 안내 카드 추가
- testflight 옛 경로·Appfile 오안내 정리, playstore 죽은 함수 정리 (선행 작업분 포함)

🙋‍♂️ 담당자
---

- 프론트엔드/CICD: Cassiiopeia
