import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 프로필 이미지 크롭 화면
/// - 직사각형 프레임을 드래그로 이미지 위에서 이동
/// - 직사각형 꼭지점 드래그로 크기 조정
/// - 직사각형 축소 후 2초 뒤 해당 영역에 맞춰 이미지 자동 줌인
/// - 원(지름 = 직사각형 가로)이 직사각형 내부 중앙에 표시
/// - 저장 시 원 영역 기준으로 정사각형 이미지 반환
class ProfileImageCropScreen extends StatefulWidget {
  const ProfileImageCropScreen({super.key, required this.imageFile});

  final XFile imageFile;

  @override
  State<ProfileImageCropScreen> createState() => _ProfileImageCropScreenState();
}

class _ProfileImageCropScreenState extends State<ProfileImageCropScreen> with SingleTickerProviderStateMixin {
  ui.Image? _image;
  double _imageScale = 1.0;
  double _baseImageScale = 1.0;
  double _cropSize = 0.0;
  int _prevPointerCount = 0;
  bool _isDraggingHandle = false;

  // 이동/리사이즈 가능한 직사각형 (cropSize 좌표계)
  double _rectLeft = 0;
  double _rectTop = 0;
  double _rectW = 0;
  double _rectH = 0;

  // 자동 줌인 애니메이션
  late final AnimationController _zoomController;
  Timer? _autoZoomTimer;

  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;
  static const double _minRectSize = 60.0;
  static const double _handleSize = 12.0;
  static const int _outputSize = 500;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _zoomController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _autoZoomTimer?.cancel();
    _zoomController.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _imageScale = _minScale;
          if (_cropSize > 0) _initRect(_cropSize);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지를 불러오는 데 실패했습니다.')));
        Navigator.of(context).pop(null);
      }
    }
  }

  double _displayW(double cropSize) => cropSize * _imageScale;

  double _displayH(double cropSize) {
    if (_image == null) return cropSize * _imageScale;
    return _displayW(cropSize) * (_image!.height.toDouble() / _image!.width.toDouble());
  }

  double _imgLeft(double cropSize) => (cropSize - _displayW(cropSize)) / 2;

  double _imgTop(double cropSize) => (cropSize - _displayH(cropSize)) / 2;

  // cropSize 내 이미지가 실제로 보이는 영역 (landscape처럼 이미지가 view보다 짧을 때 흑색 영역 제외)
  _VisibleArea _visibleArea(double cropSize) {
    final iL = _imgLeft(cropSize);
    final iT = _imgTop(cropSize);
    final dW = _displayW(cropSize);
    final dH = _displayH(cropSize);
    return _VisibleArea(
      left: math.max(0.0, iL),
      top: math.max(0.0, iT),
      right: math.min(cropSize, iL + dW),
      bottom: math.min(cropSize, iT + dH),
    );
  }

  void _initRect(double cropSize) {
    if (_image == null) return;
    final va = _visibleArea(cropSize);
    final size = math.min(va.width, va.height);
    _rectW = size;
    _rectH = size;
    _rectLeft = va.left + (va.width - size) / 2;
    _rectTop = va.top + (va.height - size) / 2;
  }

  void _clampRect(double cropSize) {
    if (_image == null) return;
    final va = _visibleArea(cropSize);
    _rectW = _rectW.clamp(_minRectSize, va.width);
    _rectH = _rectH.clamp(_rectW, va.height);
    _rectLeft = _rectLeft.clamp(va.left, va.right - _rectW);
    _rectTop = _rectTop.clamp(va.top, va.bottom - _rectH);
  }

  // ── 제스처 ──

  void _onScaleStart(ScaleStartDetails details) {
    _baseImageScale = _imageScale;
    _prevPointerCount = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double cropSize) {
    if (_image == null || _isDraggingHandle) return;

    if (details.pointerCount != _prevPointerCount) {
      _baseImageScale = _imageScale;
      _prevPointerCount = details.pointerCount;
      return;
    }

    if (details.pointerCount == 1) {
      setState(() {
        _rectLeft += details.focalPointDelta.dx;
        _rectTop += details.focalPointDelta.dy;
        _clampRect(cropSize);
      });
    } else {
      setState(() {
        _imageScale = (_baseImageScale * details.scale).clamp(_minScale, _maxScale);
        _clampRect(cropSize);
      });
    }
  }

  void _onResizeCorner({
    required DragUpdateDetails details,
    required double cropSize,
    required bool moveLeft,
    required bool moveTop,
  }) {
    setState(() {
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      if (moveLeft) {
        final newW = _rectW - dx;
        if (newW >= _minRectSize) {
          _rectLeft += dx;
          _rectW = newW;
        }
      } else {
        final newW = _rectW + dx;
        if (newW >= _minRectSize) {
          _rectW = newW;
        }
      }

      if (moveTop) {
        final newH = _rectH - dy;
        if (newH >= _rectW) {
          _rectTop += dy;
          _rectH = newH;
        }
      } else {
        final newH = _rectH + dy;
        if (newH >= _rectW) {
          _rectH = newH;
        }
      }

      _clampRect(cropSize);
    });
  }

  // ── 크롭 저장 ──

  Future<void> _onConfirm() async {
    if (_image == null || _cropSize == 0.0 || _rectW == 0.0) return;

    final imageW = _image!.width.toDouble();
    final imageH = _image!.height.toDouble();
    final dW = _displayW(_cropSize);
    final iL = _imgLeft(_cropSize);
    final iT = _imgTop(_cropSize);

    // 원: 직사각형 가로 = 지름, 직사각형 안에서 수직 중앙
    final circleLeft = _rectLeft;
    final circleTop = _rectTop + (_rectH - _rectW) / 2;
    final circleDiam = _rectW;

    final scaleRatio = imageW / dW;
    final srcLeft = ((circleLeft - iL) * scaleRatio).clamp(0.0, imageW);
    final srcTop = ((circleTop - iT) * scaleRatio).clamp(0.0, imageH);
    final srcSize = (circleDiam * scaleRatio).clamp(0.0, math.min(imageW - srcLeft, imageH - srcTop));

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(srcLeft, srcTop, srcSize.toDouble(), srcSize.toDouble()),
      Rect.fromLTWH(0, 0, _outputSize.toDouble(), _outputSize.toDouble()),
      paint,
    );
    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(_outputSize, _outputSize);
    final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지 처리에 실패했습니다. 다시 시도해주세요.')));
      }
      return;
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    if (mounted) {
      Navigator.of(context).pop(XFile(tempFile.path));
    }
  }

  // ── 빌드 ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.textColorBlack,
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '프로필 사진 수정',
        showBottomBorder: true,
        onBackPressed: () => Navigator.pop(context),
        actions: [
          AppPressable(
            onTap: () => _onConfirm(),
            child: Padding(
              padding: EdgeInsets.all(6.0.w),
              child: Text('저장', style: CustomTextStyles.h2.copyWith(color: AppColors.primaryYellow)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCropArea()),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  /// 크롭 영역 위에 이동/리사이즈 가능한 직사각형과 원 오버레이 표시
  Widget _buildCropArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 외부 SizedBox 크기: 핸들이 경계를 넘어 보일 공간 확보
        final outerSize = constraints.maxWidth - 32.w;
        // 이미지/오버레이 실제 크기: 핸들 반지름(handleSize/2)만큼 사방 여백
        final innerSize = outerSize - _handleSize;

        if (_cropSize != innerSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _cropSize = innerSize;
              if (_image != null) _initRect(innerSize);
            });
          });
        }

        return Center(
          child: SizedBox(
            width: outerSize,
            height: outerSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 이미지 + 오버레이: handleSize/2 패딩으로 내부 영역 축소
                Padding(
                  padding: const EdgeInsets.all(_handleSize / 2),
                  child: GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (details) => _onScaleUpdate(details, innerSize),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          _buildImageLayer(innerSize),
                          if (_rectW > 0)
                            CustomPaint(
                              size: Size(innerSize, innerSize),
                              painter: _CropOverlayPainter(
                                rectLeft: _rectLeft,
                                rectTop: _rectTop,
                                rectW: _rectW,
                                rectH: _rectH,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 핸들: 외부 Stack 좌표계 (handleSize/2 오프셋 적용)
                if (_rectW > 0) _buildHandles(innerSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageLayer(double cropSize) {
    if (_image == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
    }
    return Center(
      child: RawImage(
        image: _image,
        width: _displayW(cropSize),
        height: _displayH(cropSize),
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildHandles(double innerSize) {
    // 핸들 위치: 내부 좌표(innerSize 기준) + handleSize/2 오프셋 → 외부 Stack 좌표계
    const o = _handleSize / 2;
    return Stack(
      children: [
        _buildHandle(_rectLeft + o, _rectTop + o, innerSize, moveLeft: true, moveTop: true),
        _buildHandle(_rectLeft + _rectW + o, _rectTop + o, innerSize, moveLeft: false, moveTop: true),
        _buildHandle(_rectLeft + o, _rectTop + _rectH + o, innerSize, moveLeft: true, moveTop: false),
        _buildHandle(_rectLeft + _rectW + o, _rectTop + _rectH + o, innerSize, moveLeft: false, moveTop: false),
      ],
    );
  }

  /// 직사각형 꼭지점 드래그용 핸들
  Widget _buildHandle(double x, double y, double cropSize, {required bool moveLeft, required bool moveTop}) {
    return Positioned(
      left: x - _handleSize / 2,
      top: y - _handleSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() => _isDraggingHandle = true),
        onPanUpdate: (details) =>
            _onResizeCorner(details: details, cropSize: cropSize, moveLeft: moveLeft, moveTop: moveTop),
        onPanEnd: (_) {
          setState(() => _isDraggingHandle = false);
        },
        onPanCancel: () {
          setState(() => _isDraggingHandle = false);
        },
        child: SizedBox(
          width: _handleSize,
          height: _handleSize,
          child: CustomPaint(
            painter: _CornerHandlePainter(holeAtRight: moveLeft, holeAtBottom: moveTop),
          ),
        ),
      ),
    );
  }
}

class _VisibleArea {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const _VisibleArea({required this.left, required this.top, required this.right, required this.bottom});

  double get width => right - left;
  double get height => bottom - top;
}

/// 크롭 오버레이 Painter
/// - 원 외부: 반투명 검정 오버레이
/// - 직사각형 테두리 및 원 테두리 흰색 선
/// - 원 내부: rule of thirds 격자선
class _CropOverlayPainter extends CustomPainter {
  final double rectLeft;
  final double rectTop;
  final double rectW;
  final double rectH;

  const _CropOverlayPainter({required this.rectLeft, required this.rectTop, required this.rectW, required this.rectH});

  @override
  void paint(Canvas canvas, Size size) {
    final circleRadius = rectW / 2;
    final circleCenter = Offset(rectLeft + rectW / 2, rectTop + rectH / 2);

    // 원 외부 반투명 오버레이
    final overlayPaint = Paint()..color = AppColors.opacity40PrimaryBlack;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // 직사각형 테두리
    final borderPaint = Paint()
      ..color = AppColors.textColorWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(rectLeft, rectTop, rectW, rectH), borderPaint);

    // 원 테두리
    canvas.drawCircle(circleCenter, circleRadius, borderPaint);

    // rule of thirds 격자선 (원 내부)
    final gridPaint = Paint()
      ..color = AppColors.textColorWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius)));
    for (int i = 1; i <= 2; i++) {
      final x = circleCenter.dx - circleRadius + (circleRadius * 2 * i / 3);
      canvas.drawLine(Offset(x, circleCenter.dy - circleRadius), Offset(x, circleCenter.dy + circleRadius), gridPaint);
    }
    for (int i = 1; i <= 2; i++) {
      final y = circleCenter.dy - circleRadius + (circleRadius * 2 * i / 3);
      canvas.drawLine(Offset(circleCenter.dx - circleRadius, y), Offset(circleCenter.dx + circleRadius, y), gridPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.rectLeft != rectLeft ||
      oldDelegate.rectTop != rectTop ||
      oldDelegate.rectW != rectW ||
      oldDelegate.rectH != rectH;
}

/// 꼭지점 핸들 Painter
/// - 외곽 12×12 정사각형, 내부 9×9 정사각형 구멍
/// - 구멍은 직사각형 안쪽(중심 방향) 꼭지점에 위치
///   좌상단 핸들 → 구멍 우하단 (holeAtRight=true, holeAtBottom=true)
///   우상단 핸들 → 구멍 좌하단 (holeAtRight=false, holeAtBottom=true)
///   좌하단 핸들 → 구멍 우상단 (holeAtRight=true, holeAtBottom=false)
///   우하단 핸들 → 구멍 좌상단 (holeAtRight=false, holeAtBottom=false)
class _CornerHandlePainter extends CustomPainter {
  final bool holeAtRight;
  final bool holeAtBottom;

  const _CornerHandlePainter({required this.holeAtRight, required this.holeAtBottom});

  static const double _shapeSize = 12.0;
  static const double _holeSize = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    // 12×12 도형을 중앙 정렬
    final offsetX = (size.width - _shapeSize) / 2;
    final offsetY = (size.height - _shapeSize) / 2;
    final holeX = offsetX + (holeAtRight ? _shapeSize - _holeSize : 0.0);
    final holeY = offsetY + (holeAtBottom ? _shapeSize - _holeSize : 0.0);

    final paint = Paint()..color = AppColors.textColorWhite;
    final path = Path()
      ..addRect(Rect.fromLTWH(offsetX, offsetY, _shapeSize, _shapeSize))
      ..addRect(Rect.fromLTWH(holeX, holeY, _holeSize, _holeSize))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerHandlePainter old) =>
      old.holeAtRight != holeAtRight || old.holeAtBottom != holeAtBottom;
}
