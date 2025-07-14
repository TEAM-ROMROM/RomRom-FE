import 'package:flutter/material.dart';

import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ErrorImagePlaceholder extends StatelessWidget {
  // Reusable placeholder for failed or empty network images
  final Size? size;
  final BorderRadius? borderRadius;

  const ErrorImagePlaceholder({super.key, this.size, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: size?.width,
      height: size?.height,
      color: AppColors.imagePlaceholderBackground,
      alignment: Alignment.center,
      child: const Icon(
        AppIcons.warning,
        color: AppColors.textColorWhite,
        size: 64,
      ),
    );

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
} 