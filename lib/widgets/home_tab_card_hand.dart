import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_geometry.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_layout.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_motion.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/home_tab_card_body.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/home_tab_card_decoration.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/home_tab_card_drop_zone.dart';
import 'dart:async';

part 'home_tab_card_hand/home_tab_card_hand_card_loading.dart';
part 'home_tab_card_hand/home_tab_card_hand_ai_highlight.dart';
part 'home_tab_card_hand/home_tab_card_hand_gestures.dart';

/// 홈탭 카드 핸드 위젯
class HomeTabCardHand extends StatefulWidget {
  final Function(String itemId)? onCardDrop;
  final List<Item>? cards;

  /// AI 추천 상위 3개 itemId 목록 - 해당 카드에 glow boxShadow 효과 적용
  final List<String> highlightedItemIds;

  /// 드래그 인터랙션 활성화 여부 (광고 슬롯에서 false)
  final bool dragEnabled;

  const HomeTabCardHand({
    super.key,
    this.onCardDrop,
    this.cards,
    this.highlightedItemIds = const [],
    this.dragEnabled = true,
  });

  @override
  State<HomeTabCardHand> createState() => _HomeTabCardHandState();
}

/// 카드 핸드 상태 필드·공용 계산 (책임별 mixin이 공유, part 파일: home_tab_card_hand/)
abstract class _HomeTabCardHandStateFields extends State<HomeTabCardHand> with TickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _fanController;
  // 뽑기 진행도 0~1 (뽑을 때 곡선, 놓으면 spring 복귀)
  late AnimationController _pullController;
  AnimationController? _orbitController;

  // 당김 변위 축별 값 (드래그 중 손가락 1:1, 놓으면 spring 복귀)
  late AnimationController _pullOffsetXController;
  late AnimationController _pullOffsetYController;

  // 드롭존 그림자 강도 0~1 (진입·이탈 시 감속 전환)
  late AnimationController _dropZoneHighlightController;

  // 애니메이션들
  late Animation<double> _fanAnimation;
  Animation<double> get _pullAnimation => _pullController;

  // 덱/제스처 상태
  double _orbitAngle = -math.pi / 2;
  double _orbitDragStart = 0.0;
  double _orbitAccumulated = -math.pi / 2;

  bool _panStartedOnCard = false; // 터치 시작이 카드 위
  String? _startCardId; // 터치 시작 카드
  bool _hasStartedCardDrag = false; // 수직 드래그 임계치 넘겨 카드 드래그 모드 진입
  String? _pressedCardId; // 터치로 강조된 카드
  Timer? _longPressTimer; // 0.2초 롱프레스 타이머

  // 카드 상태
  String? _hoveredCardId;
  String? _pulledCardId;
  Offset _panStartPosition = Offset.zero;

  // 뽑기 시작 순간의 손가락 변위 (뽑기 진행도만큼 따라잡아 시작 순간 점프 방지)
  Offset _pullStartLagOffset = Offset.zero;

  // 놓은 카드가 덱으로 돌아가는 중 (새 카드 선택 차단, 크기 보정)
  bool _isPulledCardReturning = false;

  // 놓는 순간의 뽑기 진행도 (복귀 진행도 계산 기준)
  double _pullProgressAtRelease = 1.0;

  // 카드 리스트
  List<Item> _allCards = []; // 전체 카드 리스트
  List<Item> _cards = []; // 현재 표시되는 카드 리스트
  int _leftLoadedCount = 0; // 왼쪽에서 로드된 카드 개수
  int _rightLoadedCount = 0; // 오른쪽에서 로드된 카드 개수

  // 카드 레이아웃 파라미터 (didChangeDependencies에서 화면 크기 기준으로 초기화)
  CardHandLayout _layout = CardHandLayout.designDefault;
  bool _layoutInitialized = false;

  // keys: 전역 좌표 구하려고
  final GlobalKey _deckKey = GlobalKey(); // 카드 스택 영역
  final GlobalKey _dropZoneKey = GlobalKey(); // 흰색 드롭존

  bool _wasOverDropZone = false; // 진입/이탈 감지용(햅틱 등)

  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  // AI 하이라이트 애니메이션
  // - glow 펄스: repeat(reverse) 로 밝기 반복
  // - float: 한 번만 위로 슥 올라오는 단방향 애니메이션
  late AnimationController _highlightPulseController; // glow 밝기 반복
  late Animation<double> _highlightPulseAnimation;

  late AnimationController _highlightFloatController; // 위로 슥 올라오는 단방향
  late Animation<double> _highlightFloatAnimation;

  // AI 추천 카드 재정렬 애니메이션
  // - _reorderAnimController: 카드가 old 위치 → new 위치로 이동하는 보간 제어
  // - _preReorderTransforms: 재정렬 직전 각 카드의 transform 스냅샷 (cardId → transform)
  late AnimationController _reorderAnimController;
  Animation<double> get _reorderAnimation => _reorderAnimController;
  Map<String, CardHandCardTransform> _preReorderTransforms = {};
  int _reorderGeneration = 0;

  /// 현재 궤도 각도 기준 카드 정적 목표 위치 (화면 너비는 MediaQuery)
  CardHandCardTransform _calculateCardTransform(BuildContext context, int index, int totalCards) {
    return CardHandGeometry.calculateCardTransform(
      layout: _layout,
      screenWidth: MediaQuery.of(context).size.width,
      index: index,
      totalCards: totalCards,
      orbitAngle: _orbitAngle,
    );
  }

  double _getMinOrbitAngle() => CardHandGeometry.calculateMinOrbitAngle(_cards.length);

  double _getMaxOrbitAngle() => CardHandGeometry.calculateMaxOrbitAngle(_cards.length);

  /// 화면에 반영할 당김 변위: 손가락 변위 - 시작 지연분 (뽑기 진행도만큼 해소)
  Offset _calculateVisiblePullOffset() {
    final fingerOffset = Offset(_pullOffsetXController.value, _pullOffsetYController.value);
    return fingerOffset - _pullStartLagOffset * (1 - _pullAnimation.value);
  }

  /// 뽑힌 카드 상태 즉시 초기화: 변위·진행도·드롭존 강도 0, 복귀 해제 (진행 중 spring 정지, setState 안에서 호출)
  void _resetPulledCard() {
    _pullOffsetXController.value = 0.0;
    _pullOffsetYController.value = 0.0;
    _pullController.value = 0.0;
    _dropZoneHighlightController.value = 0.0;
    _pulledCardId = null;
    _isPulledCardReturning = false;
    _pullStartLagOffset = Offset.zero;
    _wasOverDropZone = false;
  }
}

/// 카드 핸드: 수명주기·애니메이션 초기화·화면 구성 (로직은 mixin 3개: 카드 로드, AI 하이라이트, 제스처)
class _HomeTabCardHandState extends _HomeTabCardHandStateFields
    with _HomeTabCardHandCardLoading, _HomeTabCardHandAiHighlight, _HomeTabCardHandGestures {
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateCards();

    // 궤도 각도: 리스너는 동기 보관만 (카드 변환은 _buildCard의 AnimatedBuilder가 구독)
    _orbitController = AnimationController.unbounded(vsync: this)
      ..addListener(() => _orbitAngle = _orbitController?.value ?? _orbitAngle)
      ..value = _orbitAngle;

    // 드롭 안내 아이콘 위아래 반복 (카드 당김 중에만 실행, _syncDropGuideIconWithPulledCard)
    _iconAnimationController = AnimationController(
      duration: CardHandMotion.dropGuideIconHalfCycleDuration,
      vsync: this,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _iconAnimationController, curve: AppMotion.standard));

    // glow 밝기 반복 (0.5 ~ 1.0 사이를 계속 왔다갔다)
    _highlightPulseController = AnimationController(
      duration: CardHandMotion.highlightPulseHalfCycleDuration,
      vsync: this,
    );

    _highlightPulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _highlightPulseController, curve: AppMotion.standard));

    // float: 0 → -10h 로 한 번만 올라옴 (출발 빠르고 길게 감속)
    _highlightFloatController = AnimationController(duration: CardHandMotion.highlightFloatUpDuration, vsync: this);

    _highlightFloatAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(parent: _highlightFloatController, curve: AppMotion.entry));

    // 재정렬 위치 보간 (선형 진행도, 집결·홀드·팬아웃 구간 곡선은 CardHandGeometry)
    _reorderAnimController = AnimationController(duration: CardHandMotion.reorderDuration, vsync: this);
    _reorderAnimController.addStatusListener((status) {
      if ((status == AnimationStatus.completed || status == AnimationStatus.dismissed) && mounted) {
        setState(() => _preReorderTransforms = {});
      }
    });

    // highlightedItemIds가 이미 있으면 재정렬 포함 전체 시퀀스 실행
    if (widget.highlightedItemIds.isNotEmpty) {
      _highlightPulseController.repeat(reverse: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reorderForAiHighlight(widget.highlightedItemIds);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_layoutInitialized) {
      // 화면 너비 기준으로 카드 크기 계산 (iPhone 393 기준 비율 유지)
      _layout = CardHandLayout.fromScreenWidth(MediaQuery.of(context).size.width);
      _layoutInitialized = true;
    }
  }

  @override
  void didUpdateWidget(HomeTabCardHand oldWidget) {
    super.didUpdateWidget(oldWidget);

    // dragEnabled가 true→false로 바뀌면 진행 중인 제스처 상태 전부 정리
    if (oldWidget.dragEnabled && !widget.dragEnabled) {
      _longPressTimer?.cancel();
      _longPressTimer = null;
      setState(() {
        _panStartedOnCard = false;
        _startCardId = null;
        _hasStartedCardDrag = false;
        _pressedCardId = null;
        _hoveredCardId = null;
        _resetPulledCard();
      });
      _syncDropGuideIconWithPulledCard();
    }

    if (!listEquals(widget.cards, oldWidget.cards)) {
      setState(() => _generateCards());
    }

    if (!listEquals(widget.highlightedItemIds, oldWidget.highlightedItemIds)) {
      if (widget.highlightedItemIds.isNotEmpty) {
        if (!_highlightPulseController.isAnimating) {
          _highlightPulseController.repeat(reverse: true);
        }
        // 재정렬 + orbit 복귀 + float 애니메이션 순서로 실행
        _reorderForAiHighlight(widget.highlightedItemIds);
      } else {
        _highlightPulseController.stop();
        _highlightPulseController.value = 0.0;
        // 하이라이트 해제 시 float 슥 내려가기, 재정렬 애니메이션 역방향
        _highlightFloatController.animateTo(
          0.0,
          duration: CardHandMotion.highlightFloatDownDuration,
          curve: AppMotion.standard,
        );
        _reorderAnimController.reverse();
      }
    }
  }

  void _initializeAnimations() {
    // 팬 애니메이션 (카드 펼치기, 강한 감속)
    _fanController = AnimationController(duration: CardHandMotion.fanDuration, vsync: this);
    _fanAnimation = CurvedAnimation(parent: _fanController, curve: AppMotion.decelerate);

    // 카드 뽑기 진행도 (곡선은 뽑을 때 animateTo에서, 복귀는 spring)
    _pullController = AnimationController(vsync: this);

    // 당김 변위 (unbounded: 손가락 위치·spring 복귀 중 넘침 허용)
    _pullOffsetXController = AnimationController.unbounded(vsync: this);
    _pullOffsetYController = AnimationController.unbounded(vsync: this);

    // 드롭존 그림자 강도
    _dropZoneHighlightController = AnimationController(duration: CardHandMotion.dropZoneHighlightDuration, vsync: this);

    // 초기 팬 애니메이션 실행
    Future.delayed(CardHandMotion.fanStartDelay, () {
      if (mounted) _fanController.forward();
    });
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _highlightPulseController.dispose();
    _highlightFloatController.dispose();
    _reorderAnimController.dispose();
    _fanController.dispose();
    _pullController.dispose();
    _pullOffsetXController.dispose();
    _pullOffsetYController.dispose();
    _dropZoneHighlightController.dispose();
    _orbitController?.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Widget _buildCard(Item cardData, int index, int totalCards) {
    final cardId = cardData.itemId;
    final isPulled = _pulledCardId == cardId;

    final isHovered = _hasStartedCardDrag && _hoveredCardId == cardId && !isPulled;

    final bool isPressed = _pressedCardId == cardId;

    // AI 추천 하이라이트 여부
    final bool isAiHighlighted = cardId != null && widget.highlightedItemIds.contains(cardId);

    return AnimatedBuilder(
      // 공통: 팬·하이라이트·재정렬·궤도 / 뽑힌 카드만: 뽑기 진행도·당김 변위 (드래그 중 나머지 카드 재빌드 없음)
      animation: Listenable.merge([
        _fanAnimation,
        _highlightPulseAnimation,
        _highlightFloatAnimation,
        _reorderAnimation,
        _orbitController,
        if (isPulled) ...[_pullAnimation, _pullOffsetXController, _pullOffsetYController],
      ]),
      // 카드 본문 (애니메이션 값 무관 > 프레임마다 재빌드하지 않도록 child로 재사용)
      child: HomeTabCardBody(item: cardData, width: _layout.cardWidth, height: _layout.cardHeight),
      builder: (context, child) {
        // 현재 궤도 각도 기준 목표 위치 > 팬·재정렬·당김·float 반영 자세
        final pose = CardHandGeometry.calculateCardPose(
          layout: _layout,
          screenWidth: MediaQuery.of(context).size.width,
          transform: _calculateCardTransform(context, index, totalCards),
          index: index,
          fanProgress: _fanAnimation.value,
          preReorderTransform: _preReorderTransforms[cardId],
          reorderProgress: _reorderAnimation.value,
          isGatheringReorder: widget.highlightedItemIds.length > 1,
          isPulled: isPulled,
          isHovered: isHovered,
          isPressed: isPressed,
          pullProgress: isPulled ? _pullAnimation.value : 0.0,
          pullOffset: isPulled ? _calculateVisiblePullOffset() : Offset.zero,
          isPullOffsetFollowingFinger: true,
          isAiHighlighted: isAiHighlighted,
          highlightFloatOffsetPixels: _highlightFloatAnimation.value.h,
        );

        // 복귀 중인 카드: 덱 도착 시 1.0배가 되도록 크기 보정
        final bool isReturning = isPulled && _isPulledCardReturning;
        final double cardScale = isReturning
            ? pose.scale *
                  CardHandGeometry.calculateReturningCardScaleFactor(returnProgress: _calculateReturnProgress())
            : pose.scale;

        return Positioned(
          left: pose.left,
          top: pose.top,
          child: Transform.rotate(
            angle: pose.angle,
            // 누름·선택 확대는 감속 전환, 뽑힌 카드는 매 프레임 값 그대로 (지연 없음)
            child: AnimatedScale(
              scale: cardScale,
              duration: isPulled ? Duration.zero : CardHandMotion.cardScaleDuration,
              curve: AppMotion.decelerate,
              child: AnimatedContainer(
                duration: isPulled
                    ? CardHandMotion.pulledCardDecorationDuration
                    : CardHandMotion.cardDecorationDuration,
                curve: AppMotion.decelerate,
                width: _layout.cardWidth,
                height: _layout.cardHeight,
                decoration: HomeTabCardDecoration.create(
                  // 복귀 시작과 함께 강조 테두리·그림자 해제
                  isPulled: isPulled && !isReturning,
                  isHovered: isHovered,
                  isAiHighlighted: isAiHighlighted,
                  highlightPulse: _highlightPulseAnimation.value,
                  scale: cardScale,
                  cardWidth: _layout.cardWidth,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 복귀 진행도: 놓는 순간 1 > 덱 도착 0 (뽑기 진행도 기준)
  double _calculateReturnProgress() {
    if (_pullProgressAtRelease <= 0) return 0.0;
    return (_pullAnimation.value / _pullProgressAtRelease).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _deckKey,
      clipBehavior: Clip.none,
      children: [
        // 덱(카드 핸드) 영역
        GestureDetector(
          // 광고 슬롯에서는 드래그 비활성화
          onPanStart: widget.dragEnabled ? _handlePanStart : null,
          onPanUpdate: widget.dragEnabled ? _handlePanUpdate : null,
          onPanEnd: widget.dragEnabled ? _handlePanEnd : null,
          onPanCancel: widget.dragEnabled ? _handlePanCancel : null,
          child: SizedBox(
            height: 280.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 카드 선택 중 배경 어둡게 (페이드 인·아웃, 터치는 덱 제스처가 처리)
                Positioned(
                  top: -MediaQuery.of(context).size.height,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hasStartedCardDrag ? 1.0 : 0.0,
                      duration: CardHandMotion.dimOverlayFadeDuration,
                      curve: AppMotion.standard,
                      child: Container(
                        height: MediaQuery.of(context).size.height + 50.h,
                        width: MediaQuery.of(context).size.width,
                        color: AppColors.opacity30PrimaryBlack,
                      ),
                    ),
                  ),
                ),
                // 드롭 영역 표시 (카드 뽑기 중일 때만, 뽑기 진행도만큼 페이드)
                if (_pulledCardId != null)
                  Positioned(
                    top: -408.h,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _pullAnimation,
                      child: HomeTabCardDropZone(
                        dropTargetKey: _dropZoneKey,
                        dropShadowAnimation: _dropZoneHighlightController,
                        guideIconAnimation: _iconAnimation,
                      ),
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
