# #975 성능 개선 1단계 구현 계획

설계: `docs/superpowers/specs/2026-11-03-issue-975-performance-phase1-design.md`

각 Task는 로직 테스트 먼저 > 구현 > 해당 테스트 통과 순서. 마지막에 `dart format --line-length=120 .` > `flutter analyze` > `flutter test`.

| # | Task | 파일 | 테스트 |
|---|---|---|---|
| 1 | 동시 실행 제한 유틸 | `lib/utils/concurrency_limiter.dart` | `test/utils/concurrency_limiter_test.dart` (최대 동시 수, FIFO, 실패 시 슬롯 반환, 동기 예외) |
| 2 | 압축 동시 2개 | `lib/utils/image_compressor.dart` | 기존 `image_compressor_test.dart` + 상수 검증 |
| 3 | 디코딩 크기 유틸 | `lib/utils/image_decode_size.dart` | `test/utils/image_decode_size_test.dart` |
| 4 | 이미지 캐시 매니저 | `lib/services/app_image_cache_manager.dart`, `pubspec.yaml` (flutter_cache_manager 직접 의존 명시) | `cached_image_test.dart`에서 cacheManager 전달 확인 |
| 5 | CachedImage 레이아웃 기반 디코딩 | `lib/widgets/common/cached_image.dart` | `cached_image_test.dart` (크기 없음·무한대·IntrinsicHeight 안·전체 해상도) |
| 6 | 채팅 셀·아바타·등록 썸네일·전체 보기·크롭 | `chat_image_bubble.dart`, `user_profile_circular_avatar.dart`, `register_image_picker_section.dart`, `image_fullscreen_viewer.dart`, `profile_image_crop_screen.dart` | 셀 decode 크기 위젯 테스트 |
| 7 | 주소 디스크 캐시·동시 제한 | `lib/services/address_lookup_persistent_store.dart`, `lib/services/address_lookup_cache.dart`, `lib/enums/storage_keys.dart` | `address_lookup_cache_test.dart` 추가, `address_lookup_persistent_store_test.dart` |
| 8 | 토큰 메모리 캐시 | `lib/services/token_manager.dart` | `test/services/token_manager_test.dart` |
| 9 | 회원 캐시 정리 | `lib/services/member_manager_service.dart` | analyze (호출부 API 유지) |
| 10 | 미사용 provider 삭제 | `lib/utils/item_card_scale_utils.dart`, `test/architecture/user_scoped_providers_rule_test.dart` | 규칙 테스트 |
| 11 | 등장 지연 상한 | `lib/widgets/common/app_fade_slide_in.dart`, `lib/models/app_motion.dart` | `test/widgets/common/app_fade_slide_in_test.dart` |
| 12 | 웹소켓 회원 변경 시 재연결 | `lib/services/chat_websocket_service.dart` | `test/services/chat_websocket_service_test.dart` |
