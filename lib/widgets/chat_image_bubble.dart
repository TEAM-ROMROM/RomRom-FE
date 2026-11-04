import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/app_image_cache_manager.dart';
import 'package:romrom_fe/utils/image_decode_size.dart';
import 'package:romrom_fe/widgets/chat_room/chat_image_viewer_save_button.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

double _gapBase = 2.0;

// 4장 이상 줄 배치: 사진 수 > 줄별 사진 인덱스 (그리드 배치·셀 크기 계산 공통 원본)
const Map<int, List<List<int>>> _photoGridRowsByCount = {
  4: [
    [0, 1],
    [2, 3],
  ],
  5: [
    [0, 1],
    [2, 3, 4],
  ],
  6: [
    [0, 1, 2],
    [3, 4, 5],
  ],
  7: [
    [0, 1, 2],
    [3, 4],
    [5, 6],
  ],
  8: [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7],
  ],
  9: [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
  ],
  10: [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7],
    [8, 9],
  ],
};

/// 4장 이상 줄 높이: 4장은 2행(가로 절반), 그 외 3행(가로 1/3)
double _photoGridRowHeight(int photoCount, double width, double gap) =>
    photoCount == 4 ? (width - gap) / 2 : (width - gap * 2) / 3;

/// 셀 표시 크기 (논리 px): 1장 정사각형, 2장 반반, 3장 왼쪽 세로 긴 셀 + 오른쪽 2칸, 4장 이상 줄 배치 기준
/// 셀 이미지를 이 크기로 디코딩 > 레이아웃 측정 없이 고정 (Hero 비행 중 재디코딩 방지)
Size photoGridCellSize({required int photoCount, required int index, required double width, required double gap}) {
  final count = photoCount.clamp(1, 10);
  final halfSide = (width - gap) / 2;
  switch (count) {
    case 1:
      return Size(width, width);
    case 2:
      return Size(halfSide, halfSide);
    case 3:
      return index == 0 ? Size(halfSide, width) : Size(halfSide, halfSide);
  }
  final row = _photoGridRowsByCount[count]!.firstWhere((rowIndices) => rowIndices.contains(index));
  final cellWidth = (width - gap * (row.length - 1)) / row.length;
  return Size(cellWidth, _photoGridRowHeight(count, width, gap));
}

/// 그리드 칸 간격 (논리 px)
double get photoGridGap => _gapBase.w;

/// 셀 디코딩 크기 (물리 px): 셀 표시 크기 + cover 규칙 (서버 이미지 셀·업로드 중 말풍선 공통)
ImageDecodeSize photoGridCellDecodeSize({
  required int photoCount,
  required int index,
  required double width,
  required double devicePixelRatio,
}) {
  final cellSize = photoGridCellSize(photoCount: photoCount, index: index, width: width, gap: photoGridGap);
  return ImageDecodeSize.forDisplay(
    width: cellSize.width,
    height: cellSize.height,
    fit: BoxFit.cover,
    devicePixelRatio: devicePixelRatio,
  );
}

/// 1~10장 이미지를 그리드 레이아웃으로 표시하는 공통 빌더
/// [photoCount] 실제 이미지 수 (1~10 클램프됨)
/// [cellBuilder] 각 인덱스에 해당하는 셀 위젯 빌더
/// [width] 버블 전체 너비 (채팅 말풍선 264.w)
Widget buildPhotoGrid({
  required int photoCount,
  required Widget Function(int index) cellBuilder,
  required double width,
}) {
  final count = photoCount.clamp(1, 10);
  final w = width;
  final gap = photoGridGap;
  final h1 = (w - gap) / 2; // 2장 레이아웃 높이

  Widget makeRow(List<int> indices, double height) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < indices.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: cellBuilder(indices[i])),
        ],
      ],
    ),
  );

  final Widget grid = switch (count) {
    1 => SizedBox(height: w, child: cellBuilder(0)),
    2 => SizedBox(
      height: h1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cellBuilder(0)),
          SizedBox(width: gap),
          Expanded(child: cellBuilder(1)),
        ],
      ),
    ),
    3 => SizedBox(
      height: w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cellBuilder(0)),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cellBuilder(1)),
                SizedBox(height: gap),
                Expanded(child: cellBuilder(2)),
              ],
            ),
          ),
        ],
      ),
    ),
    _ => Column(
      children: [
        for (final (rowIndex, rowIndices) in _photoGridRowsByCount[count]!.indexed) ...[
          if (rowIndex > 0) SizedBox(height: gap),
          makeRow(rowIndices, _photoGridRowHeight(count, w, gap)),
        ],
      ],
    ),
  };

  return SizedBox(width: w, child: grid);
}

Widget chatImageBubble(BuildContext context, ChatMessage message) {
  final urls = message.imageUrls ?? const [];
  if (urls.isEmpty) return const SizedBox.shrink();

  final base = message.chatMessageId ?? 'local_${message.createdDate?.microsecondsSinceEpoch ?? message.hashCode}';
  String heroTag(int index) => 'chat_image_${base}_$index';

  // 셀별 디코딩 크기: 셀 표시 크기 기준 고정 (전체 보기 로딩 중 미리보기도 같은 메모리 캐시 키 사용)
  final bubbleWidth = 264.w;
  final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  ImageDecodeSize cellDecodeSize(int index) => photoGridCellDecodeSize(
    photoCount: urls.length,
    index: index,
    width: bubbleWidth,
    devicePixelRatio: devicePixelRatio,
  );

  void onTap(int initialPage) {
    // 저장 버튼이 읽을 현재 장 (넘길 때마다 갱신)
    final pageTracker = PhotoViewerPageTracker(currentPageIndex: initialPage);
    showPhotoViewer(
      context: context,
      heroTagBuilder: heroTag,
      onPageChanged: (pageIndex) => pageTracker.currentPageIndex = pageIndex,
      overlayBuilder: (_) => ChatImageViewerSaveButton(imageUrls: urls, pageTracker: pageTracker),
      builders: urls.indexed.map<WidgetBuilder>((indexedUrl) {
        final (index, url) = indexedUrl;
        // 전체 보기는 확대용 원본 해상도, 디코딩 중에는 셀 이미지 > 없으면 스피너
        return (_) => CachedNetworkImage(
          imageUrl: url,
          cacheManager: AppImageCacheManager.instance,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (_, _) => _buildViewerLoadingPreview(url, cellDecodeSize(index)),
          errorWidget: (_, _, _) => const Center(child: ErrorImagePlaceholder()),
        );
      }).toList(),
      initialPage: initialPage,
    );
  }

  // 셀 크기로 디코딩 (원본 디코딩 시 10장 묶음 메모리 급증)
  Widget cell(int index) {
    final decodeSize = cellDecodeSize(index);
    return GestureDetector(
      onTap: () => onTap(index),
      child: Hero(
        tag: heroTag(index),
        child: CachedNetworkImage(
          imageUrl: urls[index],
          cacheManager: AppImageCacheManager.instance,
          fit: BoxFit.cover,
          memCacheWidth: decodeSize.width,
          memCacheHeight: decodeSize.height,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          // 셀 이미지 로딩 중 스피너
          placeholder: (_, _) => const ColoredBox(
            color: AppColors.opacity10White,
            child: Center(child: CommonLoadingIndicator()),
          ),
          errorWidget: (_, _, _) => const Center(child: ErrorImagePlaceholder()),
        ),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(10.r),
    child: buildPhotoGrid(photoCount: urls.length, cellBuilder: cell, width: bubbleWidth),
  );
}

/// 전체 보기 원본 디코딩 중 미리보기: 셀 이미지(메모리 캐시), 셀 이미지도 없으면 스피너
Widget _buildViewerLoadingPreview(String url, ImageDecodeSize cellDecodeSize) {
  const loadingIndicator = Center(child: CommonLoadingIndicator(size: 32.0));
  return CachedNetworkImage(
    imageUrl: url,
    cacheManager: AppImageCacheManager.instance,
    fit: BoxFit.contain,
    memCacheWidth: cellDecodeSize.width,
    memCacheHeight: cellDecodeSize.height,
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    placeholderFadeInDuration: Duration.zero,
    placeholder: (_, _) => loadingIndicator,
    errorWidget: (_, _, _) => loadingIndicator,
  );
}
