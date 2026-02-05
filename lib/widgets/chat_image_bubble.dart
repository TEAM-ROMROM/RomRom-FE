import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

Widget chatImageBubble(BuildContext context, ChatMessage message) {
  final urls = message.imageUrls ?? const [];
  if (urls.isEmpty) return const SizedBox.shrink();

  final base = message.chatMessageId ?? 'local_${message.createdDate?.microsecondsSinceEpoch ?? message.hashCode}';

  String heroTag(int index) => 'chat_image_${base}_$index';

  return GestureDetector(
    onTap: () {
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
            placeholder: (_, __) => const Center(
              child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: AppColors.primaryYellow)),
            ),
            errorWidget: (_, __, ___) => const Center(child: ErrorImagePlaceholder()),
          );
        }).toList(),
        initialPage: 0,
      );
    },
    child: Hero(
      tag: heroTag(0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 264.w,
          constraints: BoxConstraints(maxHeight: 264.h),
          child: CachedNetworkImage(
            imageUrl: urls.first,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            placeholder: (_, __) => const ColoredBox(
              color: AppColors.opacity10White,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(color: AppColors.primaryYellow),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => const Center(child: ErrorImagePlaceholder()),
          ),
        ),
      ),
    ),
  );
}
