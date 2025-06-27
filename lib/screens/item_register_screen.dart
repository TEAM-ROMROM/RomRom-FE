import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/transaction_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';

class ItemRegisterScreen extends StatefulWidget {
  const ItemRegisterScreen({super.key});

  @override
  State<ItemRegisterScreen> createState() => _ItemRegisterScreenState();
}

class _ItemRegisterScreenState extends State<ItemRegisterScreen> {
  // 임시 상태 변수들
  int imageCount = 0;
  String? selectedCategory;
  String? selectedCondition;
  List<String> selectedItemConditionTypes = [];
  List<String> selectedTransactionTypes = [];
  bool useAiPrice = false;

  // 각 TextField의 controller 추가
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  // itemMethodOptions TransactionType name 리스트로 변경
  List<String> itemTransactionOptions =
      TransactionType.values.map((e) => e.name).toList();
  // itemConditonOptions ItemCondition의 name 리스트로 변경
  List itemConditonOptions = ItemCondition.values.map((e) => e.name).toList();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: const CommonAppBar(title: '물건 등록하기'),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 업로드
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                        color: AppColors.opacity40White, width: 1.5.w)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/item-register-photo.svg'),
                    SizedBox(
                      height: 4.h,
                    ),
                    Text('$imageCount/10',
                        style: CustomTextStyles.p3
                            .copyWith(color: AppColors.opacity40White)),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 제목
              _LabeledField(
                label: '제목',
                field: _CustomTextField(
                  hintText: '제목을 입력하세요',
                  maxLength: 20,
                  controller: titleController,
                ),
              ),

              // 카테고리
              _LabeledField(
                label: '카테고리',
                field: _CustomTextField(
                  hintText: '카테고리를 선택하세요',
                  controller:
                      TextEditingController(text: selectedCategory ?? ''),
                  readOnly: true,
                  onTap: () async {
                    final categories = ['전자기기', '의류', '도서', '가구', '기타'];
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      isScrollControlled: true,
                      builder: (context) {
                        String? tempSelected = selectedCategory;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                            left: 0,
                            right: 0,
                            top: 24,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(
                                spacing: 8,
                                children: categories.map((category) {
                                  return ChoiceChip(
                                    label: Text(category,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    selected: tempSelected == category,
                                    selectedColor: Colors.amber,
                                    backgroundColor: Colors.grey[800],
                                    onSelected: (_) {
                                      tempSelected = category;
                                      Navigator.pop(context, category);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        selectedCategory = selected;
                      });
                    }
                  },
                ),
              ),

              // 물건 설명
              _LabeledField(
                label: '물건 설명',
                field: _CustomTextField(
                  hintText: '물건의 자세한 설명을 적어주세요',
                  controller: descriptionController,
                  maxLength: 1000,
                  maxLines: 5,
                ),
              ),

              // 물건 상태
              _LabeledField(
                label: '물건 상태',
                field: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.w,
                  children: itemConditonOptions
                      .map((option) => RegisterOptionChip(
                            itemOption: option,
                            isSelected:
                                selectedItemConditionTypes.contains(option),
                            onTap: () {
                              setState(() {
                                if (selectedItemConditionTypes
                                    .contains(option)) {
                                  selectedItemConditionTypes.clear();
                                } else {
                                  selectedItemConditionTypes
                                    ..clear()
                                    ..add(option);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ),

              // 거래방식
              _LabeledField(
                label: '거래방식',
                field: Wrap(
                  spacing: 8.w,
                  children: itemTransactionOptions
                      .map((option) => RegisterOptionChip(
                            itemOption: option,
                            isSelected:
                                selectedTransactionTypes.contains(option),
                            onTap: () {
                              setState(() {
                                if (selectedTransactionTypes.contains(option)) {
                                  selectedTransactionTypes.remove(option);
                                } else {
                                  selectedTransactionTypes.add(option);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ),

              // 적정 가격 + AI 추천 가격
              Row(
                children: [
                  const _Label(label: '적정 가격'),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.aiSuggestionContainerBackground,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: GradientText(
                      text: 'AI 추천 가격',
                      style:
                          CustomTextStyles.p3.copyWith(letterSpacing: -0.5.sp),
                      gradient: const LinearGradient(
                        colors: AppColors.aiGradient,
                        stops: [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 4.w,
                  ),
                  AnimatedToggleSwitch.dual(
                    current: useAiPrice,
                    first: false,
                    second: true,
                    spacing: 2.0.w,
                    height: 20.h,
                    style: ToggleStyle(
                      indicatorColor: AppColors.textColorWhite,
                      borderRadius: BorderRadius.all(Radius.circular(100.r)),
                      indicatorBoxShadow: [
                        const BoxShadow(
                            color: AppColors.toggleSwitchIndicatorShadow,
                            offset: Offset(-1, 0),
                            blurRadius: 2)
                      ],
                    ),
                    indicatorSize: Size(18.w, 18.h),
                    borderWidth: 0,
                    padding: EdgeInsets.all(1.w),
                    onChanged: (b) => setState(() => useAiPrice = b),
                    styleBuilder: (b) => ToggleStyle(
                      backgroundGradient: b
                          ? const LinearGradient(
                              colors: AppColors.aiGradient,
                            )
                          : const LinearGradient(colors: [
                              AppColors.opacity40White,
                              AppColors.opacity40White
                            ]),
                    ),
                  ),
                ],
              ),
              _CustomTextField(
                hintText: '10000원',
                keyboardType: TextInputType.number,
                controller: priceController,
              ),
              SizedBox(height: 24.w),

              // 거래 희망 위치
              _LabeledField(
                label: '거래 희망 위치',
                field: _CustomTextField(
                  readOnly: true,
                  hintText: '거래 희망 위치를 선택하세요',
                  suffixIcon: Icon(
                    AppIcons.detailView,
                    color: AppColors.textColorWhite,
                    size: 18.w,
                  ),
                  controller: locationController,
                ),
                spacing: 32,
              ),

              // 등록 완료 버튼
              const CompletionButton(
                isEnabled: true,
                buttonText: '등록 완료',
                buttonType: 2,
              ),
              SizedBox(height: 24.w),
            ],
          ),
        ),
      ),
    );
  }
}

/// 라벨
class _Label extends StatelessWidget {
  final String label;
  const _Label({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0.h),
      child: Text(label, style: CustomTextStyles.p1),
    );
  }
}

/// 내용 입력 Field
class _CustomTextField extends StatelessWidget {
  final String hintText;
  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  const _CustomTextField({
    required this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.readOnly = false,
    this.suffixIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: AppColors.opacity30White, width: 1.5),
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
          ),
        ),
        if (maxLength != null)
          Builder(
            builder: (context) {
              final currentLength = controller?.text.length ?? 0;
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
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  final double spacing;

  const _LabeledField({
    required this.label,
    required this.field,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label),
        field,
        SizedBox(height: spacing.h),
      ],
    );
  }
}
