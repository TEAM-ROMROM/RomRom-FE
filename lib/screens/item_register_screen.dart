import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/screens/item_register_location_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';
import 'package:romrom_fe/widgets/register_text_field.dart';

/// 물품 등록 화면
class ItemRegisterScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ItemRegisterScreen({super.key, this.onClose});

  @override
  State<ItemRegisterScreen> createState() => _ItemRegisterScreenState();
}

class _ItemRegisterScreenState extends State<ItemRegisterScreen> {
  // 임시 상태 변수들
  int imageCount = 0;
  ItemCategories? selectedCategory;
  ItemCondition? selectedCondition;
  List<ItemCondition> selectedItemConditionTypes = [];
  List<ItemTradeOption> selectedTradeOptions = [];
  bool useAiPrice = false;

  // 각 TextField의 controller 추가
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController =
      TextEditingController(text: '0');
  final TextEditingController locationController = TextEditingController();
  // itemMethodOptions ItemTradeOption name 리스트로 변경
  List<ItemTradeOption> itemTradeOptions = ItemTradeOption.values;
  // itemConditonOptions ItemCondition의 name 리스트로 변경
  List<ItemCondition> itemConditonOptions = ItemCondition.values;

  final ImagePicker _picker = ImagePicker();
  List<XFile> imageFiles = []; // 선택된 이미지 저장

  // 상품사진 갤러리에서 가져오는 함수
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFiles.add(picked);
        imageCount = imageFiles.length.clamp(0, 10);
      });
    }
  }

  // ai 가격 측정 함수
  Future<void> _measureAiPrice() async {
    final predictedPrice = await ItemApi().pricePredict(ItemRequest(
      itemName: titleController.text,
      itemDescription: descriptionController.text,
      itemCondition: selectedItemConditionTypes.isNotEmpty
          ? selectedItemConditionTypes.first.serverName
          : null,
    ));
    setState(() {
      priceController.text = predictedPrice.toString();
    });
  }

  /// 폼 유효성 검사
  /// 모든 필드가 채워져 있는지 확인
  bool get isFormValid {
    return titleController.text.isNotEmpty &&
        selectedCategory != null &&
        descriptionController.text.isNotEmpty &&
        selectedItemConditionTypes.isNotEmpty &&
        selectedTradeOptions.isNotEmpty &&
        priceController.text != '0' &&
        locationController.text.isNotEmpty &&
        imageFiles.isNotEmpty;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

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
        appBar: CommonAppBar(
          title: '물건 등록하기',
          onBackPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            }
          },
          showBottomBorder: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(top: 24.h, bottom: 24.h, left: 24.w),
          child: Column(
            children: [
              // 이미지 업로드
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 이미지 업로드 버튼
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                            color: AppColors.opacity40White, width: 1.5.w),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                              'assets/images/item-register-photo.svg'),
                          SizedBox(height: 4.h),
                          Text('$imageCount/10',
                              style: CustomTextStyles.p3
                                  .copyWith(color: AppColors.opacity40White)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // 이미지 미리보기 썸네일
                  Expanded(
                    child: SizedBox(
                      height: 88.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageFiles.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        padding: EdgeInsets.only(top: 8.h),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: 88.h,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.file(
                                    File(imageFiles[index].path),
                                    width: 80.w,
                                    height: 80.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: -8.h,
                                  right: -8.w,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        imageFiles.removeAt(index);
                                        imageCount = imageFiles.length;
                                      });
                                    },
                                    child: Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: const BoxDecoration(
                                        color: AppColors
                                            .itemPictureRemoveButtonBackground,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        AppIcons.cancel,
                                        color: AppColors.primaryBlack,
                                        size: 16.w,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(right: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24.h,
                    ),

                    // 제목 필드
                    RegisterCustomLabeledField(
                      label: '제목',
                      field: RegisterCustomTextField(
                        hintText: '제목을 입력하세요',
                        maxLength: 20,
                        controller: titleController,
                      ),
                    ),

                    // 카테고리 필드
                    RegisterCustomLabeledField(
                      label: '카테고리',
                      field: StatefulBuilder(
                        builder: (context, setModalState) {
                          return RegisterCustomTextField(
                            hintText: '카테고리를 선택하세요',
                            controller: TextEditingController(
                                text: selectedCategory?.name ?? ''),
                            readOnly: true,
                            onTap: () async {
                              const categories = ItemCategories.values;
                              ItemCategories? tempSelected = selectedCategory;
                              await showModalBottomSheet<void>(
                                context: context,
                                backgroundColor: AppColors.primaryBlack,
                                barrierColor: AppColors.opacity80Black,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                isScrollControlled: true,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setInnerState) {
                                      return SizedBox(
                                        height: 502.h,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14.0.h),
                                                child: Container(
                                                  width: 50.w,
                                                  height: 4.h,
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .opacity50White,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.r),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(left: 26.w),
                                              child: Text(
                                                '카테고리',
                                                style: CustomTextStyles.h2
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ),
                                            SizedBox(
                                              width: double.infinity,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    right: 26.w,
                                                    left: 26.w,
                                                    top: 24.h),
                                                child: Wrap(
                                                  spacing: 8.0.w,
                                                  runSpacing: 12.0.h,
                                                  children: categories
                                                      .map((category) {
                                                    final isSelected =
                                                        tempSelected ==
                                                            category;
                                                    return CategoryChip(
                                                      label: category.name,
                                                      isSelected: isSelected,
                                                      onTap: () {
                                                        setInnerState(() {
                                                          tempSelected =
                                                              category;
                                                        });
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                              setState(() {
                                selectedCategory = tempSelected;
                              }); // 선택 후 화면 갱신
                            },
                          );
                        },
                      ),
                    ),

                    // 물건 설명
                    RegisterCustomLabeledField(
                      label: '물건 설명',
                      field: RegisterCustomTextField(
                        hintText: '물건의 자세한 설명을 적어주세요',
                        controller: descriptionController,
                        maxLength: 1000,
                        maxLines: 8,
                      ),
                    ),

                    // 물건 상태
                    RegisterCustomLabeledField(
                      label: '물건 상태',
                      field: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.w,
                        children: itemConditonOptions
                            .map((option) => RegisterOptionChip(
                                  itemOption: option.name,
                                  isSelected: selectedItemConditionTypes
                                      .contains(option),
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
                    RegisterCustomLabeledField(
                      label: '거래방식',
                      field: Wrap(
                        spacing: 8.w,
                        children: itemTradeOptions
                            .map((option) => RegisterOptionChip(
                                  itemOption: option.name,
                                  isSelected:
                                      selectedTradeOptions.contains(option),
                                  onTap: () {
                                    setState(() {
                                      if (selectedTradeOptions
                                          .contains(option)) {
                                        selectedTradeOptions.remove(option);
                                      } else {
                                        selectedTradeOptions.add(option);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),

                    // 적정 가격 + AI 추천 가격
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('적정 가격', style: CustomTextStyles.p1),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.aiSuggestionContainerBackground,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: GradientText(
                            text: 'AI 추천 가격',
                            style: CustomTextStyles.p3
                                .copyWith(letterSpacing: -0.5.sp),
                            gradient: const LinearGradient(
                              colors: AppColors.aiGradient,
                              stops: [0.0, 0.35, 0.7, 1.0],
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        AnimatedToggleSwitch.dual(
                          current: useAiPrice,
                          first: false,
                          second: true,
                          spacing: 2.0.w,
                          height: 20.h,
                          style: ToggleStyle(
                            indicatorColor: AppColors.textColorWhite,
                            borderRadius:
                                BorderRadius.all(Radius.circular(100.r)),
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
                          onChanged: (b) {
                            setState(() => useAiPrice = b);
                            if (b &&
                                titleController.text.isNotEmpty &&
                                descriptionController.text.isNotEmpty &&
                                selectedItemConditionTypes.isNotEmpty) {
                              _measureAiPrice();
                            }
                          },
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
                    SizedBox(height: 8.w),
                    RegisterCustomTextField(
                      hintText: '가격을 입력해주세요',
                      suffixText: '원',
                      keyboardType: TextInputType.number,
                      controller: priceController,
                    ),
                    SizedBox(height: 24.w),

                    // 거래 희망 위치
                    RegisterCustomLabeledField(
                      label: '거래 희망 위치',
                      field: RegisterCustomTextField(
                        readOnly: true,
                        hintText: '거래 희망 위치를 선택하세요',
                        suffixIcon: Icon(
                          AppIcons.detailView,
                          color: AppColors.textColorWhite,
                          size: 18.w,
                        ),
                        controller: locationController,
                        onTap: () async {
                          final result =
                              await Navigator.of(context).push<LocationAddress>(
                            MaterialPageRoute(
                              builder: (_) => ItemRegisterLocationScreen(
                                onLocationSelected: (address) {
                                  locationController.text =
                                      '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
                                  // 필요하다면 address 전체를 상태로 저장
                                },
                              ),
                            ),
                          );
                          // Navigator.pop으로만 돌아온 경우도 처리
                          if (result != null) {
                            locationController.text =
                                '${result.siDo} ${result.siGunGu} ${result.eupMyoenDong}';
                          }
                        },
                      ),
                      spacing: 32,
                    ),

                    // 등록 완료 버튼
                    CompletionButton(
                      isEnabled: isFormValid,
                      buttonText: '등록 완료',
                      buttonType: 2,
                      enabledOnPressed: () {
                        ItemApi().postItem(ItemRequest(
                          itemName: titleController.text,
                          itemDescription: descriptionController.text,
                          itemCategory: selectedCategory!.serverName,
                          itemCondition: selectedItemConditionTypes.isNotEmpty
                              ? selectedItemConditionTypes.first.serverName
                              : null,
                          itemTradeOptions: selectedTradeOptions
                              .map((e) => e.serverName)
                              .toList(),
                          itemPrice: int.parse(priceController.text),
                          itemCustomTags: [],
                          itemImages:
                              imageFiles.map((e) => File(e.path)).toList(),
                        ));
                      },
                    ),
                    SizedBox(height: 24.w),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
