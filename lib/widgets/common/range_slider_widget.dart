import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 탐색 범위 설정을 위한 커스텀 슬라이더 위젯
/// 4개의 분기점(2.5km, 5km, 7.5km, 10km)을 가지며, 좌우 스와이프로 값을 조절합니다.
class RangeSliderWidget extends StatefulWidget {
  /// 현재 선택된 인덱스 (0~3)
  final int selectedIndex;

  /// 값 변경 시 호출되는 콜백
  final ValueChanged<int> onChanged;

  /// 범위 옵션 목록
  final List<RangeOption> options;

  const RangeSliderWidget({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.options,
  });

  @override
  State<RangeSliderWidget> createState() => _RangeSliderWidgetState();
}

class _RangeSliderWidgetState extends State<RangeSliderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late int _currentIndex;
  int? _lastHapticIndex; // 마지막으로 햅틱을 준 인덱스 (중복 방지)
  double _dragStartX = 0;
  double _dragStartValue = 0;

  // 슬라이더 상수
  static const double _trackHorizontalPadding = 12.0;
  static const double _smallDotSize = 10.0;
  static const double _largeDotSize = 24.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _lastHapticIndex = _currentIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _currentIndex.toDouble(),
      end: _currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(RangeSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    _animation = Tween<double>(
      begin: _animation.value,
      end: index.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward(from: 0);
    _currentIndex = index;
    _lastHapticIndex = index;
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartValue = _animation.value;
    // 시작 시 현재 인덱스 기록(드래그 중 중복 햅틱 방지용)
    _lastHapticIndex = _animation.value.round();
  }

  void _onPanUpdate(DragUpdateDetails details, double trackWidth) {
    final segmentWidth = trackWidth / (widget.options.length - 1);
    final dragDelta = details.localPosition.dx - _dragStartX;
    final valueDelta = dragDelta / segmentWidth;
    final newValue =
        (_dragStartValue + valueDelta).clamp(0.0, (widget.options.length - 1).toDouble());

    setState(() {
      _animation = AlwaysStoppedAnimation(newValue);
    });

    // 드래그 중 분기점(정수 인덱스)을 넘을 때마다 햅틱
    final int nearest = newValue.round().clamp(0, widget.options.length - 1);
    if (_lastHapticIndex != nearest) {
      _lastHapticIndex = nearest;
      if (!kIsWeb) HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final nearestIndex = _animation.value.round().clamp(0, widget.options.length - 1);
    _animateTo(nearestIndex);
    widget.onChanged(nearestIndex);
    // 최종 선택 시 약한 임팩트
    if (!kIsWeb) HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details, double trackWidth) {
    final segmentWidth = trackWidth / (widget.options.length - 1);
    final tapX = details.localPosition.dx - _trackHorizontalPadding.w;
    final newIndex = (tapX / segmentWidth).round().clamp(0, widget.options.length - 1);
    _animateTo(newIndex);
    widget.onChanged(newIndex);
    // 탭으로 선택했을 때 햅틱
    if (!kIsWeb) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth =
            constraints.maxWidth - (_trackHorizontalPadding.w * 2);
        final segmentWidth = trackWidth / (widget.options.length - 1);

        return SizedBox(
          height: 76.h,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final currentValue = _animation.value;
              final nearestIndex =
                  currentValue.round().clamp(0, widget.options.length - 1);
              final dotX =
                  _trackHorizontalPadding.w + (currentValue * segmentWidth);

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 레이블 (큰 원 위 8px)
                  _buildLabel(nearestIndex, dotX),
                  // 슬라이더 트랙
                  _buildSliderTrack(trackWidth),
                  // 설명 텍스트 (큰 원 아래 8px)
                  _buildDescription(nearestIndex, dotX),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 레이블 빌드 - Transform으로 X 위치 조정
  Widget _buildLabel(int nearestIndex, double dotX) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(dotX, 0),
        child: FractionalTranslation(
          translation: const Offset(-0.5, 0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
              color: AppColors.opacity10White,
            ),
            child: Text(
              widget.options[nearestIndex].label,
              style: CustomTextStyles.p2.copyWith(
                color: AppColors.opacity60White,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 슬라이더 트랙 빌드
  Widget _buildSliderTrack(double trackWidth) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: (details) => _onPanUpdate(details, trackWidth),
      onPanEnd: _onPanEnd,
      onTapUp: (details) => _onTapUp(details, trackWidth),
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: _trackHorizontalPadding.w),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(trackWidth, 40.h),
              painter: _RangeSliderPainter(
                optionCount: widget.options.length,
                currentValue: _animation.value,
                primaryColor: AppColors.primaryYellow,
                inactiveColor: AppColors.secondaryBlack2,
                smallDotSize: _smallDotSize.w,
                largeDotSize: _largeDotSize.w,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 설명 텍스트 빌드 - Transform으로 X 위치 조정
  Widget _buildDescription(int nearestIndex, double dotX) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(dotX, 0),
        child: FractionalTranslation(
          translation: const Offset(-0.5, 0),
          child: Text(
            widget.options[nearestIndex].description,
            style: CustomTextStyles.p3,
          ),
        ),
      ),
    );
  }
}

/// 슬라이더 페인터
class _RangeSliderPainter extends CustomPainter {
  final int optionCount;
  final double currentValue;
  final Color primaryColor;
  final Color inactiveColor;
  final double smallDotSize;
  final double largeDotSize;

  _RangeSliderPainter({
    required this.optionCount,
    required this.currentValue,
    required this.primaryColor,
    required this.inactiveColor,
    required this.smallDotSize,
    required this.largeDotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final segmentWidth = size.width / (optionCount - 1);
    final centerY = size.height / 2;

    // 페인트들
    final inactiveTrackPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final activeTrackPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // knob 위치 (선과 큰 원이 함께 움직이도록 currentValue 기반으로 계산)
    final knobX = (currentValue.clamp(0.0, (optionCount - 1).toDouble())) * segmentWidth;

    // 1) 전체 비활성 트랙 그리기
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      inactiveTrackPaint,
    );

    // 2) 활성 트랙: 0에서 knob 위치까지
    canvas.drawLine(
      Offset(0, centerY),
      Offset(knobX, centerY),
      activeTrackPaint,
    );

    // 3) 분기점 점들 그리기 (활성 여부는 knobX 기준)
    for (int i = 0; i < optionCount; i++) {
      final x = i * segmentWidth;
      final isActive = x <= knobX + 0.0001; // knob이 지나는 지점 포함
      final paint = Paint()..color = isActive ? primaryColor : inactiveColor;
      canvas.drawCircle(Offset(x, centerY), smallDotSize / 2, paint);
    }

    // 4) 이동 가능한 큰 원(노브) 항상 그리기 — 선과 함께 부드럽게 움직임
    final shadowPaint = Paint()
      ..color = AppColors.textColorBlack.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(knobX + 1, centerY + 1),
      largeDotSize / 2,
      shadowPaint,
    );

    final largeDotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(
      Offset(knobX, centerY),
      largeDotSize / 2,
      largeDotPaint,
    );
  }

  @override
  bool shouldRepaint(_RangeSliderPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.optionCount != optionCount ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

/// 범위 옵션 데이터 클래스
class RangeOption {
  /// 레이블 (예: "2.5km 이내")
  final String label;

  /// 설명 (예: "가까운 동네")
  final String description;

  /// 실제 거리 값 (km)
  final double distanceKm;

  const RangeOption({
    required this.label,
    required this.description,
    required this.distanceKm,
  });
}

/// 기본 탐색 범위 옵션
const List<RangeOption> defaultSearchRangeOptions = [
  RangeOption(
    label: '2.5km 이내',
    description: '가까운 동네',
    distanceKm: 2.5,
  ),
  RangeOption(
    label: '5km 이내',
    description: '조금 가까운 동네',
    distanceKm: 5.0,
  ),
  RangeOption(
    label: '7.5km 이내',
    description: '조금 먼 동네',
    distanceKm: 7.5,
  ),
  RangeOption(
    label: '10km 이내',
    description: '먼 동네',
    distanceKm: 10.0,
  ),
];
