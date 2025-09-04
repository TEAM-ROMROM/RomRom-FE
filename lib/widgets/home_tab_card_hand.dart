import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/item_card.dart';

/// 홈탭 카드 핸드 위젯
class HomeTabCardHand extends StatefulWidget {
  final Function(String itemId)? onCardDrop;
  final List<Map<String, dynamic>>? cards;

  const HomeTabCardHand({
    super.key,
    this.onCardDrop,
    this.cards,
  });

  @override
  State<HomeTabCardHand> createState() => _HomeTabCardHandState();
}

class _HomeTabCardHandState extends State<HomeTabCardHand>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _fanController;
  late AnimationController _pullController;
  late AnimationController _deckLiftController;

  // 애니메이션들
  late Animation<double> _fanAnimation;
  late Animation<double> _pullAnimation;
  late Animation<double> _deckLift;

  // 덱/제스처 상태
  bool _isDeckRaised = false;
  double _orbitAngle = 0.0;

  bool _panStartedOnCard = false; // 터치 시작이 카드 위?
  String? _startCardId; // 터치 시작 카드
  bool _hasStartedCardDrag = false; // 수직 드래그 임계치 넘겨 카드 드래그 모드 진입?

  // 카드 상태
  String? _hoveredCardId;
  String? _pulledCardId;
  bool _isCardPulled = false;
  Offset _panStartPosition = Offset.zero;
  Offset _currentPanPosition = Offset.zero;
  Offset _pullOffset = Offset.zero;

  // 카드 리스트
  List<Map<String, dynamic>> _cards = [];

  // 카드 레이아웃 파라미터
  final double _cardWidth = 80.w;
  final double _cardHeight = 130.h;
  final double _fanRadius = 500.w; // 부채꼴 반경
  final double _maxFanAngle = 18.0; // 최대 펼침 각도 (도)
  final double _pullLift = 80.h; // 카드 뽑을 때 상승 높이
  final double _baseBottom = 50.h; // 기본 bottom 위치 (네비게이션 바 위)

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateCards();
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

    _deckLiftController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _deckLift = CurvedAnimation(
      parent: _deckLiftController,
      curve: Curves.easeOutCubic,
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

  void _setDeckRaised(bool raised) {
    if (_isDeckRaised == raised) return;
    setState(() => _isDeckRaised = raised);
    if (raised) {
      _deckLiftController.forward();
    } else {
      _deckLiftController.reverse();
      // 내려갈 때 카드 관련 상태 리셋
      _pulledCardId = null;
      _isCardPulled = false;
      _pullOffset = Offset.zero;
      _pullController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _fanController.dispose();
    // _hoverController.dispose();
    _pullController.dispose();
    _deckLiftController.dispose();
    super.dispose();
  }

  // 좌표에서 카드 찾기
  String? _findCardAtPosition(Offset localPosition) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    for (int i = 0; i < _cards.length; i++) {
      final transform = _calculateCardTransform(i, _cards.length);
      final cardCenterX = centerX + transform['x'];

      // 카드 영역 체크 (카드 너비의 절반 범위 내)
      if ((localPosition.dx - cardCenterX).abs() < _cardWidth / 2) {
        return _cards[i]['id'];
      }
    }
    return null;
  }

  // 카드 위치 및 회전 계산
  Map<String, dynamic> _calculateCardTransform(int index, int totalCards,
      {double phase = 0.0}) {
    final centerIndex = (totalCards - 1) / 2;
    final relativeIndex = index - centerIndex;

    // 카드 간격을 계산
    final cardSpacing = totalCards <= 5
        ? 60.w
        : totalCards <= 7
            ? 65.w
            : 50.w;

    // 각도 계산 (라디안)
    double angle = 0.0;
    if (totalCards > 1) {
      final maxAngleRad = _maxFanAngle * math.pi / 180;
      final angleStep = (2 * maxAngleRad) / (totalCards - 1);
      angle = -maxAngleRad + (index * angleStep);

      // 중앙 카드는 정확히 0도로 설정
      if ((relativeIndex.abs() < 0.1)) {
        angle = 0.0;
      }
    }

    // ⬇️ 덱 전체 위상 이동 적용: fan 각도에 phase를 '더한다'
    final angleWithPhase = angle + phase;

    // ===== 튜닝 파라미터 =====
    const double curveK = 0.25; // 기본 곡률 강도(↑면 전체가 더 내려감) 0.2~0.35 추천
    const double edgeDrop = 5.0; // 가장자리를 추가로 더 내림(px)
    const double edgeGamma = 1.6; // 가장자리 가중치 곡선(↑면 중앙은 덜, 끝은 더 내려감)
    // ========================

    final r = _fanRadius;

    // X
    final x = relativeIndex * cardSpacing;

    // 기본 곡률
    final baseY = -r * (1 - math.cos(angleWithPhase)) * curveK;

    // 가장자리 추가 드롭 (0~1 정규화)
    final absNorm =
        (centerIndex == 0) ? 0.0 : (relativeIndex.abs() / centerIndex);
    final extraEdgeDrop = -edgeDrop * math.pow(absNorm, edgeGamma).toDouble();

    final y = baseY + extraEdgeDrop;

    return {
      'x': x,
      'y': y,
      'angle': angleWithPhase * 0.7,
      'zIndex': totalCards - math.max((relativeIndex.abs() * 2).toInt(), 0),
    };
  }

  Widget _buildCard(Map<String, dynamic> cardData, int index, int totalCards) {
    final cardId = cardData['id'];
    final isPulled = _pulledCardId == cardId;

    final isHovered =
        _hasStartedCardDrag && _hoveredCardId == cardId && !isPulled;

    final transform =
        _calculateCardTransform(index, totalCards, phase: _orbitAngle);
    _calculateCardTransform(index, totalCards, phase: _orbitAngle);

    return AnimatedBuilder(
      animation: Listenable.merge([_fanAnimation, _pullAnimation, _deckLift]),
      builder: (context, child) {
        // 스태거드 애니메이션 효과
        final staggerDelay = index * 0.03;
        final staggeredFanValue =
            (_fanAnimation.value - staggerDelay).clamp(0.0, 1.0);

        double x = transform['x'] * staggeredFanValue;
        double y = transform['y'] * staggeredFanValue;
        double angle = transform['angle'] * staggeredFanValue;
        double scale = 1.0;
        double opacity = staggeredFanValue;

        // 카드 뽑기 효과
        if (isPulled) {
          final pullValue = _pullAnimation.value;
          x += _pullOffset.dx * pullValue;
          y -= (_pullOffset.dy - _pullLift) * pullValue; // 위로 드래그 시 카드가 위로 이동
          scale = 1.0 + (0.15 * pullValue);
          angle *= (1 - pullValue * 0.8);

          if (_isCardPulled) {
            opacity = 1.0 - (pullValue * 0.2);
          }
        }

        // Z-Index를 위한 순서 조정
        final zIndex = isPulled
            ? 1000
            : isHovered
                ? 999
                : transform['zIndex'] as int;

        final deckLiftPx = 40.h; // 덱이 떠오르는 높이(기호대로 튜닝)
        final liftedBottom = _baseBottom + (deckLiftPx * _deckLift.value);

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 - _cardWidth / 2 + x,
          bottom: liftedBottom + y, // 기본 위치 -130.h
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, 0.0, zIndex.toDouble())
              ..rotateZ(angle)
              ..scale(scale),
            child: AnimatedContainer(
              duration: Duration(milliseconds: isPulled ? 100 : 200),
              curve: Curves.easeOutCubic,
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                // 선택된 카드에 노란색 테두리 추가
                border: (isHovered || isPulled)
                    ? Border.all(
                        color: AppColors.primaryYellow,
                        width: 2,
                      )
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
                  itemId: cardId,
                  itemName: cardData['name'] ?? '아이템',
                  itemCategoryLabel: cardData['category'] ?? '카테고리',
                  itemCardImageUrl: cardData['imageUrl'] ?? '',
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

    _panStartedOnCard = false;
    _startCardId = null;
    _hasStartedCardDrag = false;

    if (_isDeckRaised) {
      final cardId = _findCardAtPosition(details.localPosition);
      if (cardId != null) {
        _panStartedOnCard = true;
        _startCardId = cardId;
        // 여기서는 선택 표시하지 않음 (수직 임계치 통과할 때 선택)
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final dx = details.localPosition.dx - _currentPanPosition.dx;
    final dy = _panStartPosition.dy - details.localPosition.dy;
    _currentPanPosition = details.localPosition;

    // 1) 좌우 = 항상 원호 회전만
    const double orbitSensitivity = 0.003; // 감도 튜닝
    setState(() {
      _orbitAngle += dx * orbitSensitivity;
    });

    // 2) 카드 드래그는 조건부
    if (_isDeckRaised && _panStartedOnCard && _startCardId != null) {
      // 수직 임계치 통과 시점에 '카드 드래그 모드' 진입 + 선택 고정
      const double selectThreshold = 10.0; // px
      if (!_hasStartedCardDrag && dy.abs() > selectThreshold) {
        setState(() {
          _hasStartedCardDrag = true;
          _hoveredCardId = _startCardId; // 이때 처음으로 선택 상태 표시
          HapticFeedback.selectionClick();
        });
      }

      // 카드 드래그 모드에서만 뽑기/위치 업데이트
      if (_hasStartedCardDrag) {
        setState(() {
          if (_pulledCardId == null && dy > 30) {
            _pulledCardId = _hoveredCardId;
            _pullOffset =
                Offset(details.localPosition.dx - _panStartPosition.dx, -dy);
            _pullController.forward();
            HapticFeedback.mediumImpact();
          } else if (_pulledCardId != null) {
            _pullOffset =
                Offset(details.localPosition.dx - _panStartPosition.dx, -dy);
          }
        });
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final dy = _panStartPosition.dy - _currentPanPosition.dy;

    if (_isDeckRaised && _hasStartedCardDrag) {
      if (_pulledCardId != null && dy > 100) {
        // 드롭 발생
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

    // 플래그/선택 해제
    setState(() {
      _panStartedOnCard = false;
      _startCardId = null;
      _hasStartedCardDrag = false;
      _hoveredCardId = null;
      _panStartPosition = Offset.zero;
      _currentPanPosition = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ⬇️ 바깥 오버레이: 덱이 떠 있을 때만 탭으로 닫기
        if (_isDeckRaised)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _setDeckRaised(false),
            ),
          ),

        // 덱(카드 핸드) 영역
        GestureDetector(
          // 한 번 탭하면 덱이 올라옴
          onTap: () {
            if (!_isDeckRaised) {
              _setDeckRaised(true);
            }
          },
          // 드래그 제스처
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: SizedBox(
            height: 280.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 드롭 영역 표시 (카드 뽑기 중일 때만)
                if (_pulledCardId != null)
                  Positioned(
                    top: -250.h,
                    left: 0,
                    right: 0,
                    height: 100.h,
                    child: AnimatedOpacity(
                      opacity: _pulledCardId != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 40.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                AppColors.primaryYellow.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          color: AppColors.primaryYellow.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            '거래 요청',
                            style: TextStyle(
                              color: AppColors.primaryYellow,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
