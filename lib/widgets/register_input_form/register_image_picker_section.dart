// 물품 등록 사진 영역: 추가 버튼(개수 표시), 가로 썸네일 목록(전체 보기·삭제), 사진 없음 안내
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

/// 사진 목록 순서: 기존 서버 사진 > 새로 고른 로컬 사진 (index 공통)
class RegisterImagePickerSection extends StatelessWidget {
  // 수정 모드: 기존 서버 사진 주소
  final List<String> existingImageUrls;
  // 새로 고른 로컬 사진 경로 (아직 업로드 안 됨)
  final List<String> newImagePaths;
  // 사진 선택 시도 후 0장이면 안내 표시
  final bool shouldShowEmptyImageError;
  final VoidCallback onAddImageTap;
  final ValueChanged<int> onImageTap;
  final ValueChanged<int> onDeleteImageTap;

  const RegisterImagePickerSection({
    super.key,
    required this.existingImageUrls,
    required this.newImagePaths,
    required this.shouldShowEmptyImageError,
    required this.onAddImageTap,
    required this.onImageTap,
    required this.onDeleteImageTap,
  });

  int get _totalImageCount => existingImageUrls.length + newImagePaths.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAddImageButton(),
            SizedBox(width: 8.w),
            Expanded(
              child: SizedBox(
                height: 88.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _totalImageCount,
                  separatorBuilder: (_, index) => SizedBox(width: 8.w),
                  padding: EdgeInsets.only(top: 8.h),
                  itemBuilder: (context, index) => _buildThumbnail(index),
                ),
              ),
            ),
          ],
        ),
        if (shouldShowEmptyImageError)
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
            child: Row(
              children: [
                Text('상품 사진을 최소 1장 이상 등록해주세요', style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder)),
              ],
            ),
          ),
      ],
    );
  }

  /// 사진 추가 버튼 (현재 장수/10)
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: onAddImageTap,
      child: Container(
        width: 80.w,
        height: 80.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.opacity40White, width: 1.5.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 6.h),
            Icon(AppIcons.itmeRegisterImage, color: AppColors.opacity60White, size: 18.sp),
            SizedBox(height: 4.h),
            Text('$_totalImageCount/10', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity40White)),
          ],
        ),
      ),
    );
  }

  /// 썸네일 1장: 탭 > 전체 보기, 우상단 X > 삭제
  Widget _buildThumbnail(int index) {
    return SizedBox(
      height: 88.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => onImageTap(index),
            child: Hero(
              tag: 'item_image_$index',
              child: ClipRRect(borderRadius: BorderRadius.circular(10.r), child: _buildThumbnailImage(index)),
            ),
          ),
          Positioned(
            top: -6.h,
            right: -6.h,
            child: GestureDetector(
              onTap: () => onDeleteImageTap(index),
              child: Container(
                width: 22.h,
                height: 22.h,
                decoration: const BoxDecoration(
                  color: AppColors.itemPictureRemoveButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Icon(AppIcons.cancel, color: AppColors.textColorBlack, size: 12.sp, semanticLabel: '사진 삭제'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기존 서버 사진 > CachedImage, 새 로컬 사진 > Image.file
  Widget _buildThumbnailImage(int index) {
    final int existingCount = existingImageUrls.length;
    if (index < existingCount) {
      return CachedImage(
        imageUrl: existingImageUrls[index],
        width: 80.w,
        height: 80.h,
        fit: BoxFit.cover,
        errorWidget: Container(
          color: AppColors.opacity40White,
          child: const Icon(Icons.broken_image, color: AppColors.textColorWhite),
        ),
      );
    }
    return Image.file(
      File(newImagePaths[index - existingCount]),
      width: 80.w,
      height: 80.h,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Container(
        width: 80.w,
        height: 80.h,
        color: AppColors.opacity40White,
        child: const Icon(Icons.broken_image, color: AppColors.textColorWhite),
      ),
    );
  }
}
