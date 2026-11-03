import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/range_slider_widget.dart';

void main() {
  group('searchRangeIndexForRadius', () {
    test('반경 이하인 가장 가까운 범위 index (경계 포함)', () {
      expect(searchRangeIndexForRadius(1000), 0);
      expect(searchRangeIndexForRadius(2500), 0);
      expect(searchRangeIndexForRadius(2501), 1);
      expect(searchRangeIndexForRadius(5000), 1);
      expect(searchRangeIndexForRadius(7500), 2);
      expect(searchRangeIndexForRadius(10000), 3);
    });

    test('10km 초과 > 가장 넓은 범위 (2.5km로 줄여 보이지 않음)', () {
      expect(searchRangeIndexForRadius(15000), defaultSearchRangeOptions.length - 1);
    });
  });
}
