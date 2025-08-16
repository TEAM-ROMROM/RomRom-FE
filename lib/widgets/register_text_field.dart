import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 라벨
class RegisterCustomTextFieldLabel extends StatelessWidget {
  final String label;
  const RegisterCustomTextFieldLabel({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0.h),
      child: label == ItemTextFieldPhrase.tradeOption.label
          ? Row(
              children: [
                Text(label, style: CustomTextStyles.p1),
                SizedBox(width: 8.w),
                Text(ItemTextFieldPhrase.tradeOption.hintText,
                    style: CustomTextStyles.p3
                        .copyWith(color: AppColors.opacity40White)),
              ],
            )
          : Text(label, style: CustomTextStyles.p1),
    );
  }
}

/// 내용 입력 Field
class RegisterCustomTextField extends StatelessWidget {
  final ItemTextFieldPhrase phrase;

  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final Widget? suffixIcon;
  final String prefixText;
  final VoidCallback? onTap;

  const RegisterCustomTextField({
    super.key,
    required this.phrase,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixText = '',
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
    OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(
        color: AppColors.errorBorder,
        width: 1.5.w,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    );
    final isNumberField = keyboardType == TextInputType.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        isNumberField && controller != null
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, value, child) {
                  // 커서 위치 보정
                  final formatted = formatPrice(int.tryParse(
                          value.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0);

                  if (value.text != formatted) {
                    controller!.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  // number field일 때
                  return TextField(
                    controller: controller,
                    maxLength: maxLength,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    readOnly: readOnly,
                    onTap: onTap,
                    style: CustomTextStyles.p2
                        .copyWith(color: AppColors.textColorWhite),
                    cursorColor: AppColors.textColorWhite,
                    decoration: InputDecoration(
                      hintText: phrase.hintText,
                      filled: true,
                      fillColor: AppColors.opacity10White,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                      hintStyle: CustomTextStyles.p2
                          .copyWith(color: AppColors.opacity40White),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      suffixIcon: suffixIcon,
                      prefix: prefixText.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(right: 8.0.w),
                              child: Text(
                                prefixText,
                                style: CustomTextStyles.p2
                                    .copyWith(color: AppColors.textColorWhite),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              )
            : ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, value, child) {
                  return TextField(
                    controller: controller,
                    maxLength: maxLength,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    readOnly: readOnly,
                    onTap: onTap,
                    style: CustomTextStyles.p2
                        .copyWith(color: AppColors.textColorWhite, height: 1.4),
                    cursorColor: AppColors.textColorWhite,
                    decoration: InputDecoration(
                      hintText: phrase.hintText,
                      filled: true,
                      fillColor: controller!.text.isNotEmpty
                          ? AppColors.opacity10White
                          : AppColors.errorContainer,
                      border: controller!.text.isNotEmpty
                          ? inputBorder
                          : errorBorder,
                      enabledBorder: controller!.text.isNotEmpty
                          ? inputBorder
                          : errorBorder,
                      focusedBorder: controller!.text.isNotEmpty
                          ? inputBorder
                          : errorBorder,
                      hintStyle: CustomTextStyles.p2
                          .copyWith(color: AppColors.opacity40White),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      suffixIcon: suffixIcon,
                      errorBorder: errorBorder,
                      prefix: prefixText.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(right: 8.0.w),
                              child: Text(
                                prefixText,
                                style: CustomTextStyles.p2
                                    .copyWith(color: AppColors.textColorWhite),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
        if (maxLength != null && controller != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller!,
            builder: (context, value, child) {
              final currentLength = value.text.length;
              return Padding(
                padding: EdgeInsets.only(top: 8.0.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller!.text.isNotEmpty ? '' : phrase.errorText,
                      style: CustomTextStyles.p3
                          .copyWith(color: AppColors.errorBorder),
                    ),
                    phrase.name != ItemTextFieldPhrase.category.name
                        ? Text(
                            '$currentLength/$maxLength',
                            style: CustomTextStyles.p3
                                .copyWith(color: AppColors.opacity50White),
                          )
                        : const SizedBox.shrink(),
                  ],
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
