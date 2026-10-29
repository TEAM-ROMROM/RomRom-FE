// 카드 핸드 AI 추천 연출: 추천 카드 앞쪽 재정렬 > 궤도 복귀 + 집결/팬아웃 보간 > float
part of '../home_tab_card_hand.dart';

mixin _HomeTabCardHandAiHighlight on _HomeTabCardHandStateFields {
  /// AI 추천 카드를 덱 앞쪽으로 재정렬하고 애니메이션을 실행한다.
  ///
  /// 동작 순서:
  /// 1. 추천 카드 중 _cards에 없는 것을 _allCards에서 찾아 _cards에 추가
  /// 2. 현재 카드 위치 스냅샷 저장 (_preReorderTransforms)
  /// 3. _cards를 [추천카드..., 나머지...] 순으로 재구성
  /// 4. orbit 중앙 복귀 + 재정렬 보간 동시 시작 (400ms)
  /// 5. 450ms 후 float 애니메이션 시작
  void _reorderForAiHighlight(List<String> highlightedItemIds) {
    if (highlightedItemIds.isEmpty || !mounted) return;
    if (_allCards.isEmpty) return;

    final generation = ++_reorderGeneration;

    // 카드 7장 이상일 때만 카드 재정렬 + 집결/팬아웃 애니메이션 실행
    // 7장 미만이면 카드 순서/위치 변경 없이 그 자리에서 float + glow만 적용
    if (_allCards.length >= 7) {
      // 1. 추천 카드 중 _cards에 없는 것 강제 로드
      var workingCards = List<Item>.from(_cards);
      for (final id in highlightedItemIds) {
        if (!workingCards.any((c) => c.itemId == id)) {
          final idx = _allCards.indexWhere((c) => c.itemId == id);
          if (idx != -1) {
            workingCards.add(_allCards[idx]);
          }
        }
      }

      // 2. _cards 재정렬: 추천 카드 먼저, 나머지 뒤
      final highlighted = workingCards.where((c) => highlightedItemIds.contains(c.itemId)).toList();
      final others = workingCards.where((c) => !highlightedItemIds.contains(c.itemId)).toList();
      final reordered = [...highlighted, ...others];

      // 3. 카드 인덱스(순서) 변화 여부 확인
      final currentIds = workingCards.map((c) => c.itemId).toList();
      final reorderedIds = reordered.map((c) => c.itemId).toList();
      final orderChanged = !listEquals(currentIds, reorderedIds);

      if (orderChanged) {
        // 순서가 바뀔 때만: 현재 위치 스냅샷 저장 → 집결/팬아웃 애니메이션 실행
        final snapshot = <String, CardHandCardTransform>{};
        for (int i = 0; i < workingCards.length; i++) {
          final id = workingCards[i].itemId;
          if (id != null) {
            snapshot[id] = _calculateCardTransform(context, i, workingCards.length);
          }
        }

        // 재정렬 후 _cards가 _allCards의 연속 슬라이스가 아니므로 lazy load 비활성화
        setState(() {
          _preReorderTransforms = snapshot;
          _cards = reordered;
          _leftLoadedCount = 0;
          _rightLoadedCount = 0;
        });

        // orbit → 첫 번째 카드가 화면 왼쪽 끝에 오도록 + 재정렬 보간 동시 시작 (400ms)
        final targetOrbit = _getHighlightOrbitAngle(reordered.length);
        _orbitAccumulated = targetOrbit;
        _orbitController?.animateTo(targetOrbit, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        _reorderAnimController.forward(from: 0.0);

        // 750ms 후 float 시작 (집결+팬아웃 완료 직후)
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!mounted || generation != _reorderGeneration) return;
          _highlightFloatController.forward(from: 0.0);
        });
      } else {
        // 순서 변화 없음: 집결/팬아웃 생략, 그 자리에서 float만 실행
        _highlightFloatController.forward(from: 0.0);
      }
    } else {
      // 7장 미만: 카드 순서/위치 변경 없이 그 자리에서 float만 실행
      _highlightFloatController.forward(from: 0.0);
    }
  }

  /// 재정렬 후 첫 번째 카드(index 0)가 화면 왼쪽 끝에 보이도록 orbit 각도를 역산
  double _getHighlightOrbitAngle(int totalCards) {
    // index 0 카드 왼쪽 끝 ≈ 8w
    return CardHandGeometry.calculateHighlightOrbitAngle(
      layout: _layout,
      screenWidth: MediaQuery.of(context).size.width,
      totalCards: totalCards,
      cardLeftMarginPixels: 8.w,
    );
  }
}
