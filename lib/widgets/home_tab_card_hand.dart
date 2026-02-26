import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'dart:async';

/// 홈탭 카드 핸드 위젯
class HomeTabCardHand extends StatefulWidget {
  final Function(String itemId)? onCardDrop;
  final List<Item>? cards;

  /// AI 추천 상위 3개 itemId 목록 - 해당 카드에 glow boxShadow 효과 적용
  final List<String> highlightedItemIds;

  const HomeTabCardHand({super.key, this.onCardDrop, this.cards, this.highlightedItemIds = const []});

  @override
  State<HomeTabCardHand> createState() => _HomeTabCardHandState();
}

class _HomeTabCardHandState extends State<HomeTabCardHand> with TickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _fanController;
  late AnimationController _pullController;
  AnimationController? _orbitController;

  // 애니메이션들
  late Animation<double> _fanAnimation;
  late Animation<double> _pullAnimation;

  // 덱/제스처 상태
  double _orbitAngle = -math.pi / 2;
  double _orbitDragStart = 0.0;
  double _orbitAccumulated = -math.pi / 2;
  static const double _orbitSensitivity = 0.0045;

  bool _panStartedOnCard = false; // 터치 시작이 카드 위
  String? _startCardId; // 터치 시작 카드
  bool _hasStartedCardDrag = false; // 수직 드래그 임계치 넘겨 카드 드래그 모드 진입
  String? _pressedCardId; // 터치로 강조된 카드
  Timer? _longPressTimer; // 0.2초 롱프레스 타이머

  // 카드 상태
  String? _hoveredCardId;
  String? _pulledCardId;
  Offset _panStartPosition = Offset.zero;
  Offset _pullOffset = Offset.zero;

  // 카드 리스트
  List<Item> _allCards = []; // 전체 카드 리스트
  List<Item> _cards = []; // 현재 표시되는 카드 리스트
  int _leftLoadedCount = 0; // 왼쪽에서 로드된 카드 개수
  int _rightLoadedCount = 0; // 오른쪽에서 로드된 카드 개수
  static const int _initialLoadCount = 7; // 초기 로드 개수
  static const int _loadChunkSize = 3; // 한 번에 로드할 카드 개수

  // 카드 레이아웃 파라미터
  final double _cardWidth = 92.w;
  final double _cardHeight = 137.h;
  final double _pullLift = 80.h; // 카드 뽑을 때 상승 높이
  final double _baseBottom = 50.h; // 기본 bottom 위치 (네비게이션 바 위)
  final double _deckRadius = 340.r;
  final double _deckCenterYOffset = 140.h;
  final double _deckStepAngle = 10 * math.pi / 180;
  final double _deckMaxTilt = 8 * math.pi / 180;
  final int _deckDepth = 8;

  // keys: 전역 좌표 구하려고
  final GlobalKey _deckKey = GlobalKey(); // 카드 스택 영역
  final GlobalKey _dropZoneKey = GlobalKey(); // 흰색 드롭존

  double _dropShadowT = 0.0; // 0~1, 드롭존 그림자 강도
  bool _wasOverDropZone = false; // 진입/이탈 감지용(햅틱 등)

  Rect? _globalRectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  // AI 하이라이트 애니메이션
  // - glow 펄스: repeat(reverse) 로 밝기 반복
  // - float: 한 번만 위로 슥 올라오는 단방향 애니메이션
  late AnimationController _highlightPulseController; // glow 밝기 반복
  late Animation<double> _highlightPulseAnimation;

  late AnimationController _highlightFloatController; // 위로 슥 올라오는 단방향
  late Animation<double> _highlightFloatAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateCards();

    _orbitController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!mounted) return;
        setState(() => _orbitAngle = _orbitController?.value ?? _orbitAngle);
      })
      ..value = _orbitAngle;

    // 아이콘 애니메이션 초기화
    _iconAnimationController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this)
      ..repeat(reverse: true); // 반복 애니메이션 (위아래로 움직임)

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0.h,
    ).animate(CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut));

    // glow 밝기 반복 (0.5 ~ 1.0 사이를 계속 왔다갔다)
    _highlightPulseController = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);

    _highlightPulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _highlightPulseController, curve: Curves.easeInOut));

    // float: 0 → -10h 로 한 번만 올라옴 (easeOut으로 자연스럽게 감속)
    _highlightFloatController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _highlightFloatAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(parent: _highlightFloatController, curve: Curves.easeOut));

    // highlightedItemIds 가 이미 있으면 즉시 float 실행
    if (widget.highlightedItemIds.isNotEmpty) {
      _highlightFloatController.forward();
    }
  }

  @override
  void didUpdateWidget(HomeTabCardHand oldWidget) {
    super.didUpdateWidget(oldWidget);

    // highlightedItemIds 가 새로 들어오면 float 애니메이션 처음부터 재실행
    if (widget.highlightedItemIds != oldWidget.highlightedItemIds) {
      if (widget.highlightedItemIds.isNotEmpty) {
        _highlightFloatController.forward(from: 0.0);
      } else {
        // 하이라이트 해제 시 원위치
        _highlightFloatController.reverse();
      }
    }
  }

  void _initializeAnimations() {
    // 팬 애니메이션 (카드 펼치기)
    _fanController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fanAnimation = CurvedAnimation(parent: _fanController, curve: Curves.easeOutExpo);

    // 카드 뽑기 애니메이션
    _pullController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _pullAnimation = CurvedAnimation(parent: _pullController, curve: Curves.easeOut);

    // 초기 팬 애니메이션 실행
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fanController.forward();
    });
  }

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

  // 각도 제한 계산 메서드 추가
  double _getMinOrbitAngle() {
    if (_cards.isEmpty || _cards.length <= 1) return -math.pi / 2;
    final totalCards = _cards.length;
    final midIndex = (totalCards - 1) / 2;
    // 맨 오른쪽 카드가 오른쪽 끝에 올 때의 각도 (새로 로드하지는 않지만 기존 카드 볼 수 있음)
    return -math.pi / 2 - (midIndex * _deckStepAngle);
  }

  double _getMaxOrbitAngle() {
    if (_cards.isEmpty || _cards.length <= 1) return -math.pi / 2;
    final totalCards = _cards.length;
    final midIndex = (totalCards - 1) / 2;
    // 맨 왼쪽 카드가 왼쪽 끝에 올 때의 각도 (새로 로드하지는 않지만 기존 카드 볼 수 있음)
    return -math.pi / 2 + (midIndex * _deckStepAngle);
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _highlightPulseController.dispose();
    _highlightFloatController.dispose();
    _fanController.dispose();
    _pullController.dispose();
    _orbitController?.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  // 좌표에서 카드 찾기
  String? _findCardAtPosition(Offset localPosition) {
    // 왼쪽 카드가 위에 있으므로 (reversed로 렌더링됨)
    // 역순으로 검사하여 위에 있는 카드부터 확인
    for (int i = _cards.length - 1; i >= 0; i--) {
      final transform = _calculateCardTransform(context, i, _cards.length);
      final cardCenterX = transform['centerX'] as double;

      // 카드 영역 체크 (카드 너비의 절반 범위 내)
      if ((localPosition.dx - cardCenterX).abs() < _cardWidth / 2) {
        return _cards[i].itemId;
      }
    }

    return null;
  }

  // 카드 위치 및 회전 계산
  Map<String, dynamic> _calculateCardTransform(BuildContext context, int index, int totalCards) {
    final double midIndex = (totalCards - 1) / 2;
    final double relativeIndex = index - midIndex;
    final double angle = (relativeIndex * _deckStepAngle) + _orbitAngle;

    final size = MediaQuery.of(context).size;
    final double centerX = size.width / 2;
    final double centerY = _deckRadius + _deckCenterYOffset;

    final double cardCenterX = centerX + _deckRadius * math.cos(angle);
    final double cardCenterY = centerY + _deckRadius * math.sin(angle);

    final double verticalShift = _deckCenterYOffset - (_baseBottom + (_cardHeight / 2));
    final double adjustedTop = cardCenterY - verticalShift - (_cardHeight / 2);

    final double tangent = angle + math.pi / 2;
    final double proximity = 1.0 - (relativeIndex.abs() / (midIndex + 1e-6));
    // 카드가 1개일 때는 tilt를 0으로 설정
    final double tilt = totalCards == 1 ? 0 : _deckMaxTilt * proximity;
    final int zIndex = ((_deckDepth * proximity) + (totalCards + relativeIndex)).round();

    return {
      'left': cardCenterX - (_cardWidth / 2),
      'top': adjustedTop,
      'angle': tangent + tilt,
      'centerX': cardCenterX,
      'zIndex': zIndex,
    };
  }

  Widget _buildCard(Item cardData, int index, int totalCards) {
    final cardId = cardData.itemId;
    final isPulled = _pulledCardId == cardId;

    final isHovered = _hasStartedCardDrag && _hoveredCardId == cardId && !isPulled;

    final transform = _calculateCardTransform(context, index, totalCards);
    final bool isPressed = _pressedCardId == cardId;

    // AI 추천 하이라이트 여부
    final bool isAiHighlighted = cardId != null && widget.highlightedItemIds.contains(cardId);

    return AnimatedBuilder(
      // float 컨트롤러도 함께 listen
      animation: Listenable.merge([_fanAnimation, _pullAnimation, _highlightPulseAnimation, _highlightFloatAnimation]),
      builder: (context, child) {
        // 스태거드 애니메이션 효과
        final staggerDelay = index * 0.03;
        final staggeredFanValue = (_fanAnimation.value - staggerDelay).clamp(0.0, 1.0);

        final size = MediaQuery.of(context).size;
        final double fanOriginLeft = size.width / 2 - _cardWidth / 2;
        final double fanOriginTop = _deckCenterYOffset - (_cardHeight / 2) - (_baseBottom * 0.2);

        double left = lerpDouble(fanOriginLeft, transform['left'] as double, staggeredFanValue)!;
        double top = lerpDouble(fanOriginTop, transform['top'] as double, staggeredFanValue)!;
        double angle = lerpDouble(0.0, transform['angle'] as double, staggeredFanValue)!;
        double scale = 1.0;

        if (!isPulled) {
          if (isHovered) {
            scale = math.max(scale, 1.12);
          } else if (isPressed) {
            scale = math.max(scale, 1.05);
          }
        }

        // 카드 뽑기 효과
        if (isPulled) {
          final pullValue = _pullAnimation.value;
          left += _pullOffset.dx * pullValue;
          top += _pullOffset.dy * pullValue - _pullLift * pullValue;
          const double dragBaseScale = 1.15;
          const double dragScaleGain = 0.20;
          scale = dragBaseScale + (dragScaleGain * pullValue);
          angle *= (1 - pullValue);
        }

        // ── AI 하이라이트 float 적용 ─────────────────────────────────
        // pulled/hovered 상태에서는 적용하지 않아 기존 드래그 인터랙션과 충돌 없음
        // _highlightFloatAnimation: 0.0 → -10.h (위로 슥 한 번만 올라옴, easeOut)
        if (isAiHighlighted && !isPulled && !isHovered) {
          top += _highlightFloatAnimation.value.h;
        }
        // ────────────────────────────────────────────────────────────

        // ── boxShadow 결정 ──────────────────────────────────────────
        List<BoxShadow> cardBoxShadow;

        if (isAiHighlighted && !isPulled && !isHovered) {
          // AI 추천 카드: aiCardGradient 색상 기반 glow (펄스 애니메이션)
          final pulse = _highlightPulseAnimation.value;
          cardBoxShadow = [
            BoxShadow(
              color: AppColors.aiCardGradient[0].withValues(alpha: 0.75 * pulse),
              offset: Offset((-1).w, (-1).h),
              blurRadius: 6.r,
              spreadRadius: 4.r,
            ),
            BoxShadow(
              color: AppColors.aiCardGradient[1].withValues(alpha: 0.7 * pulse),
              offset: Offset(0, 5.h),
              blurRadius: 20.r,
              spreadRadius: 4.r,
            ),
            BoxShadow(
              color: AppColors.aiCardGradient[2].withValues(alpha: 0.65 * pulse),
              offset: Offset((-3).w, (-3).h),
              blurRadius: 10.r,
              spreadRadius: 3.r,
            ),
          ];
        } else {
          // 기본 / hover / pulled 상태
          cardBoxShadow = [
            BoxShadow(
              color: isHovered || isPulled ? AppColors.primaryBlack.withValues(alpha: 0.3) : AppColors.opacity20Black,
              blurRadius: isHovered || isPulled ? 20 : 10,
              spreadRadius: 0,
              offset: Offset(0, isHovered || isPulled ? 10 : 5),
            ),
          ];
        }
        // ────────────────────────────────────────────────────────────

        return Positioned(
          left: left,
          top: top,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(angle)
              // ignore: deprecated_member_use
              ..scale(scale),
            child: AnimatedContainer(
              duration: Duration(milliseconds: isPulled ? 100 : 200),
              curve: Curves.easeOutCubic,
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                border: (isHovered || isPulled)
                    ? Border.all(color: AppColors.primaryYellow, width: 2)
                    : isAiHighlighted
                    ? Border.all(
                        color: AppColors.aiCardGradient[1].withValues(alpha: _highlightPulseAnimation.value),
                        width: 1.5.w,
                      )
                    : null,
                borderRadius: BorderRadius.circular((10 * scale * _cardHeight / 326.h).r),
                boxShadow: cardBoxShadow,
              ),
              child: RequestManagementItemCardWidget(
                card: RequestManagementItemCard(
                  itemId: cardId!,
                  imageUrl: cardData.primaryImageUrl ?? 'https://picsum.photos/400/300',
                  category: ItemCategories.fromServerName(cardData.itemCategory!).label,
                  title: cardData.itemName ?? '아이템',
                  price: cardData.price ?? 0,
                  likeCount: cardData.likeCount ?? 0,
                  aiPrice: cardData.isAiPredictedPrice ?? false,
                ),
                width: _cardWidth,
                height: _cardHeight,
                isActive: true,
              ),
            ),
          ),
        );
      },
    );
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

    // 1) 좌우 = 항상 원호 회전만 (카드 드래그 모드 전까지)
    if (!_hasStartedCardDrag) {
      final double dragDx = details.localPosition.dx - _orbitDragStart;
      final double targetAngle = _orbitAccumulated + (dragDx * _orbitSensitivity);

      final double minAngle = _getMinOrbitAngle();
      final double maxAngle = _getMaxOrbitAngle();
      final double clampedAngle = targetAngle.clamp(minAngle, maxAngle);

      setState(() {
        _orbitAngle = clampedAngle;
        _orbitController?.value = clampedAngle;

        // 각도에 따라 카드 동적 로드
        // 왼쪽으로 스와이프 (음수 방향) → 오른쪽 카드 추가 로드
        if (_orbitAngle < _orbitAccumulated - 0.2 && _rightLoadedCount > 0) {
          if (_loadCardsRight()) {
            // 연속 로드 방지
            _orbitAccumulated = _orbitAngle;
            _orbitDragStart = details.localPosition.dx;
          }
        }
        // 오른쪽으로 스와이프 (양수 방향) → 왼쪽 카드 추가 로드
        if (_orbitAngle > _orbitAccumulated + 0.2 && _leftLoadedCount > 0) {
          if (_loadCardsLeft()) {
            // 연속 로드 방지
            _orbitAccumulated = _orbitAngle;
            _orbitDragStart = details.localPosition.dx;
          }
        }
      });
    }

    // 2) 카드 드래그는 조건부
    if (_panStartedOnCard && _startCardId != null) {
      // 드래그 임계치 확인 - 만약 일정 거리 이상 이동하면 롱프레스 타이머 취소
      const double dragThreshold = 20.0; // px
      if (_longPressTimer != null && (dispX.abs() > dragThreshold || dispY.abs() > dragThreshold)) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
      }

      // 수직 임계치 통과했고 이미 선택됨
      const double selectThreshold = 10.0; // px
      if (_hasStartedCardDrag && dispY.abs() > selectThreshold) {
        setState(() {
          // 위로 당길 때 시작(dispY가 음수), 시작 임계치 -30px
          if (_pulledCardId == null && dispY < -30) {
            _pulledCardId = _hoveredCardId;
            _pullOffset = Offset(dispX, dispY);
            _pullController.forward();
            HapticFeedback.mediumImpact();
          } else if (_pulledCardId != null) {
            _pullOffset = Offset(dispX, dispY);
          }
        });

        // ⬇️ 드롭존 overlap 체크 → 그림자 강도 갱신
        final deckBox = _deckKey.currentContext?.findRenderObject() as RenderBox?;
        final dropRect = _globalRectOf(_dropZoneKey);
        if (deckBox != null && dropRect != null && _pulledCardId != null) {
          // 현재 카드의 위치 계산
          final cardIndex = _cards.indexWhere((card) => card.itemId == _pulledCardId);
          if (cardIndex != -1) {
            final transform = _calculateCardTransform(context, cardIndex, _cards.length);
            final pullValue = _pullAnimation.value;

            // 카드의 실제 위치 계산 (pull 효과 포함)
            final cardLeft = (transform['left'] as double) + _pullOffset.dx * pullValue;
            final cardTop = (transform['top'] as double) + _pullOffset.dy * pullValue - _pullLift * pullValue;

            // 카드의 글로벌 위치
            final cardGlobalTopLeft = deckBox.localToGlobal(Offset(cardLeft, cardTop));

            // 카드의 전체 영역 (Rect)
            final cardRect = cardGlobalTopLeft & Size(_cardWidth, _cardHeight);

            // 드롭존과 카드 영역이 겹치는지 체크
            final isOver = dropRect.overlaps(cardRect);

            // 스무딩(선형 보간)
            final target = isOver ? 1.0 : 0.0;
            final newT = (_dropShadowT * 0.7) + (target * 0.3); // 부드럽게

            if (isOver && !_wasOverDropZone) {
              HapticFeedback.selectionClick(); // 드롭존 진입시 손맛
            }
            _wasOverDropZone = isOver;

            setState(() => _dropShadowT = newT.clamp(0.0, 1.0));
          }
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _deckKey,
      clipBehavior: Clip.none,
      children: [
        // 덱(카드 핸드) 영역
        GestureDetector(
          // 드래그 제스처
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onPanCancel: _handlePanCancel,
          child: SizedBox(
            height: 280.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_hasStartedCardDrag)
                  Positioned(
                    top: -MediaQuery.of(context).size.height,
                    child: Container(
                      height: MediaQuery.of(context).size.height + 50.h,
                      width: MediaQuery.of(context).size.width,
                      color: AppColors.opacity30PrimaryBlack,
                    ),
                  ),
                // 드롭 영역 표시 (카드 뽑기 중일 때만)
                if (_pulledCardId != null)
                  Positioned(
                    top: -408.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 136.w),
                          child: Container(
                            key: _dropZoneKey,
                            width: 122.w,
                            height: 189.h,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardDropZoneShadow.withValues(alpha: 0.8 * _dropShadowT),
                                  blurRadius: 30 * (0.5 + 0.5 * _dropShadowT),
                                  spreadRadius: 2 * _dropShadowT,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                    child: const SizedBox.expand(),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.cardDropZoneBorder, width: 2.w),
                                      borderRadius: BorderRadius.circular(8.r),
                                      color: AppColors.cardDropZoneBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _iconAnimation,
                          builder: (context, child) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: 32.0.h - _iconAnimation.value,
                                bottom: 20.h + _iconAnimation.value,
                              ),
                              child: const Icon(AppIcons.cardDrag, color: AppColors.primaryYellow),
                            );
                          },
                        ),
                        Text(
                          "위로 드래그하여\n거래방식 선택하기",
                          textAlign: TextAlign.center,
                          style: CustomTextStyles.p2.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),

                // 카드들 - 왼쪽 카드가 위로 오도록 역순으로 렌더링
                ..._cards.asMap().entries.toList().reversed.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return _buildCard(card, index, _cards.length);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
