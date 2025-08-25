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
  late AnimationController _hoverController;
  late AnimationController _dragController;

  // 애니메이션들
  late Animation<double> _fanAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _dragAnimation;

  // 카드 상태
  String? _hoveredCardId;
  String? _draggedCardId;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  // 카드 리스트
  List<Map<String, dynamic>> _cards = [];

  // 카드 레이아웃 파라미터
  final double _cardWidth = 80.w;
  final double _cardHeight = 130.h;
  final double _fanRadius = 500.w; // 부채꼴 반경
  final double _maxFanAngle = 18.0; // 최대 펼침 각도 (도)
  final double _hoverLift = 30.h; // 호버 시 카드 상승 높이
  final double _dragLift = 50.h; // 드래그 시 카드 상승 높이

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

    // 호버 애니메이션
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutBack,
    );

    // 드래그 애니메이션
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _dragAnimation = CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutQuart,
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
      // 카드가 없을 때는 빈 리스트
      _cards = [];
    }
  }

  @override
  void dispose() {
    _fanController.dispose();
    _hoverController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  // 카드 위치 및 회전 계산
  Map<String, dynamic> _calculateCardTransform(int index, int totalCards) {
    final centerIndex = (totalCards - 1) / 2;
    final relativeIndex = index - centerIndex;

    // 카드 간격을 계산 (카드가 많을수록 간격 좁아짐)
    final cardSpacing = totalCards <= 5 
        ? 55.w  // 5장 이하일 때 넓은 간격
        : totalCards <= 7 
            ? 45.w  // 6-7장일 때 중간 간격
            : 35.w; // 8장 이상일 때 좁은 간격

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

    // 위치 계산 (부채꼴 배치)
    final arcY = _fanRadius * (1 - math.cos(angle));

    // 최종 위치 (카드 간격 포함)
    final x = relativeIndex * cardSpacing;
    final y = -arcY * 0.15; // Y축 곡률 감소 (음수로 기본적으로 아래쪽 위치)

    return {
      'x': x,
      'y': y,
      'angle': angle * 0.7, // 회전 각도 감소
      'zIndex': totalCards - math.max((relativeIndex.abs() * 2).toInt(), 0), // 중앙 카드가 위에 오도록
    };
  }

  Widget _buildCard(Map<String, dynamic> cardData, int index, int totalCards) {
    final cardId = cardData['id'];
    final isHovered = _hoveredCardId == cardId;
    final isDragged = _draggedCardId == cardId;

    final transform = _calculateCardTransform(index, totalCards);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _fanAnimation,
        _hoverAnimation,
        _dragAnimation,
      ]),
      builder: (context, child) {
        // 스태거드 애니메이션 효과
        final staggerDelay = index * 0.03;
        final staggeredFanValue = (_fanAnimation.value - staggerDelay).clamp(0.0, 1.0);
        
        double x = transform['x'] * staggeredFanValue;
        double y = transform['y'] * staggeredFanValue;
        double angle = transform['angle'] * staggeredFanValue;
        double scale = 1.0;
        double opacity = staggeredFanValue;

        // 호버 효과
        if (isHovered && !isDragged) {
          final hoverValue = _hoverAnimation.value;
          y -= _hoverLift * hoverValue; // 호버 시 카드가 위로 올라감 (top에서는 y값이 작아져야 올라감)
          scale = 1.0 + (0.18 * hoverValue); // 호버 시 18% 크기 증가
          
          // 인접 카드 밀어내기 효과
          final centerIndex = (totalCards - 1) / 2;
          if (index != centerIndex) {
            final pushAmount = 8.w * hoverValue;
            if (index < centerIndex) {
              // 왼쪽 카드들은 왼쪽으로
              for (int i = 0; i < index; i++) {
                x -= pushAmount * (1 - (index - i) * 0.3);
              }
            } else {
              // 오른쪽 카드들은 오른쪽으로
              for (int i = index + 1; i < totalCards; i++) {
                x += pushAmount * (1 - (i - index) * 0.3);
              }
            }
          }
        }

        // 드래그 효과
        if (isDragged) {
          x = _dragOffset.dx;
          y = -_dragOffset.dy - _dragLift; // 드래그 오프셋 반전하여 적용 (위로 드래그하면 카드가 위로)
          angle = _dragOffset.dx * 0.001; // 드래그 방향에 따른 미세한 회전
          scale = 1.25;
          opacity = 0.9;
        }

        // Z-Index를 위한 순서 조정
        final zIndex = isDragged 
            ? 1000 
            : isHovered 
                ? 999 
                : transform['zIndex'] as int;

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 - _cardWidth / 2 + x,
          bottom: 60.h - y, // bottom 위치로 복원, y가 음수면 카드가 올라감
          child: IgnorePointer(
            ignoring: false,
            child: GestureDetector(
              onTapDown: (_) => _onCardTapDown(cardId),
              onTapUp: (_) => _onCardTapUp(cardId),
              onTapCancel: () => _onCardTapCancel(cardId),
              onLongPressStart: (_) => _onCardLongPress(cardId),
              onPanStart: (details) => _onCardDragStart(cardId, details),
              onPanUpdate: (details) => _onCardDragUpdate(details),
              onPanEnd: (details) => _onCardDragEnd(details),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(0.0, 0.0, zIndex.toDouble())
                  ..rotateZ(angle)
                  ..scale(scale),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: isDragged ? 100 : 300),
                  curve: Curves.easeOutCubic,
                  width: _cardWidth,
                  height: _cardHeight,
                  decoration: BoxDecoration(
                    boxShadow: [
                      // 메인 그림자
                      BoxShadow(
                        color: isDragged
                            ? AppColors.primaryYellow.withValues(alpha: 0.5)
                            : isHovered
                                ? AppColors.primaryYellow.withValues(alpha: 0.4)
                                : AppColors.opacity20Black,
                        blurRadius: isDragged ? 35 : isHovered ? 25 : 10,
                        spreadRadius: isDragged ? 4 : isHovered ? 2 : 0,
                        offset: Offset(0, isDragged ? 20 : isHovered ? 12 : 5),
                      ),
                      // 글로우 효과 (호버/드래그 시)
                      if (isHovered || isDragged)
                        BoxShadow(
                          color: AppColors.primaryYellow.withValues(alpha: 0.3),
                          blurRadius: 50,
                          spreadRadius: 8,
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
            ),
          ),
        );
      },
    );
  }

  // 카드 인터랙션 핸들러들
  void _onCardTapDown(String cardId) {
    HapticFeedback.selectionClick();
    setState(() {
      _hoveredCardId = cardId;
    });
    _hoverController.forward();
  }

  void _onCardTapUp(String cardId) {
    setState(() {
      _hoveredCardId = null;
    });
    _hoverController.reverse();
  }

  void _onCardTapCancel(String cardId) {
    setState(() {
      _hoveredCardId = null;
    });
    _hoverController.reverse();
  }

  void _onCardLongPress(String cardId) {
    HapticFeedback.mediumImpact();
  }

  void _onCardDragStart(String cardId, DragStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _draggedCardId = cardId;
      _isDragging = true;
      _dragOffset = Offset.zero;
      _hoveredCardId = null; // 드래그 시작 시 호버 상태 해제
    });
    _dragController.forward();
    _hoverController.reverse();
  }

  void _onCardDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 드래그 오프셋 업데이트 (위로 드래그하면 카드가 위로 가야 하므로 dy를 반전)
      _dragOffset = Offset(
        _dragOffset.dx + details.delta.dx,
        _dragOffset.dy - details.delta.dy,  // y축을 반전시켜 위로 드래그하면 카드가 위로 가도록
      );
    });
  }

  void _onCardDragEnd(DragEndDetails details) {
    // 드롭 영역 체크 (상단 영역에 드롭했는지 확인)
    // 위로 드래그하면 dy가 양수이므로 100보다 큰지 체크
    if (_dragOffset.dy > 100) {
      // 거래 요청 트리거
      if (widget.onCardDrop != null && _draggedCardId != null) {
        widget.onCardDrop!(_draggedCardId!);
        HapticFeedback.heavyImpact();
      }
    }

    // 원위치로 애니메이션
    _dragController.reverse().then((_) {
      setState(() {
        _draggedCardId = null;
        _isDragging = false;
        _dragOffset = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 드롭 영역 표시 (드래그 중일 때만)
          if (_isDragging)
            Positioned(
              top: -200.h,  // 상단에 위치
              left: MediaQuery.of(context).size.width / 2 - 70.w,  // 중앙에 위치
              width: 140.w,  // 작은 박스 크기
              height: 50.h,
              child: AnimatedOpacity(
                opacity: _isDragging ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.opacity70Black,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    color: AppColors.opacity80Black,
                  ),
                  child: Center(
                    child: Text(
                      '거래 요청',
                      style: TextStyle(
                        color: AppColors.textColorWhite,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
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
    );
  }
}