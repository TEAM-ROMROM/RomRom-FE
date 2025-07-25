# Changelog

이 프로젝트의 모든 주목할 만한 변경사항이 이 파일에 문서화됩니다.

  
## [1.1.4] - 2025-01-27
## [1.1.7] - 2025-07-25

  "body_html": "\n## Summary by CodeRabbit\n
\n- \n**새 기능**\n
\n- 자동 패치 버전 업데이트를 위한 GitHub Actions 워크플로우가 추가되었습니다.\n- 병합된 PR의 요약을 자동으로 추출해 CHANGELOG.md를 업데이트하는 워크플로우가 추가되었습니다.\n\n\n- \n**버그 수정**\n
\n- 아이템 이미지 관련 필드명이 itemImagePaths에서 itemImageUrls로 변경되어 이미지 표시가 정상화되었습니다.\n- 네이버 역지오코드 API의 기본 URL이 수정되었습니다.\n\n\n- \n**개선사항**\n
\n- 홈 탭에서 첫 진입 시 블러 및 코치마크 표시 조건이 개선되었습니다.\n- 피드 스크롤 동작 및 코치마크 페이지 인디케이터가 개선되었습니다.\n- 마이페이지 탭의 아이템 카드 이미지 소스가 itemImageUrls로 변경되었습니다.\n- 신고 메뉴 버튼의 아이콘 크기 및 레이아웃이 조정되었습니다.\n\n\n- \n**빌드/배포**\n
\n- 안드로이드 빌드 시 버전 정보 추출 및 APK 파일명에 버전 정보가 포함되도록 변경되었습니다.\n- iOS 빌드 구성의 DEVELOPMENT_TEAM 값이 변경되었습니다.\n- iOS TestFlight 배포 시 기존 버전을 사용하고 릴리즈 노트를 자동으로 포함하도록 변경되었습니다.\n- 메인 브랜치 푸시 시 자동으로 버전이 증가하도록 빌드 프로세스가 개선되었습니다.\n\n\n- \n**문서/설정**\n
\n- pubspec.yaml의 버전이 1.1.6+1.1.0으로 업데이트되었습니다.\n- 자동 리뷰 기능의 적용 브랜치 설정이 추가되었습니다.\n\n\n\n",
  "active_lock_reason": null,
  "merged": false,
  "mergeable": true,
  "rebaseable": false,
  "mergeable_state": "unstable",
  "merged_by": null,
  "comments": 1,
  "review_comments": 2,
  "maintainer_can_modify": false,
  "commits": 28,
  "additions": 413,
  "deletions": 106,
  "changed_files": 15
}

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