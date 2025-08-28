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
class RegisterCustomTextField extends StatefulWidget {
  final ItemTextFieldPhrase phrase;

  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final Widget? suffixIcon;
  final String prefixText;
  final VoidCallback? onTap;
  final bool? forceValidate; // 강제로 유효성 검사를 실행할지 여부

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
    this.forceValidate,
  });

  @override
  State<RegisterCustomTextField> createState() => _RegisterCustomTextFieldState();
}

class _RegisterCustomTextFieldState extends State<RegisterCustomTextField> {
  bool _hasLostFocus = false; // 포커스를 잃은 적이 있는지
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      // 포커스를 잃었을 때만 validation 시작
      if (!_focusNode.hasFocus && !_hasLostFocus) {
        setState(() {
          _hasLostFocus = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
    final isNumberField = widget.keyboardType == TextInputType.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        isNumberField && widget.controller != null
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller!,
                builder: (context, value, child) {
                  // 커서 위치 보정
                  final formatted = formatPrice(int.tryParse(
                          value.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0);

                  if (value.text != formatted) {
                    widget.controller!.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  
                  // 가격 유효성 검사 (포커스를 잃었거나 강제 검증일 때)
                  final price = int.tryParse(value.text.replaceAll(',', '')) ?? 0;
                  bool shouldShowError = (_hasLostFocus || widget.forceValidate == true) && price == 0;
                  
                  // number field일 때
                  return TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    style: CustomTextStyles.p2
                        .copyWith(color: AppColors.textColorWhite),
                    cursorColor: AppColors.textColorWhite,
                    decoration: InputDecoration(
                      hintText: widget.phrase.hintText,
                      filled: true,
                      fillColor: shouldShowError
                          ? AppColors.errorContainer
                          : AppColors.opacity10White,
                      border: shouldShowError ? errorBorder : inputBorder,
                      enabledBorder: shouldShowError ? errorBorder : inputBorder,
                      focusedBorder: shouldShowError ? errorBorder : inputBorder,
                      hintStyle: CustomTextStyles.p2
                          .copyWith(color: AppColors.opacity40White),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      suffixIcon: widget.suffixIcon,
                      prefix: widget.prefixText.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(right: 8.0.w),
                              child: Text(
                                widget.prefixText,
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
                valueListenable: widget.controller!,
                builder: (context, value, child) {
                  // 에러 표시 조건: 포커스를 잃었거나 강제 검증일 때
                  bool shouldShowError = false;
                  if (_hasLostFocus || widget.forceValidate == true) {
                    if (widget.phrase == ItemTextFieldPhrase.description) {
                      shouldShowError = value.text.trim().isEmpty || value.text.trim().length < 30;
                    } else {
                      shouldShowError = value.text.trim().isEmpty;
                    }
                  }
                  
                  return TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    style: CustomTextStyles.p2
                        .copyWith(color: AppColors.textColorWhite, height: 1.4),
                    cursorColor: AppColors.textColorWhite,
                    decoration: InputDecoration(
                      hintText: widget.phrase.hintText,
                      filled: true,
                      fillColor: shouldShowError
                          ? AppColors.errorContainer
                          : AppColors.opacity10White,
                      border: shouldShowError
                          ? errorBorder
                          : inputBorder,
                      enabledBorder: shouldShowError
                          ? errorBorder
                          : inputBorder,
                      focusedBorder: shouldShowError
                          ? errorBorder
                          : inputBorder,
                      hintStyle: CustomTextStyles.p2
                          .copyWith(color: AppColors.opacity40White),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      suffixIcon: widget.suffixIcon,
                      errorBorder: errorBorder,
                      prefix: widget.prefixText.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(right: 8.0.w),
                              child: Text(
                                widget.prefixText,
                                style: CustomTextStyles.p2
                                    .copyWith(color: AppColors.textColorWhite),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
        // 에러 메시지 및 카운터
        if (widget.controller != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller!,
            builder: (context, value, child) {
              final currentLength = value.text.length;
              bool shouldShowError = false;
              String errorMessage = '';
              
              if (_hasLostFocus || widget.forceValidate == true) {
                if (widget.keyboardType == TextInputType.number) {
                  // 가격 필드
                  final price = int.tryParse(value.text.replaceAll(',', '')) ?? 0;
                  if (price == 0) {
                    shouldShowError = true;
                    errorMessage = '가격은 0원보다 커야 합니다';
                  }
                } else if (widget.phrase == ItemTextFieldPhrase.description) {
                  if (value.text.trim().isEmpty) {
                    shouldShowError = true;
                    errorMessage = widget.phrase.errorText;
                  } else if (value.text.trim().length < 30) {
                    shouldShowError = true;
                    errorMessage = '설명은 최소 30자 이상 입력해주세요';
                  }
                } else if (value.text.trim().isEmpty) {
                  shouldShowError = true;
                  errorMessage = widget.phrase.errorText;
                }
              }
              
              return Padding(
                padding: EdgeInsets.only(top: 8.0.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shouldShowError ? errorMessage : '',
                      style: CustomTextStyles.p3
                          .copyWith(color: AppColors.errorBorder),
                    ),
                    // 카운터는 maxLength가 있고, 카테고리가 아닌 경우에만 표시
                    if (widget.maxLength != null && widget.phrase.name != ItemTextFieldPhrase.category.name)
                      Text(
                        '$currentLength/${widget.maxLength}',
                        style: CustomTextStyles.p3
                            .copyWith(color: AppColors.opacity50White),
                      ),
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