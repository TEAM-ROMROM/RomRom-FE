// 카드 핸드 제스처: 터치 시작 히트테스트·롱프레스, 방향 판별(회전/카드 당김), 드롭존 판정, 놓기(드롭·원위치·관성 회전)
part of '../home_tab_card_hand.dart';

mixin _HomeTabCardHandGestures on _HomeTabCardHandStateFields, _HomeTabCardHandCardLoading {
  static const double _orbitSensitivity = 0.0045;

  Rect? _globalRectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  // 좌표에서 카드 찾기
  // 렌더링은 _cards.reversed로 그려져 index 0이 시각적 최상단(Stack 맨 위)이다.
  // 따라서 index 0부터(=위에 있는 카드부터) 검사해 첫 매치를 반환해야
  // 사용자가 보는 최상단 카드가 선택된다.
  // 전제: hit-test는 _handlePanStart(터치 시작) 시점에 호출되며, 이때 카드는
  // 팬/재정렬/pull 애니메이션이 끝난 정적 상태다. 따라서 _calculateCardTransform의
  // 정적 목표값(보간 전)으로 판정해도 실제 렌더 위치와 일치한다.
  String? _findCardAtPosition(Offset localPosition) {
    for (int i = 0; i < _cards.length; i++) {
      final transform = _calculateCardTransform(context, i, _cards.length);
      // 회전·세로 위치 반영 판정 (CardHandGeometry.isPositionInsideCard)
      if (CardHandGeometry.isPositionInsideCard(position: localPosition, transform: transform, layout: _layout)) {
        return _cards[i].itemId;
      }
    }

    return null;
  }

  // 전체 카드 영역에 대한 제스처 처리
  void _handlePanStart(DragStartDetails details) {
    _panStartPosition = details.localPosition;
    _orbitController?.stop();
    _orbitDragStart = details.localPosition.dx;
    _longPressTimer?.cancel();
    _longPressTimer = null;

    _panStartedOnCard = false;
    _startCardId = null;
    _hasStartedCardDrag = false;

    final cardId = _findCardAtPosition(details.localPosition);
    setState(() => _pressedCardId = cardId);
    if (cardId != null) {
      _panStartedOnCard = true;
      _startCardId = cardId;

      // 0.2초 롱프레스 타이머 시작
      _longPressTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _hasStartedCardDrag = true;
          _hoveredCardId = _startCardId; // 0.2초 경과 후 선택 상태 표시
          _orbitAccumulated = _orbitAngle;
          _orbitDragStart = _panStartPosition.dx;
        });
        HapticFeedback.selectionClick();
      });
    }
  }

  void _handlePanCancel() {
    // 롱프레스 타이머 취소
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (!mounted) return;
    setState(() {
      _panStartedOnCard = false;
      _startCardId = null;
      _hasStartedCardDrag = false;
      _pressedCardId = null;
      _hoveredCardId = null;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // 드래그 변위(손가락 방향과 동일한 부호)
    final dispX = details.localPosition.dx - _panStartPosition.dx; // → 오른쪽 +
    final dispY = details.localPosition.dy - _panStartPosition.dy; // → 아래로 +

    // 방향 조기 판별: 카드 위에서 시작했고 아직 방향 미결정 상태일 때
    // 8px 이상 이동하면 수직/수평 의도를 벡터로 판별 → 타이머 상태 무관하게 판별
    if (_panStartedOnCard && _startCardId != null && !_hasStartedCardDrag) {
      const double directionThreshold = 8.0;
      final double totalDisp = math.sqrt(dispX * dispX + dispY * dispY);
      if (totalDisp >= directionThreshold) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
        // 수직 성분이 수평의 1.5배 이상이면 → 즉시 카드 드래그 모드
        if (dispY.abs() > dispX.abs() * 1.5) {
          setState(() {
            _hasStartedCardDrag = true;
            _hoveredCardId = _startCardId;
            _orbitAccumulated = _orbitAngle;
            _orbitDragStart = _panStartPosition.dx;
          });
        } else {
          // 수평 방향으로 판별 → 카드 드래그 모드 진입 없이 회전 전용
          setState(() => _panStartedOnCard = false);
        }
      }
    }

    // 1) 좌우 = 항상 원호 회전만 (카드 드래그 모드 전까지)
    if (!_hasStartedCardDrag) {
      final double dragDx = details.localPosition.dx - _orbitDragStart;
      final double targetAngle = _orbitAccumulated + (dragDx * _orbitSensitivity);

      final double minAngle = _getMinOrbitAngle();
      final double maxAngle = _getMaxOrbitAngle();
      final double clampedAngle = targetAngle.clamp(minAngle, maxAngle);

      // 각도 갱신 (전체 setState 없이 카드 변환 AnimatedBuilder만 재빌드)
      _orbitAngle = clampedAngle;
      _orbitController?.value = clampedAngle;

      // 각도에 따라 카드 동적 로드 (카드 목록 변경 시에만 전체 재빌드)
      // 왼쪽으로 스와이프 (음수 방향) → 오른쪽 카드 추가 로드
      if (_orbitAngle < _orbitAccumulated - 0.2 && _rightLoadedCount > 0) {
        setState(() {
          if (_loadCardsRight()) {
            // 연속 로드 방지
            _orbitAccumulated = _orbitAngle;
            _orbitDragStart = details.localPosition.dx;
          }
        });
      }
      // 오른쪽으로 스와이프 (양수 방향) → 왼쪽 카드 추가 로드
      if (_orbitAngle > _orbitAccumulated + 0.2 && _leftLoadedCount > 0) {
        setState(() {
          if (_loadCardsLeft()) {
            // 연속 로드 방지
            _orbitAccumulated = _orbitAngle;
            _orbitDragStart = details.localPosition.dx;
          }
        });
      }
    }

    // 2) 카드 드래그는 조건부 (당김 상태 + 드롭존 그림자 갱신, 이벤트당 setState 1회)
    if (_panStartedOnCard && _startCardId != null) {
      if (_hasStartedCardDrag) {
        setState(() {
          _updatePulledCard(dispX, dispY);
          _updateDropZoneShadow();
        });
      }
    }
  }

  /// 카드 당김 갱신: 시작 판정(위로 -15px 초과) > 손가락 변위 반영
  void _updatePulledCard(double dispX, double dispY) {
    // 위로 당길 때 시작(dispY가 음수), 시작 임계치 -15px
    if (_pulledCardId == null && dispY < -15) {
      _pulledCardId = _hoveredCardId;
      _pullOffset = Offset(dispX, dispY);
      _pullController.forward();
      HapticFeedback.mediumImpact();
      _syncDropGuideIconWithPulledCard();
    } else if (_pulledCardId != null) {
      _pullOffset = Offset(dispX, dispY);
    }
  }

  /// 드롭존 overlap 체크 > 그림자 강도 갱신 (진입 시 햅틱)
  void _updateDropZoneShadow() {
    final deckBox = _deckKey.currentContext?.findRenderObject() as RenderBox?;
    final dropRect = _globalRectOf(_dropZoneKey);
    if (deckBox == null || dropRect == null || _pulledCardId == null) return;

    // 현재 카드의 위치 계산
    final cardIndex = _cards.indexWhere((card) => card.itemId == _pulledCardId);
    if (cardIndex == -1) return;

    final transform = _calculateCardTransform(context, cardIndex, _cards.length);

    // 카드의 실제 위치 계산 (pull 효과 포함)
    final cardTopLeft = CardHandGeometry.calculatePulledCardTopLeft(
      layout: _layout,
      transform: transform,
      pullOffset: _pullOffset,
      pullProgress: _pullAnimation.value,
    );

    // 카드의 글로벌 위치
    final cardGlobalTopLeft = deckBox.localToGlobal(cardTopLeft);

    // 카드의 전체 영역 (Rect)
    final cardRect = cardGlobalTopLeft & Size(_layout.cardWidth, _layout.cardHeight);

    // 드롭존과 카드 영역이 겹치는지 체크
    final isOver = dropRect.overlaps(cardRect);

    if (isOver && !_wasOverDropZone) {
      HapticFeedback.selectionClick(); // 드롭존 진입시 손맛
    }
    _wasOverDropZone = isOver;

    // 스무딩(선형 보간)
    _dropShadowT = CardHandGeometry.calculateNextDropShadowStrength(
      currentStrength: _dropShadowT,
      isOverDropZone: isOver,
    );
  }

  /// 드롭 안내 아이콘 반복: 카드 당김 중에만 위아래 반복, 해제 시 정지 + 시작 위치 복귀
  void _syncDropGuideIconWithPulledCard() {
    final bool isCardPulled = _pulledCardId != null;
    if (isCardPulled && !_iconAnimationController.isAnimating) {
      _iconAnimationController.repeat(reverse: true);
    } else if (!isCardPulled) {
      _iconAnimationController
        ..stop()
        ..value = 0.0;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    // 롱프레스 타이머 취소
    _longPressTimer?.cancel();
    _longPressTimer = null;

    final bool draggedCard = _hasStartedCardDrag;
    if (_hasStartedCardDrag) {
      if (_pulledCardId != null && _wasOverDropZone) {
        // 드롭 발생 - 드롭존에 들어갔었다면 드롭 허용
        if (widget.onCardDrop != null) {
          widget.onCardDrop!(_pulledCardId!);
          HapticFeedback.heavyImpact();
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {
            _pulledCardId = null;
            _pullOffset = Offset.zero;
            _dropShadowT = 0.0; // 그림자 원복
            _wasOverDropZone = false;
          });
          _syncDropGuideIconWithPulledCard();
          _pullController.reverse();
        });
      } else {
        // 원위치
        _pullController.reverse().then((_) {
          if (!mounted) return;
          setState(() {
            _pulledCardId = null;
            _pullOffset = Offset.zero;
          });
          _syncDropGuideIconWithPulledCard();
        });
      }
    }

    if (!draggedCard) {
      _orbitAccumulated = _orbitAngle;
      final double horizontalVelocity = details.velocity.pixelsPerSecond.dx;
      // 속도 임계값을 낮춰서 짧은 스와이프도 감지
      if (horizontalVelocity.abs() > 5) {
        final double minAngle = _getMinOrbitAngle();
        final double maxAngle = _getMaxOrbitAngle();

        // 현재 각속도로 계산해서 경계를 넘을지 미리 확인
        // 방향을 _handlePanUpdate와 일치시킴
        final double angularVelocity = horizontalVelocity * _orbitSensitivity;

        // 이미 경계 근처면 무시
        if ((_orbitAngle <= minAngle && angularVelocity < 0) || (_orbitAngle >= maxAngle && angularVelocity > 0)) {
          _orbitController?.value = _orbitAngle;
          return;
        }

        final simulation = FrictionSimulation(0.12, _orbitAngle, angularVelocity);

        late VoidCallback bounceListener;
        bounceListener = () {
          final currentValue = _orbitController?.value ?? _orbitAngle;

          // 경계 넘어가려고 하면 멈추기
          if (currentValue < minAngle || currentValue > maxAngle) {
            _orbitController?.stop();
            _orbitController?.value = currentValue.clamp(minAngle, maxAngle);
            _orbitAccumulated = _orbitController?.value ?? _orbitAngle;
            _orbitController?.removeListener(bounceListener);
          }
        };

        _orbitController?.addListener(bounceListener);
        _orbitController?.animateWith(simulation).whenComplete(() {
          if (!mounted) return;
          _orbitController?.removeListener(bounceListener);
          final clampedValue = (_orbitController?.value ?? _orbitAngle).clamp(minAngle, maxAngle);
          _orbitController?.value = clampedValue;
          _orbitAccumulated = clampedValue;
        });
      } else {
        _orbitController?.value = _orbitAngle;
      }
    }

    // 플래그/선택 해제
    setState(() {
      _panStartedOnCard = false;
      _startCardId = null;
      _hasStartedCardDrag = false;
      _hoveredCardId = null;
      _pressedCardId = null;
      _panStartPosition = Offset.zero;
    });
  }
}
