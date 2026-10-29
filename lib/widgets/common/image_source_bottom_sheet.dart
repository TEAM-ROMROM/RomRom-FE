import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 상품 사진 추가 시 입력 소스(촬영/앨범)를 고르는 공용 바텀시트.
///
/// 선택된 [ImagePickSource]를 반환하고, 취소(바깥 탭/뒤로가기) 시 null을 반환한다.
Future<ImagePickSource?> showImageSourceBottomSheet(BuildContext context) {
  return showModalBottomSheet<ImagePickSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ImageSourceSheet(),
  );
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  static TextStyle get _itemTextStyle =>
      CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: AppColors.textColorWhite);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          const SizedBox(height: 16),
          _SourceItem(
            icon: AppIcons.camera,
            label: '사진 촬영하기',
            textStyle: _itemTextStyle,
            onTap: () => Navigator.pop(context, ImagePickSource.camera),
          ),
          _SourceItem(
            icon: AppIcons.itmeRegisterImage,
            label: '앨범에서 선택하기',
            textStyle: _itemTextStyle,
            onTap: () => Navigator.pop(context, ImagePickSource.gallery),
          ),
          const SizedBox(height: 8),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  const _SourceItem({required this.icon, required this.label, required this.textStyle, required this.onTap});

  final IconData icon;
  final String label;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.opacity60White, size: 22),
              const SizedBox(width: 14),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
