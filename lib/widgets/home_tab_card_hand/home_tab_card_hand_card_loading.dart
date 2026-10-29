// 카드 핸드 표시 카드 관리: 초기 7장 로드, 회전 방향별 3장씩 추가 로드 (왼쪽·오른쪽)
part of '../home_tab_card_hand.dart';

mixin _HomeTabCardHandCardLoading on _HomeTabCardHandStateFields {
  static const int _initialLoadCount = 7; // 초기 로드 개수
  static const int _loadChunkSize = 3; // 한 번에 로드할 카드 개수

  void _generateCards() {
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      _allCards = widget.cards!.toList(); // 전체 카드 저장

      // 초기 7개 카드 로드 (0번째부터 왼쪽으로 채움)
      final totalCards = _allCards.length;
      final initialCount = math.min(_initialLoadCount, totalCards);
      const startIndex = 0;
      final endIndex = initialCount;

      _cards = _allCards.sublist(startIndex, endIndex);
      _leftLoadedCount = startIndex; // 왼쪽에는 로드할 카드 없음
      _rightLoadedCount = totalCards - endIndex;
    } else {
      _allCards = [];
      _cards = [];
      _leftLoadedCount = 0;
      _rightLoadedCount = 0;
    }
  }

  // 왼쪽 방향으로 카드 로드
  bool _loadCardsLeft() {
    if (_leftLoadedCount == 0) return false; // 왼쪽에 더 이상 로드할 카드 없음

    final loadCount = math.min(_loadChunkSize, _leftLoadedCount);
    final newStartIndex = _leftLoadedCount - loadCount;
    final currentEndIndex = _leftLoadedCount + _cards.length;

    _cards = _allCards.sublist(newStartIndex, currentEndIndex);
    _leftLoadedCount = newStartIndex;
    return true;
  }

  // 오른쪽 방향으로 카드 로드
  bool _loadCardsRight() {
    if (_rightLoadedCount == 0) return false; // 오른쪽에 더 이상 로드할 카드 없음

    final loadCount = math.min(_loadChunkSize, _rightLoadedCount);
    final currentStartIndex = _leftLoadedCount;
    final currentEndIndex = _leftLoadedCount + _cards.length;
    final newEndIndex = math.min(_allCards.length, currentEndIndex + loadCount);

    _cards = _allCards.sublist(currentStartIndex, newEndIndex);
    _rightLoadedCount = _allCards.length - newEndIndex;
    return true;
  }
}
