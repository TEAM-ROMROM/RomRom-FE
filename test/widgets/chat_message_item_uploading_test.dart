import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/widgets/chat_message_item.dart';

import '../helpers/pump_design_screen.dart';

/// 업로드 중 사진 말풍선: 압축 전 원본 대신 셀 표시 크기로 디코딩 (서버 이미지 셀과 같은 크기)
void main() {
  Future<List<Image>> pumpUploadingBubble(WidgetTester tester, {required int photoCount}) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageItem(
              message: ChatMessage(
                chatMessageId: 'local-image-1',
                senderId: 'me',
                type: MessageType.image,
                imageUrls: [for (var index = 0; index < photoCount; index++) '/tmp/photo_$index.jpg'],
              ),
              myMemberId: 'me',
              topGap: 0,
              showTime: false,
              isUploading: true,
              opponentNickname: '상대',
            ),
          ),
        ),
      ),
    );
    return tester.widgetList<Image>(find.byType(Image)).toList();
  }

  testWidgets('사진 4장 > 셀(131x131) 기준 131 x 1.8 = 236 폭으로 디코딩', (tester) async {
    final cellImages = await pumpUploadingBubble(tester, photoCount: 4);

    expect(cellImages, hasLength(4));
    for (final cellImage in cellImages) {
      final imageProvider = cellImage.image;
      expect(imageProvider, isA<ResizeImage>());
      expect((imageProvider as ResizeImage).width, 236);
      expect(imageProvider.height, isNull);
    }
  });

  testWidgets('사진 1장 > 말풍선 폭(264) x 1.8 = 475 폭으로 디코딩', (tester) async {
    final cellImages = await pumpUploadingBubble(tester, photoCount: 1);

    expect((cellImages.single.image as ResizeImage).width, 475);
  });
}
