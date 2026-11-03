import 'package:flutter/widgets.dart';

/// IndexedStack 지연 생성: 처음 선택된 탭(+ [eagerIndices])만 만들고, 한 번 만든 탭은 상태 유지
/// 만들지 않은 탭 자리는 빈 위젯 (시작 시 모든 탭이 동시에 조회하는 것 방지)
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    this.eagerIndices = const {},
  });

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  // 선택 전이라도 바로 만들 탭 (실시간 구독 등 백그라운드 역할이 있는 탭)
  final Set<int> eagerIndices;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  // 만든 탭 위젯 (같은 인스턴스 유지 > 부모 재빌드 때 탭 재빌드 방지)
  final Map<int, Widget> _createdTabByIndex = {};

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [for (var tabIndex = 0; tabIndex < widget.itemCount; tabIndex++) _buildTabIfNeeded(context, tabIndex)],
    );
  }

  /// 선택·즉시 생성 대상이면 만들어 보관, 아니면 이미 만든 탭 또는 빈 자리
  Widget _buildTabIfNeeded(BuildContext context, int tabIndex) {
    final shouldCreate = tabIndex == widget.index || widget.eagerIndices.contains(tabIndex);
    if (shouldCreate) return _createdTabByIndex.putIfAbsent(tabIndex, () => widget.itemBuilder(context, tabIndex));
    return _createdTabByIndex[tabIndex] ?? const SizedBox.shrink();
  }
}
