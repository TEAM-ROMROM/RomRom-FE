# 채팅 편의 기능 설계 (#987)

서버 변경 없음. 기존 메시지 조회·이미지 업로드·소켓 전송 API 재사용.

## 1. 맨 아래로 버튼 · 새 메시지 알림
- 기준 하나: `nearBottomAutoScrollThresholdPixels`(120px)를 `isNearBottom()`으로 감싸 자동 스크롤과 버튼이 공유
- 스크롤 리스너 > 맨 아래에서 멀어지면 버튼, 돌아오면 숨김·개수 0
- 수신 시 자동 스크롤 안 된 상대 메시지만 +1 (`countUnseenIncomingMessages`) > `새 메시지 N`(99+) 알약
- 탭 > 개수 0 > 기존 `_scrollToBottom()`

## 2. 안 읽은 곳 이동 · '여기까지 읽었어요'
- 데이터: 채팅 목록 `ChatRoomDetailDto.unreadCount` (내 읽음 커서 API 없음)
  - 목록은 진입 직전 0으로 바꿈 > `ChatRoomScreen.unreadCountAtEntry`로 전달, 없으면(푸시 진입) initState 때 목록 상태에서 조회
- 판정: 진입 조회 최신 메시지부터 상대 메시지 N번째 = 첫 안 읽음 (내·로컬 메시지 제외, 조회 뒤 실시간 수신분 제외)
- 못 찾으면 이전 페이지 최대 3번 더 조회, 그래도 없으면 구분선 없이 맨 아래
- 이동: `scrollReverseListToKeyedItem` > 렌더 전이면 한 화면씩 위로 > `ensureVisible(alignment 0.85)`
- 숨김: 내가 메시지를 보내면(`_addLocalMessage`) 해제, 방을 나가면 화면 상태와 함께 사라짐

## 3. 사진
- 저장: 전체 보기(photo_viewer) `overlayBuilder`에 저장 버튼, `onPageChanged`로 현재 장 추적
  - `ChatImageGallerySaver`: 권한 확인 > 없으면 요청 1회 > 캐시 원본 파일 > JPEG(Q95) 변환 > `gal` 저장
  - JPEG 변환 이유: 서버 사진은 webp > 사진 앱 호환
  - 결과 enum `ChatImageSaveResult` > 성공·실패 토스트, 권한 거부 > `설정 열기` 모달 (재요청 반복 없음)
- 카메라: 첨부 메뉴 `사진 찍기` > 기존 `ensureCameraPermission`(탭 시점만 요청, 영구 거부 시 설정 안내) > `ImageSource.camera`
- 미리보기: 앨범·카메라 모두 `showChatImageSendPreviewSheet` > X로 빼기 > 보내기 (모두 빼면 닫힘 = 전송 안 함)
  - 최대 10장, 업로드·압축은 기존 흐름(`ImageCompressor.toWebp` > `uploadImages`) 그대로

### 패키지 선택: gal 2.3
- 2023~ 유지보수 중, iOS 추가 전용 권한(`NSPhotoLibraryAddUsageDescription`)만 사용
- Android 10+ MediaStore 저장 > 저장소 권한 요청 없음, 9 이하만 `WRITE_EXTERNAL_STORAGE`(maxSdk 29)
- 대안 `image_gallery_saver`는 장기간 업데이트 없음 > 제외

### 권한 문구
- `NSPhotoLibraryAddUsageDescription`: 채팅에서 받은 사진을 내 사진 앨범에 저장하기 위해 사용합니다.
- `NSCameraUsageDescription`: 교환할 물건의 사진을 직접 촬영해 게시글에 등록하거나 채팅으로 보내기 위해 카메라를 사용합니다.

## 4. 입력 편의
- 임시 저장: `chatInputDraftProvider`(Notifier, `Map<chatRoomId, text>`), `userScopedProviders` 등록 > 로그아웃 초기화
  - 메모리만 보관: 개인 대화 내용 기기 잔존 방지, 앱 실행 중 방 이동이 주 사용 사례
  - 입력마다 저장(빈 글 삭제), initState에서 복원 > dispose 중 provider 변경 없음
- 빠른 답장: 문구 원본 `lib/models/chat_quick_replies.dart`, 빈 입력·포커스·입력 가능 때 입력창 위 노출, 탭 > 넣기만
- 연결 상태: `ChatWebSocketService.connectionStatus`(`ValueListenable<bool>`, 기존 `_isConnected` 원본을 ValueNotifier로)
  - `ChatConnectionBanner`: 끊김 1초 이상 지속 시 `연결 중…`, 연결되면 즉시 숨김 (진입·순간 재연결 깜빡임 방지)

## 테스트
- 규칙: 새 메시지 수·근처 판정, 첫 안 읽음 위치·추가 조회 한도, 빠른 답장 노출·넣기
- provider: 방별 임시 저장·빈 글 삭제·로그아웃 초기화
- 서비스: 저장 권한 허용·거부·예외(가짜 `GalleryImageWriter`), 소켓 연결 상태 알림
- 위젯: 연결 띠 대기·숨김, 맨 아래로 버튼, 빠른 답장 넣기, 미리보기 빼기·보내기, 저장 버튼 결과·중복 방지, 구분선 위치·먼 구분선 이동

## 하지 않는 것
- 서버 읽음 커서 API 추가, 임시 저장 기기 영구 저장, 빠른 답장 사용자 편집
