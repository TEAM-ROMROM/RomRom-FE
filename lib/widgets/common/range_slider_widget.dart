import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  double _dragStartX = 0;
  double _dragStartValue = 0;

  // 슬라이더 상수
  static const double _trackHorizontalPadding = 24.0;
  static const double _smallDotSize = 10.0;
  static const double _largeDotSize = 24.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
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
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartValue = _animation.value;
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
  }

  void _onPanEnd(DragEndDetails details) {
    final nearestIndex = _animation.value.round().clamp(0, widget.options.length - 1);
    _animateTo(nearestIndex);
    widget.onChanged(nearestIndex);
  }

  void _onTapUp(TapUpDetails details, double trackWidth) {
    final segmentWidth = trackWidth / (widget.options.length - 1);
    final tapX = details.localPosition.dx - _trackHorizontalPadding.w;
    final newIndex = (tapX / segmentWidth).round().clamp(0, widget.options.length - 1);
    _animateTo(newIndex);
    widget.onChanged(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth =
            constraints.maxWidth - (_trackHorizontalPadding.w * 2);
        final segmentWidth = trackWidth / (widget.options.length - 1);

        return SizedBox(
          height: 120.h,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final currentValue = _animation.value;
              final nearestIndex =
                  currentValue.round().clamp(0, widget.options.length - 1);
              final dotX =
                  _trackHorizontalPadding.w + (currentValue * segmentWidth);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 레이블 (큰 원 위 8px)
                  _buildLabel(nearestIndex, dotX),
                  SizedBox(height: 8.h),
                  // 슬라이더 트랙
                  _buildSliderTrack(trackWidth),
                  SizedBox(height: 8.h),
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
                inactiveColor: AppColors.opacity30White,
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
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
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

    // 비활성 트랙 라인 그리기
    final inactiveTrackPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 활성 트랙 라인 그리기
    final activeTrackPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 현재 값까지의 활성 트랙
    final activeEndX = currentValue * segmentWidth;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(activeEndX, centerY),
      activeTrackPaint,
    );

    // 현�� 값 이후의 비활성 트랙
    canvas.drawLine(
      Offset(activeEndX, centerY),
      Offset(size.width, centerY),
      inactiveTrackPaint,
    );

    // 각 분기점에 점 그리기
    for (int i = 0; i < optionCount; i++) {
      final x = i * segmentWidth;
      final isActive = i <= currentValue.round();
      final isCurrentPosition = (currentValue - i).abs() < 0.5;

      if (isCurrentPosition) {
        // 큰 원 (현재 선택된 위치)
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(
          Offset(x + 1, centerY + 1),
          largeDotSize / 2,
          shadowPaint,
        );

        final largeDotPaint = Paint()..color = primaryColor;
        canvas.drawCircle(
          Offset(x, centerY),
          largeDotSize / 2,
          largeDotPaint,
        );
      } else {
        // 작은 원
        final smallDotPaint = Paint()
          ..color = isActive ? primaryColor : inactiveColor;
        canvas.drawCircle(
          Offset(x, centerY),
          smallDotSize / 2,
          smallDotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RangeSliderPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.optionCount != optionCount;
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
