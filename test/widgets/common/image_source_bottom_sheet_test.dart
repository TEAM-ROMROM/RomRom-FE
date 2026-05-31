import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/widgets/common/image_source_bottom_sheet.dart';

void main() {
  testWidgets('카메라 항목 탭 → ImagePickSource.camera 반환', (tester) async {
    ImagePickSource? result;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => result = await showImageSourceBottomSheet(c),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('사진 촬영하기'), findsOneWidget);
    expect(find.text('앨범에서 선택하기'), findsOneWidget);

    await tester.tap(find.text('사진 촬영하기'));
    await tester.pumpAndSettle();

    expect(result, ImagePickSource.camera);
  });

  testWidgets('앨범 항목 탭 → ImagePickSource.gallery 반환', (tester) async {
    ImagePickSource? result;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (context, child) => MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => result = await showImageSourceBottomSheet(c),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 선택하기'));
    await tester.pumpAndSettle();

    expect(result, ImagePickSource.gallery);
  });
}
