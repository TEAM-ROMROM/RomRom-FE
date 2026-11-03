import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/widgets/chat_image_bubble.dart';

import '../helpers/pump_design_screen.dart';

/// 채팅 이미지 묶음 셀 디코딩 크기 검증: 셀 크기 기준 (원본 디코딩 아님), 앱 이미지 캐시 사용
void main() {
  testWidgets('사진 4장 > 셀(131x131) 기준 131 x 1.8 = 236, 원본 디코딩 없음', (tester) async {
    useDesignScreenView(tester);
    final message = ChatMessage(
      chatMessageId: 'message-1',
      imageUrls: [for (var index = 0; index < 4; index++) 'https://example.com/photo_$index.jpg'],
    );

    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Center(child: Builder(builder: (context) => chatImageBubble(context, message))),
        ),
      ),
    );

    final cellImages = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).toList();
    expect(cellImages, hasLength(4));
    for (final cellImage in cellImages) {
      expect(cellImage.memCacheWidth, 236);
      expect(cellImage.memCacheHeight, isNull);
      expect(cellImage.cacheManager, same(AppImageCacheManager.instance));
    }
  });

  group('photoGridCellSize (셀 표시 크기, 그리드 배치와 같은 규칙)', () {
    const bubbleWidth = 264.0;
    const gap = 2.0;
    const halfSide = (bubbleWidth - gap) / 2;
    const thirdSide = (bubbleWidth - gap * 2) / 3;

    test('1장 > 버블 정사각형', () {
      expect(photoGridCellSize(photoCount: 1, index: 0, width: bubbleWidth, gap: gap), const Size(264, 264));
    });

    test('3장 > 왼쪽 세로로 긴 셀, 오른쪽 정사각형 2개', () {
      expect(photoGridCellSize(photoCount: 3, index: 0, width: bubbleWidth, gap: gap), const Size(halfSide, 264));
      expect(photoGridCellSize(photoCount: 3, index: 2, width: bubbleWidth, gap: gap), const Size(halfSide, halfSide));
    });

    test('5장 > 첫 줄 2칸(가로 절반·높이 1/3), 둘째 줄 3칸', () {
      expect(photoGridCellSize(photoCount: 5, index: 1, width: bubbleWidth, gap: gap), const Size(halfSide, thirdSide));
      expect(
        photoGridCellSize(photoCount: 5, index: 4, width: bubbleWidth, gap: gap),
        const Size(thirdSide, thirdSide),
      );
    });

    test('10장 > 마지막 두 줄 2칸', () {
      expect(
        photoGridCellSize(photoCount: 10, index: 5, width: bubbleWidth, gap: gap),
        const Size(thirdSide, thirdSide),
      );
      expect(
        photoGridCellSize(photoCount: 10, index: 9, width: bubbleWidth, gap: gap),
        const Size(halfSide, thirdSide),
      );
    });
  });
}
