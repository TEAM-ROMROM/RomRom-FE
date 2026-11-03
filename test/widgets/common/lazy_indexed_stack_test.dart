import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/lazy_indexed_stack.dart';

/// 생성 횟수 기록 탭 (initState 1회 = 생성 1회)
class _CountingTab extends StatefulWidget {
  const _CountingTab({required this.tabIndex, required this.createdCountByIndex});

  final int tabIndex;
  final Map<int, int> createdCountByIndex;

  @override
  State<_CountingTab> createState() => _CountingTabState();
}

class _CountingTabState extends State<_CountingTab> {
  @override
  void initState() {
    super.initState();
    widget.createdCountByIndex.update(widget.tabIndex, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text('tab-${widget.tabIndex}');
}

/// 탭 지연 생성: 선택·즉시 생성 탭만 만들고, 한 번 만든 탭은 유지
void main() {
  late Map<int, int> createdCountByIndex;

  Widget buildStack({required int selectedIndex, Set<int> eagerIndices = const {}}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LazyIndexedStack(
        index: selectedIndex,
        itemCount: 5,
        eagerIndices: eagerIndices,
        itemBuilder: (context, tabIndex) => _CountingTab(tabIndex: tabIndex, createdCountByIndex: createdCountByIndex),
      ),
    );
  }

  setUp(() => createdCountByIndex = {});

  testWidgets('시작: 선택 탭 + 즉시 생성 탭만 만듦', (tester) async {
    await tester.pumpWidget(buildStack(selectedIndex: 0, eagerIndices: const {3}));

    expect(createdCountByIndex, {0: 1, 3: 1});
  });

  testWidgets('처음 선택한 탭은 그때 만들고, 다른 탭 갔다 와도 다시 만들지 않음', (tester) async {
    await tester.pumpWidget(buildStack(selectedIndex: 0));
    await tester.pumpWidget(buildStack(selectedIndex: 2));
    await tester.pumpWidget(buildStack(selectedIndex: 0));
    await tester.pumpWidget(buildStack(selectedIndex: 2));

    expect(createdCountByIndex, {0: 1, 2: 1});
    expect(find.text('tab-2'), findsOneWidget);
  });
}
