import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

double _gapBase = 2.0;

/// 1~10장 이미지를 그리드 레이아웃으로 표시하는 공통 빌더
/// [photoCount] 실제 이미지 수 (1~10 클램프됨)
/// [cellBuilder] 각 인덱스에 해당하는 셀 위젯 빌더
/// [width] 버블 전체 너비 (기본 264.w)
Widget buildPhotoGrid({
  required int photoCount,
  required Widget Function(int index) cellBuilder,
  required double width,
}) {
  final count = photoCount.clamp(1, 10);
  final w = width;
  double gap = _gapBase.w;
  final h1 = (w - gap) / 2; // 2행 레이아웃 행 높이
  final h3 = (w - gap * 2) / 3; // 3행 레이아웃 행 높이

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
    4 => Column(
      children: [
        makeRow([0, 1], h1),
        SizedBox(height: gap),
        makeRow([2, 3], h1),
      ],
    ),
    5 => Column(
      children: [
        makeRow([0, 1], h3),
        SizedBox(height: gap),
        makeRow([2, 3, 4], h3),
      ],
    ),
    6 => Column(
      children: [
        makeRow([0, 1, 2], h3),
        SizedBox(height: gap),
        makeRow([3, 4, 5], h3),
      ],
    ),
    7 => Column(
      children: [
        makeRow([0, 1, 2], h3),
        SizedBox(height: gap),
        makeRow([3, 4], h3),
        SizedBox(height: gap),
        makeRow([5, 6], h3),
      ],
    ),
    8 => Column(
      children: [
        makeRow([0, 1, 2], h3),
        SizedBox(height: gap),
        makeRow([3, 4, 5], h3),
        SizedBox(height: gap),
        makeRow([6, 7], h3),
      ],
    ),
    9 => Column(
      children: [
        makeRow([0, 1, 2], h3),
        SizedBox(height: gap),
        makeRow([3, 4, 5], h3),
        SizedBox(height: gap),
        makeRow([6, 7, 8], h3),
      ],
    ),
    _ => Column(
      children: [
        makeRow([0, 1, 2], h3),
        SizedBox(height: gap),
        makeRow([3, 4, 5], h3),
        SizedBox(height: gap),
        makeRow([6, 7], h3),
        SizedBox(height: gap),
        makeRow([8, 9], h3),
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

  void onTap(int initialPage) {
    showPhotoViewer(
      context: context,
      heroTagBuilder: heroTag,
      builders: urls.map<WidgetBuilder>((url) {
        return (_) => CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (_, _) => const Center(
            child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: AppColors.primaryYellow)),
          ),
          errorWidget: (_, _, _) => const Center(child: ErrorImagePlaceholder()),
        );
      }).toList(),
      initialPage: initialPage,
    );
  }

  Widget cell(int index) => GestureDetector(
    onTap: () => onTap(index),
    child: Hero(
      tag: heroTag(index),
      child: CachedNetworkImage(
        imageUrl: urls[index],
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, _) => const ColoredBox(
          color: AppColors.opacity10White,
          child: Center(
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.primaryYellow)),
          ),
        ),
        errorWidget: (_, _, _) => const Center(child: ErrorImagePlaceholder()),
      ),
    ),
  );

  return ClipRRect(
    borderRadius: BorderRadius.circular(10.r),
    child: buildPhotoGrid(photoCount: urls.length, cellBuilder: cell, width: 264.w),
  );
}
