# Changelog

이 프로젝트의 모든 주목할 만한 변경사항이 이 파일에 문서화됩니다.

  
## [1.1.4] - 2025-01-27
## [1.1.8] - 2025-07-26

"body_html": "\n## Summary by CodeRabbit\n**새로운 기능**\n
\n
- 자동 버전 업데이트 및 CHANGELOG 자동 갱신 워크플로우가 추가되었습니다.\n
- TestFlight 업로드 시 CHANGELOG의 릴리즈 노트가 자동 포함됩니다.\n
\n**버그 수정**\n
\n
- 홈 탭 블러 상태에서 세로 스와이프 차단 문제 및 \"내 물건 등록\" 오버레이 지속 노출 현상이 해결되었습니다.\n
\n**개선 사항**\n
\n
- 블러 및 코치마크 노출 조건이 아이템 보유 여부까지 반영되도록 개선되었습니다.\n
- 이미지 URL 관련 데이터 필드 및 매핑이 일관성 있게 정정되었습니다.\n
- iOS 코드 서명 팀 정보가 갱신되었습니다.\n
- 자동 리뷰 브랜치 대상이 확장되었습니다.\n
\n**문서화**\n
\n
- CHANGELOG.md 파일이 새로 추가되어 주요 변경 사항을 문서화합니다.\n
\n**스타일**\n
\n
- 일부 아이콘 레이아웃 및 크기 조정이 적용되었습니다.\n
\n",
"active_lock_reason": null,
"merged": false,
"mergeable": true,
"rebaseable": false,
"mergeable_state": "unstable",
"merged_by": null,
"comments": 1,
"review_comments": 2,
"maintainer_can_modify": false,
"commits": 31,
"additions": 454,
"deletions": 106,
"changed_files": 15

---


## Summary by CodeRabbit

**새 기능**
- 자동 패치 버전 업데이트를 위한 GitHub Actions 워크플로우가 추가되었습니다.
- CHANGELOG.md 자동 업데이트 시스템이 추가되었습니다.

**버그 수정**
- 홈 탭 첫 진입 시 블러 상태에서 세로 스와이프가 차단되지 않던 문제를 수정했습니다.
- 내 물품 등록 CTA 오버레이가 고정되지 않던 문제를 해결했습니다.

**개선사항**
- 내 물품 보유 여부에 따른 블러 및 코치마크 표시 로직이 개선되었습니다.
- CodeRabbit 자동 리뷰 설정이 deploy 브랜치에서도 작동하도록 개선되었습니다.

**빌드/배포**
- main 브랜치 push 시 자동 버전 증가 시스템을 도입했습니다.
- deploy 브랜치에서는 버전 업 없이 현재 버전으로 배포하도록 변경했습니다.
- TestFlight 업로드 시 CHANGELOG 내용이 release notes로 자동 포함됩니다.

--- 