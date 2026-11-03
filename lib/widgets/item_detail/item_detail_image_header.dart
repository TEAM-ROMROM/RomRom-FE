// 물품 상세 상단 이미지 영역: 가로 스와이프 이미지, 인디케이터, 그라데이션, 교환 완료 오버레이·배지 (당김 확대는 ItemDetailStretchScrollView)
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

class ItemDetailImageHeader extends StatelessWidget {
  final Size imageSize;
  final List<String> imageUrls;
  final PageController pageController;
  final ValueNotifier<int> currentIndexNotifier;
  // 사진 확대 Hero id 접두사 (예: itemImage_{itemId}_ + 인덱스)
  final String heroBaseId;
  final bool isExchanged;

  const ItemDetailImageHeader({
    super.key,
    required this.imageSize,
    required this.imageUrls,
    required this.pageController,
    required this.currentIndexNotifier,
    required this.heroBaseId,
    required this.isExchanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(height: imageSize.height, width: imageSize.width, child: _buildImagePager()),

        /// 이미지 인디케이터
        Positioned(bottom: 24.h, left: 0, right: 0, child: _buildPageIndicator()),

        IgnorePointer(
          ignoring: !isExchanged,
          child: SizedBox(
            height: imageSize.height,
            width: imageSize.width,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.itemDetailBlackGradient, // 검정색 그라데이션
                  stops: const [0.0, 0.15, 0.60, 1.0],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
        ),

        /// 거래완료 오버레이 (검정 50%)
        if (isExchanged)
          IgnorePointer(
            child: Container(height: imageSize.height, width: imageSize.width, color: AppColors.opacity50Black),
          ),

        /// 거래완료 글라스모피즘 배지 (이미지 중앙)
        if (isExchanged)
          Positioned.fill(
            child: Align(alignment: Alignment.center, child: _buildExchangedBadge()),
          ),
      ],
    );
  }

  /// 가로 스와이프 이미지 (이미지 없으면 1페이지 + 실패 자리표시)
  Widget _buildImagePager() {
    return PageView.builder(
      itemCount: imageUrls.isNotEmpty ? imageUrls.length : 1, // ← 최소 1페이지
      controller: pageController,
      onPageChanged: (pageIndex) => currentIndexNotifier.value = pageIndex,
      itemBuilder: (context, pageIndex) {
        if (imageUrls.isEmpty) return Center(child: ErrorImagePlaceholder(size: imageSize));
        return _buildPageImage(context, pageIndex);
      },
    );
  }

  /// 페이지 이미지 1장: 탭 > 전체 보기 (Hero 연결)
  /// 피드·목록과 같은 디스크 캐시(AppImageCacheManager) 사용 > 상세 진입 시 재다운로드 없음
  /// 원본 해상도 디코딩 > 전체 보기(확대)와 같은 메모리 캐시 키 공유
  Widget _buildPageImage(BuildContext context, int pageIndex) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(context, pageIndex),
      child: Hero(
        tag: _toViewerHeroTag(openedPageIndex: pageIndex, viewerPageIndex: pageIndex),
        child: CachedImage(
          imageUrl: imageUrls[pageIndex],
          fit: BoxFit.cover,
          shouldDecodeAtFullResolution: true,
          placeholder: const Center(child: CommonLoadingIndicator(size: 32.0)),
          errorWidget: Center(child: ErrorImagePlaceholder(size: imageSize)),
        ),
      ),
    );
  }

  /// 전체 보기: 사진 넘김 > 상세 인디케이터·페이지 동기화 (닫기 전에 목적지 미리 맞춤)
  void _openPhotoViewer(BuildContext context, int initialPage) {
    showPhotoViewer(
      context: context,
      builders: imageUrls
          .map<WidgetBuilder>(
            (url) =>
                (_) => _buildViewerImage(url),
          )
          .toList(),
      heroTagBuilder: (viewerPageIndex) =>
          _toViewerHeroTag(openedPageIndex: initialPage, viewerPageIndex: viewerPageIndex),
      initialPage: initialPage,
      onPageChanged: (viewerIndex) {
        currentIndexNotifier.value = viewerIndex;
        if (pageController.hasClients) {
          final currentPage = pageController.page?.round();
          if (currentPage != viewerIndex) pageController.jumpToPage(viewerIndex);
        }
      },
    );
  }

  /// 전체 보기 이미지 (상세 헤더와 같은 캐시·원본 해상도)
  Widget _buildViewerImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCacheManager.instance,
      fit: BoxFit.cover,
      placeholder: (_, _) => const Center(child: CommonLoadingIndicator(size: 32.0)),
      errorWidget: (_, _, _) => Center(child: ErrorImagePlaceholder(size: imageSize)),
    );
  }

  /// 전체 보기 Hero 태그: 'photo_viewer_{heroBaseId}{연 페이지}_{보기 페이지}_{url}' (photo_viewer 패키지 형식 유지)
  String _toViewerHeroTag({required int openedPageIndex, required int viewerPageIndex}) =>
      'photo_viewer_$heroBaseId${openedPageIndex}_${viewerPageIndex}_${imageUrls[viewerPageIndex]}';

  /// 현재 페이지 점 표시 (선택: 노랑, 나머지: 흰색 50%)
  Widget _buildPageIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: currentIndexNotifier,
      builder: (_, current, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imageUrls.length,
            (index) => Container(
              width: 6.w,
              height: 6.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current == index ? AppColors.primaryYellow : AppColors.opacity50White,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 교환 완료 배지 (블러 + 흰 테두리)
  Widget _buildExchangedBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 122.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: AppColors.opacity10White,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: AppColors.textColorWhite, width: 1.w),
          ),
          alignment: Alignment.center,
          child: Text(
            '교환 완료',
            style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600, color: AppColors.textColorWhite),
          ),
        ),
      ),
    );
  }
}
