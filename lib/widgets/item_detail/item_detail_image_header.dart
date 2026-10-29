// 물품 상세 상단 이미지 영역: 가로 스와이프 이미지, 인디케이터, 그라데이션, 교환 완료 오버레이·배지 (당김 확대는 ItemDetailStretchScrollView)
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
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
        final hasImages = imageUrls.isNotEmpty;
        final safeIndex = hasImages ? pageIndex : 0;

        return PhotoViewerMultipleImage(
          // 이미지가 없으면 더미 URL을 넘겨서 로딩 실패 → errorWidget 호출
          imageUrls: hasImages ? imageUrls : const ['__NO_IMAGE__'],
          index: safeIndex,
          id: heroBaseId + safeIndex.toString(),
          onPageChanged: (viewerIndex) {
            currentIndexNotifier.value = viewerIndex;
            if (pageController.hasClients) {
              final currentPage = pageController.page?.round();
              if (currentPage != viewerIndex) {
                pageController.jumpToPage(viewerIndex); // 닫기 전에 목적지 미리 맞추기
              }
            }
          },

          // 로딩 인디케이터
          placeholder: (ctx, url) => const Center(child: CommonLoadingIndicator(size: 32.0)),

          // 이미지 없음/로딩 실패 시
          errorWidget: (ctx, url, err) => Center(child: ErrorImagePlaceholder(size: imageSize)),
        );
      },
    );
  }

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
