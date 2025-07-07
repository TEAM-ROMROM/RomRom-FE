import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 라벨
class RegisterCustomTextFieldLabel extends StatelessWidget {
  final String label;
  const RegisterCustomTextFieldLabel({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0.h),
      child: Text(label, style: CustomTextStyles.p1),
    );
  }
}

/// 내용 입력 Field
class RegisterCustomTextField extends StatelessWidget {
  final String hintText;
  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final Widget? suffixIcon;
  final String suffixText;
  final VoidCallback? onTap;

  const RegisterCustomTextField({
    super.key,
    required this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.readOnly = false,
    this.suffixIcon,
    this.suffixText = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(
        color: AppColors.opacity30White,
        width: 1.5.w,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
          cursorColor: AppColors.textColorWhite,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.opacity10White,
            border: inputBorder,
            enabledBorder: inputBorder,
            focusedBorder: inputBorder,
            hintStyle:
                CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
            counterText: '', // 기본 counter 숨김
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            suffixIcon: suffixIcon,
            suffixText: suffixText,
            suffixStyle:
                CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
          ),
        ),
        if (maxLength != null && controller != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller!,
            builder: (context, value, child) {
              final currentLength = value.text.length;
              return Padding(
                padding: EdgeInsets.only(top: 8.0.h),
                child: Text(
                  '$currentLength/$maxLength',
                  style: CustomTextStyles.p3
                      .copyWith(color: AppColors.opacity50White),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// 라벨 + 내용 Field
class RegisterCustomLabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  final double spacing;

  const RegisterCustomLabeledField({
    super.key,
    required this.label,
    required this.field,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterCustomTextFieldLabel(label: label),
        field,
        SizedBox(height: spacing.h),
      ],
    );
  }
}
