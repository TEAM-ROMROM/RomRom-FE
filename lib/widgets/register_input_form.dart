import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/screens/item_register_location_screen.dart';
import 'package:romrom_fe/services/apis/image_api.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';
import 'package:romrom_fe/widgets/register_text_field.dart';
import 'package:romrom_fe/widgets/skeletons/register_input_form_skeleton.dart';

/// 물품 등록 입력 폼 위젯
/// 물품 등록 화면에서 사용되는 입력 폼 위젯
class RegisterInputForm extends StatefulWidget {
  final ItemResponse? itemResponse; // 수정 모드에서 사용
  final bool isEditMode;

  const RegisterInputForm({
    super.key,
    this.itemResponse,
    this.isEditMode = false,
  });

  @override
  State<RegisterInputForm> createState() => _RegisterInputFormState();
}

class _RegisterInputFormState extends State<RegisterInputForm> {
  // 임시 상태 변수들
  int imageCount = 0;
  final Set<int> _loadingImageIndices = {}; // 로딩 중인 이미지 인덱스 집합
  ItemCategories? selectedCategory;
  ItemCondition? selectedCondition;
  List<ItemCondition> selectedItemConditionTypes = [];
  List<ItemTradeOption> selectedTradeOptions = [];
  bool useAiPrice = false;
  double? _latitude;
  double? _longitude;
  LocationAddress? _selectedAddress;
  
  // 처음 포커스 받았는지 추적을 위한 변수
  bool _hasConditionBeenTouched = false;
  bool _hasTradeOptionBeenTouched = false;
  bool _hasImageBeenTouched = false; // 이미지 선택 시도 여부
  bool _hasCategoryBeenTouched = false;
  bool _forceValidateAll = false; // 제출 버튼 클릭 시 모든 필드 검증

  // itemMethodOptions ItemTradeOption name 리스트로 변경
  List<ItemTradeOption> itemTradeOptions = ItemTradeOption.values;
  // itemConditonOptions ItemCondition의 name 리스트로 변경
  List<ItemCondition> itemConditonOptions = ItemCondition.values;

  // 각 TextField의 controller 추가
  TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController =
      TextEditingController(text: '0');
  final TextEditingController locationController = TextEditingController();

  // 이미지 관련 변수들
  final ImagePicker _picker = ImagePicker();
  List<XFile> imageFiles = []; // 선택된 이미지 저장
  List<String> imageUrls = []; // 서버에 업로드된 이미지 URL 저장

  // 상품사진 갤러리에서 가져오는 함수
  static const int kMaxImages = 10;

// 상품사진 갤러리에서 가져오는 함수 (다중 선택 지원)
  Future<void> onPickImage() async {
    try {
      setState(() {
        _hasImageBeenTouched = true;
      });
      
      if (imageFiles.length == 10) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지는 최대 10장까지 등록할 수 있습니다.')),
          );
        }
        return;
      }
      final List<XFile> picked = await _picker.pickMultiImage();

      // 사용자가 취소했거나 선택 없음
      if (picked.isEmpty) return;

      // 남은 슬록 계산 (최대 10장)
      final int remain = (kMaxImages - imageFiles.length).clamp(0, kMaxImages);
      if (remain == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지는 최대 10장까지 등록할 수 있습니다.')),
          );
        }
        return;
      }

      // 초과 선택 분리
      final List<XFile> toAdd =
          picked.length > remain ? picked.sublist(0, remain) : picked;

      // 로딩 인덱스 계산 (추가될 위치 범위)
      final int startIndex = imageFiles.length;
      final int endIndexExclusive = startIndex + toAdd.length;

      setState(() {
        // 로딩 인덱스 등록
        for (int i = startIndex; i < endIndexExclusive; i++) {
          _loadingImageIndices.add(i);
        }
        // 파일 목록에 다중 추가
        imageFiles.addAll(toAdd);
        // 카운트 업데이트
        imageCount = imageFiles.length.clamp(0, kMaxImages);
      });

      try {
        // 여러 장 업로드 (API가 List<XFile> -> List<String> 반환한다고 가정)
        final List<String> urls = await ImageApi().uploadImages(toAdd);

        if (mounted) {
          setState(() {
            // 서버 URL 추가 (개수 불일치 대비하여 안전하게 처리)
            if (urls.isNotEmpty) {
              imageUrls.addAll(urls.take(toAdd.length));
            } else {
              // 필요 시: 업로드 실패한 항목 처리 로직 추가 가능
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드에 실패했습니다: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            for (int i = startIndex; i < endIndexExclusive; i++) {
              _loadingImageIndices.remove(i);
            }
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> onDeleteImage(int index) async {
    if (index < 0 || index >= imageUrls.length) return;

    setState(() {
      _loadingImageIndices.add(index);
      _hasImageBeenTouched = true;
    });

    try {
      final imageUrl = imageUrls[index];

      // 서버에 업로드된 이미지인지 확인 (예: http로 시작)
      final isNetwork =
          imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

      if (isNetwork && imageUrl.isNotEmpty) {
        try {
          await ImageApi().deleteImages([imageUrl]);
        } catch (e) {
          // 삭제 실패 시 무시하거나 에러 처리
        }
      }

      if (mounted) {
        setState(() {
          imageUrls.removeAt(index);
          imageFiles.removeAt(index);
          imageCount = imageUrls.length.clamp(0, 10);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 삭제에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingImageIndices.remove(index);
        });
      }
    }
  }

  // ai 가격 측정 함수
  Future<void> _measureAiPrice() async {
    try {
      final predictedPrice = await ItemApi().pricePredict(ItemRequest(
        itemName: titleController.text.trim(),
        itemDescription: descriptionController.text.trim(),
        itemCondition: selectedItemConditionTypes.isNotEmpty
            ? selectedItemConditionTypes.first.serverName
            : null,
      ));
      setState(() {
        priceController.text = predictedPrice.toString();
      });
    } catch (e) {
      // 에러 처리 (스낵바 표시 등)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 가격 예측에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _initControllers() async {
    // 수정 모드에서 초기화
    if (widget.isEditMode && widget.itemResponse != null) {
      final item = widget.itemResponse!.item;

      // 좌표가 있으면 주소 변환, 없으면 빈 문자열로 초기화
      if (item?.latitude != null && item?.longitude != null) {
        _selectedAddress = await LocationService().getAddressFromCoordinates(
          NLatLng(item!.latitude!, item.longitude!),
        );
        locationController.text =
            '${_selectedAddress?.siDo ?? ''} ${_selectedAddress?.siGunGu ?? ''} ${_selectedAddress?.eupMyoenDong ?? ''}'
                .trim();
      } else {
        _selectedAddress = null;
        locationController.text = '';
      }

      titleController.text = item?.itemName ?? '';
      descriptionController.text = item?.itemDescription ?? '';
      priceController.text = item?.price?.toString() ?? '0';

      selectedCategory = item?.itemCategory != null
          ? ItemCategories.fromServerName(item!.itemCategory!)
          : null;
      selectedItemConditionTypes = item?.itemCondition != null
          ? [ItemCondition.fromServerName(item!.itemCondition!)]
          : [];
      selectedTradeOptions = (item?.itemTradeOptions ?? [])
          .map((e) => ItemTradeOption.fromServerName(e))
          .toList();
      // 수정 모드에서는 이미 선택된 값이 있으므로 touched 상태로 설정
      if (selectedItemConditionTypes.isNotEmpty) {
        _hasConditionBeenTouched = true;
      }
      if (selectedTradeOptions.isNotEmpty) {
        _hasTradeOptionBeenTouched = true;
      }
      imageUrls = widget.itemResponse!.itemImages != null
          ? widget.itemResponse!.itemImages!
              .map((img) => img.imageUrl ?? '')
              .where((url) => url.isNotEmpty)
              .toList()
          : [];
      imageFiles = widget.itemResponse!.itemImages != null
          ? widget.itemResponse!.itemImages!
              .map((img) {
                final imageUrl = img.imageUrl ?? '';
                if (imageUrl.startsWith('http://') ||
                    imageUrl.startsWith('https://')) {
                  return XFile(imageUrl);
                } else if (imageUrl.isNotEmpty) {
                  return XFile('http://suh-project.synology.me/$imageUrl');
                } else {
                  return null;
                }
              })
              .whereType<XFile>()
              .toList()
          : [];
      imageCount = imageUrls.length.clamp(0, 10);
      _latitude = item?.latitude;
      _longitude = item?.longitude;
      useAiPrice = item?.aiPrice ?? false;
    }
  }

  bool _isInitLoading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers().then((_) {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사
  /// 모든 필드가 채워져 있는지 확인
  bool get isFormValid {
    // 가격 변환 (콤마 제거 후 숫자로 변환)
    final priceText = priceController.text.replaceAll(',', '').trim();
    final price = int.tryParse(priceText) ?? 0;
    
    return titleController.text.trim().isNotEmpty && // 공백만 있는 경우 제외
        selectedCategory != null &&
        descriptionController.text.trim().length >= 10 && // 최소 10자 이상, 공백만 있는 경우 제외
        selectedItemConditionTypes.isNotEmpty &&
        selectedTradeOptions.isNotEmpty &&
        price > 0 && // 0원 초과
        locationController.text.isNotEmpty &&
        _latitude != null &&
        _longitude != null &&
        imageFiles.isNotEmpty;
  }

  bool get canUseAiPrice {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedItemConditionTypes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const RegisterInputFormSkeleton();
    }

    return Column(
      children: [
        // 이미지 업로드
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border:
                      Border.all(color: AppColors.opacity40White, width: 1.5.w),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loadingImageIndices.contains(imageFiles.length - 1))
                      SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.textColorWhite),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SvgPicture.asset(
                              'assets/images/item-register-photo.svg'),
                          SizedBox(height: 4.h),
                          Text('$imageCount/10',
                              style: CustomTextStyles.p3
                                  .copyWith(color: AppColors.opacity40White)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: SizedBox(
                height: 88.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  padding: EdgeInsets.only(top: 8.h),
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    return SizedBox(
                      height: 88.h,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: _loadingImageIndices.contains(index)
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.textColorWhite),
                                    ),
                                  )
                                : Image.network(
                                    url,
                                    width: 80.w,
                                    height: 80.h,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.white),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: -8.h,
                            right: -8.w,
                            child: GestureDetector(
                              onTap: () async {
                                await onDeleteImage(index);
                              },
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                decoration: const BoxDecoration(
                                  color: AppColors
                                      .itemPictureRemoveButtonBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Icon(
                                    AppIcons.cancel,
                                    color: AppColors.primaryBlack,
                                    size: 16.sp,
                                  ),
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
        // 이미지 에러 메시지
        if (_hasImageBeenTouched && imageFiles.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
            child: Row(
              children: [
                Text(
                  '상품 사진을 최소 1장 이상 등록해주세요',
                  style: CustomTextStyles.p3
                      .copyWith(color: AppColors.errorBorder),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(right: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              // 제목 필드
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.title.label,
                field: RegisterCustomTextField(
                  phrase: ItemTextFieldPhrase.title,
                  maxLength: 20,
                  controller: titleController,
                  forceValidate: _forceValidateAll,
                ),
              ),

              // 카테고리 필드
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.category.label,
                field: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          _hasCategoryBeenTouched = true;
                        });
                        const categories = ItemCategories.values;
                        ItemCategories? tempSelected = selectedCategory;
                        await showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: AppColors.primaryBlack,
                      barrierColor: AppColors.opacity80Black,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      isScrollControlled: true,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setInnerState) {
                            return SizedBox(
                              height: 502.h,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 14.0.h),
                                      child: Container(
                                        width: 50.w,
                                        height: 4.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.opacity50White,
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 26.w),
                                    child: Text(
                                      ItemTextFieldPhrase.category.label,
                                      style: CustomTextStyles.h2.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: 26.w, left: 26.w, top: 24.h),
                                      child: Wrap(
                                        spacing: 8.0.w,
                                        runSpacing: 12.0.h,
                                        children: categories.map((category) {
                                          final isSelected =
                                              tempSelected == category;
                                          return CategoryChip(
                                            label: category.name,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setInnerState(() {
                                                tempSelected = category;
                                              });
                                              Navigator.pop(context);
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
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: (_hasCategoryBeenTouched || _forceValidateAll) && selectedCategory == null
                              ? AppColors.errorContainer
                              : AppColors.opacity10White,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: (_hasCategoryBeenTouched || _forceValidateAll) && selectedCategory == null
                                ? AppColors.errorBorder
                                : AppColors.opacity30White,
                            width: 1.5.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategory?.name ?? ItemTextFieldPhrase.category.hintText,
                                style: CustomTextStyles.p2.copyWith(
                                  color: selectedCategory != null
                                      ? AppColors.textColorWhite
                                      : AppColors.opacity40White,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            Icon(
                              AppIcons.detailView,
                              color: AppColors.textColorWhite,
                              size: 18.w,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((_hasCategoryBeenTouched || _forceValidateAll) && selectedCategory == null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.0.h),
                        child: Text(
                          ItemTextFieldPhrase.category.errorText,
                          style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder),
                        ),
                      ),
                  ],
                ),
              ),

              // 물건 설명 필드
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.description.label,
                field: RegisterCustomTextField(
                  phrase: ItemTextFieldPhrase.description,
                  controller: descriptionController,
                  maxLength: 1000,
                  maxLines: 6,
                  forceValidate: _forceValidateAll,
                ),
              ),

              // 물건 상태 필드
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.condition.label,
                field: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 8.0.h, bottom: 16.0.h),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.w,
                        children: ItemCondition.values
                            .map((option) => RegisterOptionChip(
                                  itemOption: option.name,
                                  isSelected: selectedItemConditionTypes
                                      .contains(option),
                                  onTap: () {
                                    final newList = <ItemCondition>[];
                                    if (selectedItemConditionTypes
                                        .contains(option)) {
                                      // 선택 해제
                                    } else {
                                      newList
                                        ..clear()
                                        ..add(option);
                                    }
                                    setState(() {
                                      _hasConditionBeenTouched = true;
                                      selectedItemConditionTypes = newList;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    ((_hasConditionBeenTouched || _forceValidateAll) && selectedItemConditionTypes.isEmpty)
                        ? Text(
                            ItemTextFieldPhrase.condition.errorText,
                            style: CustomTextStyles.p3
                                .copyWith(color: AppColors.errorBorder),
                          )
                        : Text('', style: CustomTextStyles.p3),
                  ],
                ),
              ),

              // 거래 방식 필드
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.tradeOption.label,
                field: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 8.0.h, bottom: 16.0.h),
                      child: Wrap(
                        spacing: 8.w,
                        children: ItemTradeOption.values
                            .map((option) => RegisterOptionChip(
                                  itemOption: option.name,
                                  isSelected:
                                      selectedTradeOptions.contains(option),
                                  onTap: () {
                                    final newList = List<ItemTradeOption>.from(
                                        selectedTradeOptions);
                                    if (newList.contains(option)) {
                                      newList.remove(option);
                                    } else {
                                      newList.add(option);
                                    }
                                    setState(() {
                                      _hasTradeOptionBeenTouched = true;
                                      selectedTradeOptions = newList;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    ((_hasTradeOptionBeenTouched || _forceValidateAll) && selectedTradeOptions.isEmpty)
                        ? Text(
                            ItemTextFieldPhrase.tradeOption.errorText,
                            style: CustomTextStyles.p3
                                .copyWith(color: AppColors.errorBorder),
                          )
                        : Text('', style: CustomTextStyles.p3),
                  ],
                ),
              ),

              // AI 추천 가격 안내
              Container(
                height: 58.h,
                margin: EdgeInsets.only(bottom: 24.w),
                padding: EdgeInsets.only(left: 12.w, right: 23.w),
                decoration: BoxDecoration(
                  color: AppColors.aiSuggestionContainerBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                            color: AppColors.textColorWhite,
                            width: 0.5.w,
                            strokeAlign: BorderSide.strokeAlignInside),
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
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        ItemTextFieldPhrase.price.hintText,
                        style: CustomTextStyles.p3.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // AI 가격 추천 스위치
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(ItemTextFieldPhrase.price.label,
                      style: CustomTextStyles.p1),
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
                  SizedBox(width: 4.w),
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
                    onTap: canUseAiPrice
                        ? null
                        : (b) {
                            // 조건이 안 맞으면 스낵바로 안내
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AI 가격 측정을 위해 제목, 설명(10자 이상), 물건 상태를 모두 입력해주세요'),
                                ),
                              );
                            }
                            return;
                          }, // 비활성화
                    onChanged: canUseAiPrice
                        ? (b) {
                            setState(() => useAiPrice = b as bool);
                            if ((b as bool) && canUseAiPrice) {
                              _measureAiPrice();
                            }
                          }
                        : null, // 비활성화
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
              // 가격 필드
              RegisterCustomTextField(
                phrase: ItemTextFieldPhrase.price,
                prefixText: '₩',
                readOnly: useAiPrice,
                keyboardType: TextInputType.number,
                controller: priceController,
                forceValidate: _forceValidateAll,
              ),

              // 거래 희망 위치 필드
              SizedBox(height: 24.w),
              RegisterCustomLabeledField(
                label: ItemTextFieldPhrase.location.label,
                field: RegisterCustomTextField(
                  readOnly: true,
                  phrase: ItemTextFieldPhrase.location,
                  suffixIcon: Icon(
                    AppIcons.detailView,
                    color: AppColors.textColorWhite,
                    size: 18.w,
                  ),
                  controller: locationController,
                  forceValidate: _forceValidateAll,
                  onTap: () async {
                    final result =
                        await Navigator.of(context).push<LocationAddress>(
                      MaterialPageRoute(
                        builder: (_) => ItemRegisterLocationScreen(
                          initialLocation:
                              _latitude != null && _longitude != null
                                  ? _selectedAddress
                                  : null,
                          onLocationSelected: (address) {
                            debugPrint(
                                '위치 선택됨: latitude=${address.latitude}, longitude=${address.longitude}');
                            setState(() {
                              locationController.text =
                                  '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
                              // 위치 좌표 저장
                              _latitude = address.latitude;
                              _longitude = address.longitude;
                            });
                            debugPrint(
                                '저장된 좌표: _latitude=$_latitude, _longitude=$_longitude');
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
              IgnorePointer(
                ignoring: _isLoading,
                child: CompletionButton(
                  isEnabled: isFormValid,
                  buttonText: '등록 완료',
                  buttonType: 2,
                  enabledOnPressed: () async {
                    // 모든 필드 강제 검증
                    if (!isFormValid) {
                      setState(() {
                        _forceValidateAll = true;
                        _hasCategoryBeenTouched = true;
                        _hasConditionBeenTouched = true;
                        _hasTradeOptionBeenTouched = true;
                        _hasImageBeenTouched = true;
                      });
                      return;
                    }
                    
                    if (_longitude == null || _latitude == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ItemTextFieldPhrase.location.errorText),
                          backgroundColor: AppColors.warningRed,
                        ),
                      );
                      return;
                    }

                    try {
                      debugPrint(
                          '물품 등록 시작 - longitude: $_longitude, latitude: $_latitude');
                      setState(() {
                        _isLoading = true;
                      });
                      final itemRequest = ItemRequest(
                        itemId: widget.isEditMode
                            ? widget.itemResponse!.item?.itemId
                            : null,
                        itemName: titleController.text.trim(),
                        itemDescription: descriptionController.text.trim(),
                        itemCategory: selectedCategory!.serverName,
                        itemCondition: selectedItemConditionTypes.isNotEmpty
                            ? selectedItemConditionTypes.first.serverName
                            : null,
                        itemTradeOptions: selectedTradeOptions
                            .map((e) => e.serverName)
                            .toList(),
                        itemPrice:
                            int.parse(priceController.text.replaceAll(',', '')),
                        itemCustomTags: [],
                        itemImageUrls: imageUrls,
                        longitude: _longitude,
                        latitude: _latitude,
                        aiPrice: useAiPrice,
                      );
                      if (widget.isEditMode) {
                        await ItemApi().updateItem(itemRequest);
                      } else {
                        await ItemApi().postItem(itemRequest);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('물품이 성공적으로 등록되었습니다.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('물품 등록에 실패했습니다: $e')),
                        );
                      }
                    }
                    setState(() {
                      _isLoading = false;
                    });
                  },
                ),
              ),
              SizedBox(height: 24.w),
            ],
          ),
        ),
      ],
    );
  }
}
