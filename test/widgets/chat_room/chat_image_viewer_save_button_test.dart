import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_image_save_result.dart';
import 'package:romrom_fe/providers/chat_image_gallery_saver_provider.dart';
import 'package:romrom_fe/services/chat_image_gallery_saver.dart';
import 'package:romrom_fe/widgets/chat_room/chat_image_viewer_save_button.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import '../../helpers/pump_design_screen.dart';

/// 가짜 저장: 지정 결과 반환 (완료 대기 가능), 저장 요청 주소 기록
class FakeChatImageGallerySaver implements ChatImageGallerySaver {
  FakeChatImageGallerySaver(this.saveResult);

  final ChatImageSaveResult saveResult;
  final List<String> requestedImageUrls = [];
  Completer<void>? pendingSave;

  @override
  Future<ChatImageSaveResult> saveNetworkImage(String imageUrl) async {
    requestedImageUrls.add(imageUrl);
    await pendingSave?.future;
    return saveResult;
  }
}

/// 전체 보기 저장 버튼 (#987): 현재 장 저장, 권한 거부 > 설정 열기 안내(채팅 계속), 저장 중 중복 탭 무시
void main() {
  Future<void> pumpSaveButton(
    WidgetTester tester, {
    required FakeChatImageGallerySaver fakeSaver,
    required PhotoViewerPageTracker pageTracker,
  }) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatImageGallerySaverProvider.overrideWithValue(fakeSaver)],
        child: buildDesignScreenApp(
          home: Scaffold(
            body: ChatImageViewerSaveButton(imageUrls: const ['https://a', 'https://b'], pageTracker: pageTracker),
          ),
        ),
      ),
    );
  }

  testWidgets('넘긴 장(2번째) 저장 > 저장 완료 토스트', (tester) async {
    final fakeSaver = FakeChatImageGallerySaver(ChatImageSaveResult.saved);
    final pageTracker = PhotoViewerPageTracker(currentPageIndex: 0);
    await pumpSaveButton(tester, fakeSaver: fakeSaver, pageTracker: pageTracker);

    pageTracker.currentPageIndex = 1;
    await tester.tap(find.byType(AppPressable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(fakeSaver.requestedImageUrls, ['https://b']);
    expect(find.text('사진을 앨범에 저장했어요.'), findsOneWidget);
    // 토스트 자동 닫힘 타이머 소진
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('권한 거부 > 설정 열기 안내 모달, 취소하면 닫힘', (tester) async {
    final fakeSaver = FakeChatImageGallerySaver(ChatImageSaveResult.permissionDenied);
    await pumpSaveButton(tester, fakeSaver: fakeSaver, pageTracker: PhotoViewerPageTracker(currentPageIndex: 0));

    await tester.tap(find.byType(AppPressable));
    await tester.pumpAndSettle();

    expect(find.text('설정 열기'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('설정 열기'), findsNothing);
  });

  testWidgets('저장 중 다시 탭 > 저장 요청 1번', (tester) async {
    final fakeSaver = FakeChatImageGallerySaver(ChatImageSaveResult.failed)..pendingSave = Completer<void>();
    await pumpSaveButton(tester, fakeSaver: fakeSaver, pageTracker: PhotoViewerPageTracker(currentPageIndex: 0));

    await tester.tap(find.byType(AppPressable));
    await tester.pump();
    await tester.tap(find.byType(AppPressable));
    await tester.pump();
    expect(fakeSaver.requestedImageUrls, hasLength(1));

    fakeSaver.pendingSave!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('사진을 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
