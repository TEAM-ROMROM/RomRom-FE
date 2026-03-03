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

/// 프로필 이미지 크롭 화면
/// - 정사각형 크롭 영역에 원형 가이드라인 오버레이 표시
/// - 드래그로 이미지 위치 조정, 슬라이더로 줌 조정
/// - 확인 시 정사각형 이미지 XFile 반환
class ProfileImageCropScreen extends StatefulWidget {
  const ProfileImageCropScreen({super.key, required this.imageFile});

  final XFile imageFile;

  @override
  State<ProfileImageCropScreen> createState() => _ProfileImageCropScreenState();
}

class _ProfileImageCropScreenState extends State<ProfileImageCropScreen> {
  ui.Image? _image;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _cropSize = 0.0; // LayoutBuilder에서 설정, _buildAppBar의 _onConfirm에서 공유

  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;
  static const int _outputSize = 500; // 출력 이미지 크기 (px)

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
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
          _scale = _minScale;
          _offset = Offset.zero;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지를 불러오는 데 실패했습니다.')));
        Navigator.of(context).pop(null);
      }
    }
  }

  /// 드래그 시 이미지 오프셋 업데이트 (원 밖으로 이미지가 벗어나지 않도록 클램핑)
  void _onPanUpdate(DragUpdateDetails details, double cropSize) {
    if (_image == null) return;
    setState(() {
      _offset += details.delta;
      _offset = _clampOffset(_offset, cropSize);
    });
  }

  /// scale 변경 시 오프셋도 재클램핑
  void _onScaleChanged(double newScale, double cropSize) {
    setState(() {
      _scale = newScale;
      _offset = _clampOffset(_offset, cropSize);
    });
  }

  /// 이미지가 원 영역 밖으로 나가지 않도록 오프셋을 제한
  Offset _clampOffset(Offset offset, double cropSize) {
    if (_image == null) return offset;
    final imageW = _image!.width.toDouble();
    final imageH = _image!.height.toDouble();
    final displayW = cropSize * _scale;
    final displayH = cropSize * _scale * (imageH / imageW);
    final maxDx = math.max(0.0, (displayW - cropSize) / 2);
    final maxDy = math.max(0.0, (displayH - cropSize) / 2);
    return Offset(offset.dx.clamp(-maxDx, maxDx), offset.dy.clamp(-maxDy, maxDy));
  }

  /// 확인 버튼: 현재 offset/scale 기준으로 정사각형 이미지 저장 후 반환
  Future<void> _onConfirm() async {
    if (_image == null || _cropSize == 0.0) return;

    final imageW = _image!.width.toDouble();
    final imageH = _image!.height.toDouble();

    // 화면상 이미지 표시 크기
    final displayW = _cropSize * _scale;
    final displayH = displayW * (imageH / imageW);

    // 이미지 원점 (cropSize 기준 중앙 정렬 + offset 적용)
    final imageLeft = (_cropSize - displayW) / 2 + _offset.dx;
    final imageTop = (_cropSize - displayH) / 2 + _offset.dy;

    // 크롭 영역이 이미지 좌표계에서 어디에 해당하는지 역산
    final scaleRatio = imageW / displayW;
    final srcLeft = (-imageLeft * scaleRatio).clamp(0.0, imageW);
    final srcTop = (-imageTop * scaleRatio).clamp(0.0, imageH);
    final srcSize = (_cropSize * scaleRatio).clamp(0.0, math.min(imageW - srcLeft, imageH - srcTop));

    // dart:ui Canvas로 정사각형 이미지 추출
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(srcLeft, srcTop, srcSize, srcSize),
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

    // 임시 파일로 저장
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    if (mounted) {
      Navigator.of(context).pop(XFile(tempFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildCropArea()),
            _buildZoomSlider(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(null),
            child: Text('취소', style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White)),
          ),
          Text('프로필 사진 조정', style: CustomTextStyles.h3.copyWith(color: AppColors.textColorWhite)),
          GestureDetector(
            onTap: _onConfirm,
            child: Text('확인', style: CustomTextStyles.p1.copyWith(color: AppColors.primaryYellow)),
          ),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cropSize = constraints.maxWidth - 48.w;
        // _cropSize를 State에 반영하여 _onConfirm과 공유
        if (_cropSize != cropSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _cropSize = cropSize);
          });
        }
        return Center(
          child: SizedBox(
            width: cropSize,
            height: cropSize,
            child: GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, cropSize),
              child: ClipRect(
                child: Stack(
                  children: [
                    // 이미지 레이어
                    _buildImageLayer(cropSize),
                    // 원형 오버레이 레이어
                    CustomPaint(size: Size(cropSize, cropSize), painter: _CircleOverlayPainter()),
                  ],
                ),
              ),
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
    final imageW = _image!.width.toDouble();
    final imageH = _image!.height.toDouble();
    final displayW = cropSize * _scale;
    final displayH = displayW * (imageH / imageW);
    return Transform.translate(
      offset: _offset,
      child: Center(
        child: RawImage(
          image: _image,
          width: displayW,
          height: displayH,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildZoomSlider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          Icon(Icons.zoom_out, color: AppColors.opacity60White, size: 20.sp),
          Expanded(
            child: Slider(
              value: _scale,
              min: _minScale,
              max: _maxScale,
              activeColor: AppColors.primaryYellow,
              inactiveColor: AppColors.opacity20White,
              onChanged: (value) => _onScaleChanged(value, _cropSize),
            ),
          ),
          Icon(Icons.zoom_in, color: AppColors.opacity60White, size: 20.sp),
        ],
      ),
    );
  }
}

/// 원형 가이드라인 오버레이 Painter
/// - 전체 영역을 반투명 검정으로 덮음
/// - 중앙 원형 영역을 뚫어서 이미지가 보이게 함
/// - 원 테두리를 흰색 선으로 그림
class _CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 반투명 오버레이 (원 밖 영역)
    final overlayPaint = Paint()..color = AppColors.opacity70Black;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // 원 테두리
    final borderPaint = Paint()
      ..color = AppColors.textColorWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
