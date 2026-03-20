import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

/// 이미지 전체화면 뷰어
/// 물품등록 화면에서 썸네일 탭 시 전체화면으로 이미지 확인
class ImageFullscreenViewer extends StatefulWidget {
  /// 기존 서버 이미지 URL 목록
  final List<String> existingImageUrls;

  /// 새로 선택된 로컬 이미지 파일 경로 목록
  final List<String> newImageFilePaths;

  /// 초기 표시할 이미지 인덱스
  final int initialIndex;

  const ImageFullscreenViewer({
    super.key,
    required this.existingImageUrls,
    required this.newImageFilePaths,
    required this.initialIndex,
  });

  @override
  State<ImageFullscreenViewer> createState() => _ImageFullscreenViewerState();
}

class _ImageFullscreenViewerState extends State<ImageFullscreenViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _isZoomed = false; // 핀치 줌 상태 추적

  int get _totalCount => widget.existingImageUrls.length + widget.newImageFilePaths.length;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // 이미지 PageView (줌 상태에서는 스와이프 비활성화)
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed ? const NeverScrollableScrollPhysics() : null,
            itemCount: _totalCount,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final int existingCount = widget.existingImageUrls.length;
              final bool isExisting = index < existingCount;

              final Widget imageChild = isExisting
                  ? CachedImage(
                      imageUrl: widget.existingImageUrls[index],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorWidget: const Icon(Icons.broken_image, color: AppColors.textColorWhite, size: 48),
                    )
                  : Image.file(
                      File(widget.newImageFilePaths[index - existingCount]),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _2, _3) =>
                          const Icon(Icons.broken_image, color: AppColors.textColorWhite, size: 48),
                    );

              // 초기 페이지에서 스와이프하지 않은 경우에만 Hero 적용
              // 스와이프 후 뒤로가기 시 엉뚱한 썸네일로 날아가는 문제 방지
              final bool shouldApplyHero = index == widget.initialIndex && _currentPage == widget.initialIndex;
              final Widget wrappedImage = shouldApplyHero
                  ? Hero(tag: 'item_image_$index', child: imageChild)
                  : imageChild;

              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionUpdate: (details) {
                  final bool zoomed = details.scale > 1.0;
                  if (zoomed != _isZoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
                child: Center(child: wrappedImage),
              );
            },
          ),

          // 상단 바: 닫기 버튼 + 페이지 인디케이터
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 닫기 버튼
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Icon(AppIcons.cancel, color: AppColors.textColorWhite, size: 24.sp),
                  ),
                ),
                // 페이지 인디케이터
                Text(
                  '${_currentPage + 1}/$_totalCount',
                  style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
                ),
                // 오른쪽 패딩 (균형)
                SizedBox(width: 56.w),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
