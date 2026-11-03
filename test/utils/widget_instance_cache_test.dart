import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/widget_instance_cache.dart';

/// 위젯 인스턴스 재사용: 입력 같으면 같은 인스턴스(생성 함수 호출 안 함), 하나라도 다르면 새로 생성
void main() {
  late WidgetInstanceCache<Widget> widgetCache;
  late int buildCallCount;

  Widget buildCounted(String label) {
    buildCallCount++;
    return Text(label);
  }

  setUp(() {
    widgetCache = WidgetInstanceCache<Widget>();
    buildCallCount = 0;
  });

  test('입력 같음 > 이전 인스턴스 그대로, 생성 1회', () {
    final firstWidget = widgetCache.resolve(['닉네임', true], () => buildCounted('a'));
    final secondWidget = widgetCache.resolve(['닉네임', true], () => buildCounted('b'));

    expect(secondWidget, same(firstWidget));
    expect(buildCallCount, 1);
  });

  test('입력 하나 바뀜 > 새 인스턴스', () {
    final firstWidget = widgetCache.resolve(['닉네임', true], () => buildCounted('a'));
    final secondWidget = widgetCache.resolve(['닉네임', false], () => buildCounted('b'));

    expect(secondWidget, isNot(same(firstWidget)));
    expect(buildCallCount, 2);
  });

  test('입력 목록 수정해도 캐시 입력은 그대로 (복사 보관)', () {
    final dependencies = <Object?>['닉네임'];
    widgetCache.resolve(dependencies, () => buildCounted('a'));
    dependencies[0] = '바뀐 닉네임';

    widgetCache.resolve(['닉네임'], () => buildCounted('b'));

    expect(buildCallCount, 1);
  });
}
