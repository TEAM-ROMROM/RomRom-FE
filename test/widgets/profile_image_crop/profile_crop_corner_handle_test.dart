import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/profile_image_crop/profile_crop_corner_handle.dart';

void main() {
  group('ProfileCropCornerHandle', () {
    testWidgets('드래그: 시작 1회 > 이동 이벤트 전달 > 종료 1회', (tester) async {
      int dragStartCount = 0;
      int dragEndCount = 0;
      Offset totalDragDelta = Offset.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileCropCornerHandle(
                isLeftCorner: true,
                isTopCorner: true,
                onDragStart: () => dragStartCount++,
                onDragUpdate: (details) => totalDragDelta += details.delta,
                onDragEnd: () => dragEndCount++,
              ),
            ),
          ),
        ),
      );

      // 터치 영역 40px 고정
      expect(tester.getSize(find.byType(ProfileCropCornerHandle)), const Size(40, 40));

      await tester.drag(find.byType(ProfileCropCornerHandle), const Offset(30, 20));
      await tester.pump();

      expect(dragStartCount, 1);
      expect(dragEndCount, 1);
      expect(totalDragDelta.dx, greaterThan(0));
      expect(totalDragDelta.dy, greaterThan(0));
    });
  });
}
