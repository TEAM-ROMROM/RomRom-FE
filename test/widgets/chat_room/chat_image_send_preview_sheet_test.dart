import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/chat_room/chat_image_send_preview_sheet.dart';
import '../../helpers/pump_design_screen.dart';

/// 사진 미리보기 시트 (#987): X로 빼기, 보내기 > 남은 사진만, 모두 빼기·닫기 > 전송 안 함(null)
void main() {
  final images = [XFile('/tmp/a.jpg'), XFile('/tmp/b.jpg'), XFile('/tmp/c.jpg')];

  /// 시트 열기 버튼 화면 > 탭 > 시트 결과 기록
  Future<List<List<XFile>?>> openPreviewSheet(WidgetTester tester, List<XFile> pickedImages) async {
    useDesignScreenView(tester);
    final sheetResults = <List<XFile>?>[];
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  sheetResults.add(await showChatImageSendPreviewSheet(context: context, images: pickedImages)),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return sheetResults;
  }

  testWidgets('가운데 사진 빼기 > 2장 표시 > 보내기 > 남은 사진 순서대로', (tester) async {
    final sheetResults = await openPreviewSheet(tester, images);
    expect(find.text('사진 3장'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.cancel).at(1));
    await tester.pump();
    expect(find.text('사진 2장'), findsOneWidget);

    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(sheetResults.single!.map((image) => image.path), ['/tmp/a.jpg', '/tmp/c.jpg']);
  });

  testWidgets('마지막 사진 빼기 > 시트 닫힘, 전송 안 함', (tester) async {
    final sheetResults = await openPreviewSheet(tester, [images.first]);

    await tester.tap(find.byIcon(AppIcons.cancel));
    await tester.pumpAndSettle();

    expect(find.text('보내기'), findsNothing);
    expect(sheetResults.single, isNull);
  });
}
