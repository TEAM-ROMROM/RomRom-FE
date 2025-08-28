import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

class ItemDetailImageContainer extends StatelessWidget {
  final int index;
  final String imageUrl;
  final Size size;
  final String heroTag;
  final ValueNotifier<int> currentIndexVN;

  const ItemDetailImageContainer({
    super.key,
    required this.index,
    required this.imageUrl,
    required this.size,
    required this.heroTag,
    required this.currentIndexVN,
  });

  /// 이미지 로더: 오류 시 플레이스홀더
  Widget _buildImage(String url, Size size) {
    final placeholder = ErrorImagePlaceholder(size: size);

    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return placeholder;

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Detail 이미지 로드 실패: $trimmed, error: $error');
        return placeholder;
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryYellow,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _buildImage(imageUrl, size);

    return ValueListenableBuilder<int>(
      valueListenable: currentIndexVN,
      builder: (_, current, __) {
        // 현재 보이는 페이지만 Hero 활성화 → 중복 태그 문제/리빌드 최소화
        return HeroMode(
          enabled: current == index,
          child: Hero(
            tag: heroTag,
            transitionOnUserGestures: true,
            child: image,
          ),
        );
      },
    );
  }
}
