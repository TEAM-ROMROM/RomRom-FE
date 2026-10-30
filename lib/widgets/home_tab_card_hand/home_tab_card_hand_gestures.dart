// 카드 핸드 제스처: 터치 시작 히트테스트·롱프레스, 방향 판별(회전/카드 당김), 드롭존 판정, 놓기(드롭·spring 복귀·관성 회전)
part of '../home_tab_card_hand.dart';

mixin _HomeTabCardHandGestures on _HomeTabCardHandStateFields, _HomeTabCardHandCardLoading {
  // 가로 드래그 1px당 궤도 회전량 (라디안)
  static const double _orbitSensitivity = 0.0045;

  // 카드 선택(확대) 판정까지 누르고 있는 시간
  static const Duration _cardSelectHoldDuration = Duration(milliseconds: 200);

  // 방향 판별 시작 이동 거리 (px) / 수직 판정: 세로 이동이 가로의 1.5배 초과
  static const double _directionDecisionThresholdPixels = 8.0;
  static const double _verticalDominanceRatio = 1.5;

  // 카드 뽑기 시작: 위로 15px 초과
  static const double _pullStartThresholdPixels = 15.0;

  // 회전 누적이 이 각도(라디안)를 넘으면 다음 카드 묶음 로드
  static const double _lazyLoadOrbitAngleRadians = 0.2;

  // 관성 회전 최소 속도 (px/s) / 관성 마찰 계수
  static const double _orbitFlingMinimumVelocityPixelsPerSecond = 5.0;
  static const double _orbitFlingFrictionDrag = 0.12;

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
    // 관성 회전 중 잡으면 그 자리에서 멈추고 이어서 회전 (기준 각도 갱신으로 점프 방지)
    _orbitController?.stop();
    _orbitAccumulated = _orbitAngle;
    _orbitDragStart = details.localPosition.dx;
    _longPressTimer?.cancel();
    _longPressTimer = null;

    _panStartedOnCard = false;
    _startCardId = null;
    _hasStartedCardDrag = false;

    // 놓은 카드가 덱으로 돌아가는 중에는 새 카드 선택 없이 회전만
    final cardId = _isPulledCardReturning ? null : _findCardAtPosition(details.localPosition);
    setState(() => _pressedCardId = cardId);
    if (cardId != null) {
      _panStartedOnCard = true;
      _startCardId = cardId;

      // 롱프레스 타이머 시작
      _longPressTimer = Timer(_cardSelectHoldDuration, () {
        if (!mounted) return;
        setState(() {
          _hasStartedCardDrag = true;
          _hoveredCardId = _startCardId; // 롱프레스 경과 후 선택 상태 표시
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
    // 임계 거리 이상 이동하면 수직/수평 의도를 벡터로 판별 → 타이머 상태 무관하게 판별
    if (_panStartedOnCard && _startCardId != null && !_hasStartedCardDrag) {
      final double totalDisp = math.sqrt(dispX * dispX + dispY * dispY);
      if (totalDisp >= _directionDecisionThresholdPixels) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
        // 수직 성분이 우세하면 → 즉시 카드 드래그 모드
        if (dispY.abs() > dispX.abs() * _verticalDominanceRatio) {
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
      _rotateOrbitByDrag(details.localPosition.dx);
    }

    // 2) 카드 드래그: 뽑기 시작만 전체 재빌드, 이후 변위는 컨트롤러 값만 갱신 (뽑힌 카드만 재빌드)
    if (_panStartedOnCard && _startCardId != null && _hasStartedCardDrag) {
      final bool canStartPull = _pulledCardId == null && dispY < -_pullStartThresholdPixels;
      if (canStartPull) {
        setState(() => _startPull(dispX, dispY));
      } else if (_pulledCardId != null) {
        _pullOffsetXController.value = dispX;
        _pullOffsetYController.value = dispY;
      }
      _updateDropZoneHighlight();
    }
  }

  /// 손가락 가로 위치 > 궤도 각도 (min~max 제한) > 회전 누적 시 카드 추가 로드
  void _rotateOrbitByDrag(double fingerPositionX) {
    final double dragDx = fingerPositionX - _orbitDragStart;
    final double targetAngle = _orbitAccumulated + (dragDx * _orbitSensitivity);
    final double clampedAngle = targetAngle.clamp(_getMinOrbitAngle(), _getMaxOrbitAngle());

    // 각도 갱신 (전체 setState 없이 카드 변환 AnimatedBuilder만 재빌드)
    _orbitAngle = clampedAngle;
    _orbitController?.value = clampedAngle;

    // 각도에 따라 카드 동적 로드 (카드 목록 변경 시에만 전체 재빌드)
    // 왼쪽으로 스와이프 (음수 방향) → 오른쪽 카드 추가 로드
    if (_orbitAngle < _orbitAccumulated - _lazyLoadOrbitAngleRadians && _rightLoadedCount > 0) {
      setState(() {
        if (_loadCardsRight()) {
          // 연속 로드 방지
          _orbitAccumulated = _orbitAngle;
          _orbitDragStart = fingerPositionX;
        }
      });
    }
    // 오른쪽으로 스와이프 (양수 방향) → 왼쪽 카드 추가 로드
    if (_orbitAngle > _orbitAccumulated + _lazyLoadOrbitAngleRadians && _leftLoadedCount > 0) {
      setState(() {
        if (_loadCardsLeft()) {
          // 연속 로드 방지
          _orbitAccumulated = _orbitAngle;
          _orbitDragStart = fingerPositionX;
        }
      });
    }
  }

  /// 카드 뽑기 시작: 손가락 변위 기록 (시작 지연분은 떠오르는 동안 해소) > 떠오름 곡선 시작 > 햅틱
  void _startPull(double dispX, double dispY) {
    _pulledCardId = _hoveredCardId;
    _isPulledCardReturning = false;
    _pullStartLagOffset = Offset(dispX, dispY);
    _pullOffsetXController.value = dispX;
    _pullOffsetYController.value = dispY;
    _pullController.animateTo(1.0, duration: CardHandMotion.pullLiftDuration, curve: AppMotion.decelerate);
    HapticFeedback.mediumImpact();
    _syncDropGuideIconWithPulledCard();
  }

  /// 드롭존 overlap 체크 > 진입·이탈 시 그림자 강도 전환 (진입 시 햅틱)
  void _updateDropZoneHighlight() {
    final deckBox = _deckKey.currentContext?.findRenderObject() as RenderBox?;
    final dropRect = _globalRectOf(_dropZoneKey);
    if (deckBox == null || dropRect == null || _pulledCardId == null) return;

    // 현재 카드의 위치 계산
    final cardIndex = _cards.indexWhere((card) => card.itemId == _pulledCardId);
    if (cardIndex == -1) return;

    final transform = _calculateCardTransform(context, cardIndex, _cards.length);

    // 카드의 실제 위치 계산 (화면에 그린 위치와 동일: 손가락 추종 변위 + 떠오름)
    final cardTopLeft = CardHandGeometry.calculatePulledCardTopLeft(
      layout: _layout,
      transform: transform,
      pullOffset: _calculateVisiblePullOffset(),
      pullProgress: _pullAnimation.value,
      isPullOffsetFollowingFinger: true,
    );

    // 카드의 글로벌 위치
    final cardGlobalTopLeft = deckBox.localToGlobal(cardTopLeft);

    // 카드의 전체 영역 (Rect)
    final cardRect = cardGlobalTopLeft & Size(_layout.cardWidth, _layout.cardHeight);

    // 드롭존과 카드 영역이 겹치는지 체크
    final isOver = dropRect.overlaps(cardRect);
    if (isOver == _wasOverDropZone) return;

    if (isOver) {
      HapticFeedback.selectionClick(); // 드롭존 진입시 손맛
    }
    _wasOverDropZone = isOver;
    _dropZoneHighlightController.animateTo(isOver ? 1.0 : 0.0, curve: AppMotion.decelerate);
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
    final String? releasedCardId = _pulledCardId;
    if (_hasStartedCardDrag && releasedCardId != null) {
      _isPulledCardReturning = true;
      if (_wasOverDropZone) {
        // 드롭 발생 - 드롭존에 들어갔었다면 드롭 허용 > 잠시 머문 뒤 덱으로 복귀
        if (widget.onCardDrop != null) {
          widget.onCardDrop!(releasedCardId);
          HapticFeedback.heavyImpact();
        }
        Future.delayed(CardHandMotion.dropReturnDelay, () {
          if (!mounted || _pulledCardId != releasedCardId) return;
          _returnPulledCardToDeck(releaseVelocityPixelsPerSecond: Offset.zero);
        });
      } else {
        // 원위치: 놓는 순간 속도를 이어받아 spring 복귀
        _returnPulledCardToDeck(releaseVelocityPixelsPerSecond: details.velocity.pixelsPerSecond);
      }
    }

    if (!draggedCard) {
      _flingOrbit(details.velocity.pixelsPerSecond.dx);
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

  /// 놓은 카드 복귀: 현재 위치·속도에서 spring(snapSpring) > 변위·뽑기 진행도 0 도달 시 뽑힘 해제
  void _returnPulledCardToDeck({required Offset releaseVelocityPixelsPerSecond}) {
    final String? returningCardId = _pulledCardId;
    if (returningCardId == null) return;

    // 시작 지연분을 현재 변위에 합쳐 둔 뒤 spring 시작 (복귀 첫 프레임 점프 없음)
    final Offset releaseOffset = _calculateVisiblePullOffset();
    _pullStartLagOffset = Offset.zero;
    _pullProgressAtRelease = _pullController.value;
    _isPulledCardReturning = true;

    final returnFutures = [
      _pullOffsetXController.animateWith(
        _createSnapSpring(
          start: releaseOffset.dx,
          velocity: releaseVelocityPixelsPerSecond.dx,
          tolerance: CardHandMotion.pullOffsetSpringTolerance,
        ),
      ),
      _pullOffsetYController.animateWith(
        _createSnapSpring(
          start: releaseOffset.dy,
          velocity: releaseVelocityPixelsPerSecond.dy,
          tolerance: CardHandMotion.pullOffsetSpringTolerance,
        ),
      ),
      _pullController.animateWith(
        _createSnapSpring(
          start: _pullController.value,
          velocity: 0.0,
          tolerance: CardHandMotion.pullProgressSpringTolerance,
        ),
      ),
    ];
    _dropZoneHighlightController.animateTo(0.0, curve: AppMotion.decelerate);

    // 세 값 모두 도착 시 정리 (도중 재설정·dispose로 멈추면 실행 안 됨)
    Future.wait(returnFutures).then((_) {
      if (!mounted || _pulledCardId != returningCardId) return;
      setState(_resetPulledCard);
      _syncDropGuideIconWithPulledCard();
    });
  }

  /// 0으로 돌아가는 snapSpring (감쇠비 1.0, 넘침 없이 정착, 끝값 정확히 0)
  SpringSimulation _createSnapSpring({required double start, required double velocity, required Tolerance tolerance}) {
    return SpringSimulation(AppMotion.snapSpring, start, 0.0, velocity, tolerance: tolerance, snapToEnd: true);
  }

  /// 손 뗀 뒤 관성 회전: 마찰 감속, 끝 위치가 경계 밖이면 경계까지 spring으로 부드럽게 정착
  void _flingOrbit(double horizontalVelocityPixelsPerSecond) {
    _orbitAccumulated = _orbitAngle;
    // 속도 임계값을 낮춰서 짧은 스와이프도 감지
    if (horizontalVelocityPixelsPerSecond.abs() <= _orbitFlingMinimumVelocityPixelsPerSecond) {
      _orbitController?.value = _orbitAngle;
      return;
    }

    final double minAngle = _getMinOrbitAngle();
    final double maxAngle = _getMaxOrbitAngle();
    // 방향을 _handlePanUpdate와 일치시킴
    final double angularVelocity = horizontalVelocityPixelsPerSecond * _orbitSensitivity;

    final friction = FrictionSimulation(
      _orbitFlingFrictionDrag,
      _orbitAngle,
      angularVelocity,
      tolerance: CardHandMotion.orbitSimulationTolerance,
    );
    final double restingAngle = friction.finalX;
    final bool isRestingInsideBounds = restingAngle >= minAngle && restingAngle <= maxAngle;
    final Simulation orbitSimulation = isRestingInsideBounds
        ? friction
        : SpringSimulation(
            AppMotion.snapSpring,
            _orbitAngle,
            restingAngle.clamp(minAngle, maxAngle),
            angularVelocity,
            tolerance: CardHandMotion.orbitSimulationTolerance,
            snapToEnd: true,
          );

    _orbitController?.animateWith(orbitSimulation).then((_) {
      if (!mounted) return;
      final double settledAngle = (_orbitController?.value ?? _orbitAngle).clamp(minAngle, maxAngle);
      _orbitController?.value = settledAngle;
      _orbitAccumulated = settledAngle;
    });
  }
}
