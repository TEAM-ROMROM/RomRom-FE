import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 거래 후기 만족도 등급
enum TradeReviewRating {
  bad(
    label: '별로예요',
    serverName: 'BAD',
    selectedColor: AppColors.reviewRatingBad,
    selectedBackgroundColor: AppColors.reviewRatingBadBackground,
    selectedImgAsset: 'assets/images/review-bad-selected.svg',
    unselectedImgAsset: 'assets/images/review-bad-unselected.svg',
  ),
  good(
    label: '좋아요',
    serverName: 'GOOD',
    selectedColor: AppColors.reviewRatingGood,
    selectedBackgroundColor: AppColors.reviewRatingGoodBackground,
    selectedImgAsset: 'assets/images/review-good-selected.svg',
    unselectedImgAsset: 'assets/images/review-good-unselected.svg',
  ),
  great(
    label: '최고에요',
    serverName: 'GREAT',
    selectedColor: AppColors.reviewRatingGreat,
    selectedBackgroundColor: AppColors.reviewRatingGreatBackground,
    selectedImgAsset: 'assets/images/review-great-selected.svg',
    unselectedImgAsset: 'assets/images/review-great-unselected.svg',
  );

  final String label;
  final String serverName;
  final Color selectedColor;
  final Color selectedBackgroundColor;
  final String selectedImgAsset;
  final String unselectedImgAsset;

  const TradeReviewRating({
    required this.label,
    required this.serverName,
    required this.selectedColor,
    required this.selectedBackgroundColor,
    required this.selectedImgAsset,
    required this.unselectedImgAsset,
  });
}
