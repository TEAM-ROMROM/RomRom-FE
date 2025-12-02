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
import 'package:romrom_fe/widgets/item_card.dart';

/// 홈탭 카드 핸드 위젯
class HomeTabCardHand extends StatefulWidget {
  final Function(String itemId)? onCardDrop;
  final List<Item>? cards;

  const HomeTabCardHand({super.key, this.onCardDrop, this.cards});

  @override
  State<HomeTabCardHand> createState() => _HomeTabCardHandState();
}

class _HomeTabCardHandState extends State<HomeTabCardHand>
    with TickerProviderStateMixin {
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

  // 카드 상태
  String? _hoveredCardId;
  String? _pulledCardId;
  bool _isCardPulled = false;
  Offset _panStartPosition = Offset.zero;
  Offset _currentPanPosition = Offset.zero;
  Offset _pullOffset = Offset.zero;

  // 카드 리스트
  List<Item> _cards = [];

  // 카드 레이아웃 파라미터
  final double _cardWidth = 80.w;
  final double _cardHeight = 130.h;
  final double _pullLift = 80.h; // 카드 뽑을 때 상승 높이
  final double _baseBottom = 50.h; // 기본 bottom 위치 (네비게이션 바 위)
  final double _deckRadius = 340.r;
  final double _deckCenterYOffset = 140.h;
  final double _deckStepAngle = 12 * math.pi / 180;
  final double _deckMaxTilt = 8 * math.pi / 180;
  final int _deckDepth = 8;

  // keys: 전역 좌표 구하려고
  final GlobalKey _deckKey = GlobalKey(); // 카드 스택 영역
  final GlobalKey _dropZoneKey = GlobalKey(); // 노란 드롭존

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
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true); // 반복 애니메이션 (위아래로 움직임)

    _iconAnimation = Tween<double>(begin: 0.0, end: 10.0.h).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeAnimations() {
    // 팬 애니메이션 (카드 펼치기)
    _fanController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fanAnimation = CurvedAnimation(
      parent: _fanController,
      curve: Curves.easeOutExpo,
    );

    // 카드 뽑기 애니메이션
    _pullController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pullAnimation = CurvedAnimation(
      parent: _pullController,
      curve: Curves.easeOut,
    );

    // 초기 팬 애니메이션 실행
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fanController.forward();
    });
  }

  void _generateCards() {
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      _cards = widget.cards!.take(10).toList(); // 최대 10개까지만
    } else {
      _cards = [];
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _fanController.dispose();
    _pullController.dispose();
    _orbitController?.dispose();
    super.dispose();
  }

  // 좌표에서 카드 찾기
  String? _findCardAtPosition(Offset localPosition) {
    final transforms = List.generate(
      _cards.length,
      (index) => _calculateCardTransform(context, index, _cards.length),
    );

    final indexedCards = List.generate(_cards.length, (index) => index)
      ..sort((a, b) {
        return (transforms[b]['zIndex'] as int).compareTo(
          transforms[a]['zIndex'] as int,
        );
      });

    for (final index in indexedCards) {
      final transform = transforms[index];
      final cardCenterX = transform['centerX'] as double;

      // 카드 영역 체크 (카드 너비의 절반 범위 내)
      if ((localPosition.dx - cardCenterX).abs() < _cardWidth / 2) {
        return _cards[index].itemId;
      }
    }

    return null;
  }

  // 카드 위치 및 회전 계산
  Map<String, dynamic> _calculateCardTransform(
    BuildContext context,
    int index,
    int totalCards,
  ) {
    final double midIndex = (totalCards - 1) / 2;
    final double relativeIndex = index - midIndex;
    final double angle = (relativeIndex * _deckStepAngle) + _orbitAngle;

    final size = MediaQuery.of(context).size;
    final double centerX = size.width / 2;
    final double centerY = _deckRadius + _deckCenterYOffset;

    final double cardCenterX = centerX + _deckRadius * math.cos(angle);
    final double cardCenterY = centerY + _deckRadius * math.sin(angle);

    final double verticalShift =
        _deckCenterYOffset - (_baseBottom + (_cardHeight / 2));
    final double adjustedTop = cardCenterY - verticalShift - (_cardHeight / 2);

    final double tangent = angle + math.pi / 2;
    final double proximity = 1.0 - (relativeIndex.abs() / (midIndex + 1e-6));
    final double tilt = _deckMaxTilt * proximity;
    final int zIndex =
        ((_deckDepth * proximity) + (totalCards - relativeIndex.abs())).round();

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

    final isHovered =
        _hasStartedCardDrag && _hoveredCardId == cardId && !isPulled;

    final transform = _calculateCardTransform(context, index, totalCards);
    final bool isPressed = _pressedCardId == cardId;

    return AnimatedBuilder(
      animation: Listenable.merge([_fanAnimation, _pullAnimation]),
      builder: (context, child) {
        // 스태거드 애니메이션 효과
        final staggerDelay = index * 0.03;
        final staggeredFanValue = (_fanAnimation.value - staggerDelay).clamp(
          0.0,
          1.0,
        );

        final size = MediaQuery.of(context).size;
        final double fanOriginLeft = size.width / 2 - _cardWidth / 2;
        final double fanOriginTop =
            _deckCenterYOffset - (_cardHeight / 2) - (_baseBottom * 0.2);

        double left = lerpDouble(
          fanOriginLeft,
          transform['left'] as double,
          staggeredFanValue,
        )!;
        double top = lerpDouble(
          fanOriginTop,
          transform['top'] as double,
          staggeredFanValue,
        )!;
        double angle = lerpDouble(
          0.0,
          transform['angle'] as double,
          staggeredFanValue,
        )!;
        double scale = 1.0;
        double opacity = staggeredFanValue;

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
          angle *= (1 - pullValue * 0.8);

          if (_isCardPulled) {
            opacity = 1.0 - (pullValue * 0.2);
          }
        }

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
                // 선택된 카드에 노란색 테두리 추가
                border: (isHovered || isPulled)
                    ? Border.all(color: AppColors.primaryYellow, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: [
                  BoxShadow(
                    color: isHovered || isPulled
                        ? AppColors.primaryBlack.withValues(alpha: 0.3)
                        : AppColors.opacity20Black,
                    blurRadius: isHovered || isPulled ? 20 : 10,
                    spreadRadius: 0,
                    offset: Offset(0, isHovered || isPulled ? 10 : 5),
                  ),
                ],
              ),
              child: Opacity(
                opacity: opacity,
                child: ItemCard(
                  itemId: cardId!,
                  isSmall: true,
                  itemName: cardData.itemName ?? '아이템',
                  itemCategoryLabel: ItemCategories.fromServerName(
                    cardData.itemCategory!,
                  ).label,
                  itemCardImageUrl: cardData.primaryImageUrl != null
                      ? cardData.primaryImageUrl!
                      : 'https://picsum.photos/400/300',
                ),
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
    _currentPanPosition = details.localPosition;
    _orbitController?.stop();
    _orbitDragStart = details.localPosition.dx;

    _panStartedOnCard = false;
    _startCardId = null;
    _hasStartedCardDrag = false;

    final cardId = _findCardAtPosition(details.localPosition);
    setState(() => _pressedCardId = cardId);
    if (cardId != null) {
      _panStartedOnCard = true;
      _startCardId = cardId;
      // 여기서는 선택 표시하지 않음 (수직 임계치 통과할 때 선택)
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // 드래그 변위(손가락 방향과 동일한 부호)
    final dispX = details.localPosition.dx - _panStartPosition.dx; // → 오른쪽 +
    final dispY = details.localPosition.dy - _panStartPosition.dy; // → 아래로 +

    _currentPanPosition = details.localPosition;

    // 1) 좌우 = 항상 원호 회전만 (카드 드래그 모드 전까지)
    if (!_hasStartedCardDrag) {
      final double dragDx = -details.localPosition.dx + _orbitDragStart;
      final double targetAngle =
          _orbitAccumulated + (-dragDx * _orbitSensitivity);
      setState(() {
        _orbitAngle = targetAngle;
        _orbitController?.value = targetAngle;
      });
    }

    // 2) 카드 드래그는 조건부
    if (_panStartedOnCard && _startCardId != null) {
      // 수직 임계치 통과 시점에 '카드 드래그 모드' 진입 + 선택 고정
      const double selectThreshold = 10.0; // px
      if (!_hasStartedCardDrag && dispY.abs() > selectThreshold) {
        setState(() {
          _hasStartedCardDrag = true;
          _hoveredCardId = _startCardId; // 이때 처음으로 선택 상태 표시
          _orbitAccumulated = _orbitAngle;
          _orbitDragStart = details.localPosition.dx;
          HapticFeedback.selectionClick();
        });
      }

      // 카드 드래그 모드에서만 뽑기/위치 업데이트
      if (_hasStartedCardDrag) {
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
        final deckBox =
            _deckKey.currentContext?.findRenderObject() as RenderBox?;
        final dropRect = _globalRectOf(_dropZoneKey);
        if (deckBox != null && dropRect != null && _pulledCardId != null) {
          // 현재 포인터 위치(덱 로컬) → 글로벌
          final globalPointer = deckBox.localToGlobal(_currentPanPosition);

          // 카드 중심을 포인터로 대체(충분히 자연스러움).
          final isOver = dropRect.contains(globalPointer);

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

  void _handlePanEnd(DragEndDetails details) {
    final bool draggedCard = _hasStartedCardDrag;
    if (_hasStartedCardDrag) {
      if (_pulledCardId != null && _wasOverDropZone) {
        // 드롭 발생 - 드롭존에 들어갔었다면 드롭 허용
        if (widget.onCardDrop != null) {
          widget.onCardDrop!(_pulledCardId!);
          HapticFeedback.heavyImpact();
        }
        setState(() => _isCardPulled = true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {
            _pulledCardId = null;
            _isCardPulled = false;
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
      if (horizontalVelocity.abs() > 10) {
        final double angularVelocity = -horizontalVelocity * _orbitSensitivity;
        final simulation = FrictionSimulation(
          0.12,
          _orbitAngle,
          angularVelocity,
        );
        _orbitController?.animateWith(simulation).whenComplete(() {
          if (!mounted) return;
          _orbitAccumulated = _orbitController?.value ?? _orbitAngle;
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
      _currentPanPosition = Offset.zero;
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
          child: SizedBox(
            height: 280.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_hasStartedCardDrag)
                  Positioned(
                    top: -MediaQuery.of(context).size.height,
                    child: Container(
                      height: MediaQuery.of(context).size.height - 30.h,
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
                                  color: AppColors.cardDropZoneShadow
                                      .withValues(alpha: 0.8 * _dropShadowT),
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
                                    filter: ImageFilter.blur(
                                      sigmaX: 30,
                                      sigmaY: 30,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.cardDropZoneBorder,
                                        width: 2.w,
                                      ),
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
                              child: const Icon(
                                AppIcons.cardDrag,
                                color: AppColors.primaryYellow,
                              ),
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

                // 카드들
                ..._cards.asMap().entries.map((entry) {
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
