import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/image_pick_source.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/models/register_form_snapshot.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/image_fullscreen_viewer.dart';
import 'package:romrom_fe/screens/item_register_location_screen.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/image_compressor.dart';
import 'package:romrom_fe/utils/price_comma_format_utils.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/screens/item_price_input_screen.dart';
import 'package:romrom_fe/widgets/register_input_form/register_category_bottom_sheet.dart';
import 'package:romrom_fe/widgets/register_input_form/register_category_field.dart';
import 'package:romrom_fe/widgets/register_input_form/register_image_picker_section.dart';
import 'package:romrom_fe/widgets/register_input_form/register_option_selector.dart';
import 'package:romrom_fe/widgets/register_input_form/register_price_suffix_icon.dart';
import 'package:romrom_fe/widgets/register_text_field.dart';
import 'package:romrom_fe/widgets/skeletons/register_input_form_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/image_repository_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/utils/camera_permission_helper.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/image_source_bottom_sheet.dart';

part 'register_input_form/register_input_form_image_selection.dart';
part 'register_input_form/register_input_form_submission.dart';
part 'register_input_form/register_input_form_unsaved_changes.dart';

/// 물품 등록 입력 폼 위젯
/// 물품 등록 화면에서 사용되는 입력 폼 위젯
class RegisterInputForm extends ConsumerStatefulWidget {
  final Item? item; // 수정 모드에서 사용
  final bool isEditMode;
  // 미저장 변경 여부 전달 (부모 화면의 이탈 경고 가드가 구독)
  final ValueNotifier<bool>? hasUnsavedChangesNotifier;
  // 저장 진행 여부 전달 (부모 화면 가드가 저장 중 이탈 차단)
  final ValueNotifier<bool>? isSaveInProgressNotifier;

  const RegisterInputForm({
    super.key,
    this.item,
    this.isEditMode = false,
    this.hasUnsavedChangesNotifier,
    this.isSaveInProgressNotifier,
  });

  @override
  ConsumerState<RegisterInputForm> createState() => _RegisterInputFormState();
}

/// 물품 등록 폼 상태 필드·파생 값 (책임별 mixin이 공유, part 파일: register_input_form/)
abstract class _RegisterInputFormStateFields extends ConsumerState<RegisterInputForm> {
  // 임시 상태 변수들
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
  final TextEditingController priceController = TextEditingController(text: '0');
  final TextEditingController locationController = TextEditingController();

  // 포커스 체인 (상단→하단 자동 이동)
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  // 이미지 관련 변수들
  final ImagePicker _picker = ImagePicker();
  // 소스 선택 바텀시트~촬영/선택 완료까지 진행 중 가드 (더블탭 방지)
  bool _isPickingSource = false;
  final List<XFile> _newImageFiles = []; // 새로 선택된 로컬 이미지 파일 (아직 업로드 안 됨)
  // _newImageFiles와 인덱스 1:1로 정렬되는 백그라운드 압축 Future 리스트.
  // 선택 시 add, 삭제 시 같은 index를 removeAt, 등록 시 index로 수거.
  // (path를 key로 쓰면 동일 파일 재선택 시 충돌하므로 인덱스 정렬 리스트를 쓴다.)
  final List<Future<XFile>> _compressing = [];
  final List<String> _existingImageUrls = []; // 수정 모드: 기존 서버 이미지 URL

  bool _isInitLoading = true;
  bool _isLoading = false;

  // 진입 시점 폼 값 (등록: 빈 폼, 수정: 불러온 물품) — 이탈 경고 비교 기준, 초기화 전 null
  RegisterFormSnapshot? _initialFormSnapshot;
  // 저장 성공 여부 (true면 이탈 경고 없이 닫기)
  bool _isSubmitSucceeded = false;

  /// 수정 / 등록 (안내 문구용)
  String get _modeText => widget.isEditMode ? '수정' : '등록';

  /// 전체 이미지 수 (기존 서버 이미지 + 새 로컬 이미지)
  int get _totalImageCount => _existingImageUrls.length + _newImageFiles.length;

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
        _totalImageCount > 0;
  }
}

/// 물품 등록 폼: 수명주기·초기값·필드 입력 처리·화면 구성 (로직 mixin 3개: 사진 선택, 제출, 이탈 경고 스냅샷)
class _RegisterInputFormState extends _RegisterInputFormStateFields
    with _RegisterInputFormImageSelection, _RegisterInputFormSubmission, _RegisterInputFormUnsavedChanges {
  Future<void> _initControllers() async {
    // 수정 모드에서 초기화
    if (widget.isEditMode && widget.item != null) {
      final item = widget.item;

      // 좌표가 있으면 주소 변환, 없으면 빈 문자열로 초기화
      if (item?.latitude != null && item?.longitude != null) {
        _selectedAddress = await LocationService().getAddressFromCoordinates(NLatLng(item!.latitude!, item.longitude!));
        locationController.text = _selectedAddress?.siDoSiGunGuEupMyoenDongText.trim() ?? '';
      } else {
        _selectedAddress = null;
        locationController.text = '';
      }

      titleController.text = item?.itemName ?? '';
      descriptionController.text = item?.itemDescription ?? '';
      // 숫자를 콤마 포함 문자열로 변환
      final formatted = const PriceCommaFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: item?.price?.toString() ?? '0'),
      );

      priceController.value = formatted;

      selectedCategory = ItemCategories.fromServerName(item?.itemCategory);
      selectedItemConditionTypes = [?ItemCondition.fromServerName(item?.itemCondition)];
      selectedTradeOptions = ItemTradeOption.fromServerNamesSkippingUnknown(item?.itemTradeOptions);
      // 수정 모드에서는 이미 선택된 값이 있으므로 touched 상태로 설정
      if (selectedItemConditionTypes.isNotEmpty) {
        _hasConditionBeenTouched = true;
      }
      if (selectedTradeOptions.isNotEmpty) {
        _hasTradeOptionBeenTouched = true;
      }
      _existingImageUrls.clear();
      if (widget.item!.itemImages != null) {
        _existingImageUrls.addAll(
          widget.item!.itemImages!
              .map((img) {
                // 상대 경로 > 이미지 서버 절대 주소 (https)
                return AppUrls.toAbsoluteImageUrl(img.imageUrl ?? '');
              })
              .where((url) => url.isNotEmpty),
        );
      }
      _newImageFiles.clear();
      _compressing.clear();
      _latitude = item?.latitude;
      _longitude = item?.longitude;
      useAiPrice = item?.isAiPredictedPrice ?? false;
    }
  }

  void _onFormValueChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    titleController.addListener(_onFormValueChanged);
    descriptionController.addListener(_onFormValueChanged);
    priceController.addListener(_onFormValueChanged);
    locationController.addListener(_onFormValueChanged);
    _initControllers().then((_) {
      if (mounted) {
        setState(() {
          _initialFormSnapshot = _captureFormSnapshot();
          _isInitLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    titleController.removeListener(_onFormValueChanged);
    descriptionController.removeListener(_onFormValueChanged);
    priceController.removeListener(_onFormValueChanged);
    locationController.removeListener(_onFormValueChanged);
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.dispose();
  }

  bool get canUseAiPrice {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedItemConditionTypes.isNotEmpty;
  }

  /// 카테고리 칸 탭 > 선택 바텀시트 > 고른 값 반영
  Future<void> _onCategoryFieldTap() async {
    setState(() {
      _hasCategoryBeenTouched = true;
    });
    final ItemCategories? pickedCategory = await RegisterCategoryBottomSheet.show(
      context: context,
      selectedCategory: selectedCategory,
    );
    setState(() {
      selectedCategory = pickedCategory;
    });
  }

  /// 사용감 칩 탭 > 단일 선택 (이미 고른 칩이면 해제)
  void _onConditionOptionTap(ItemCondition option) {
    final newList = <ItemCondition>[];
    if (!selectedItemConditionTypes.contains(option)) newList.add(option);
    setState(() {
      _hasConditionBeenTouched = true;
      selectedItemConditionTypes = newList;
    });
  }

  /// 거래 방식 칩 탭 > 복수 선택 토글
  void _onTradeOptionTap(ItemTradeOption option) {
    final newList = List<ItemTradeOption>.from(selectedTradeOptions);
    if (newList.contains(option)) {
      newList.remove(option);
    } else {
      newList.add(option);
    }
    setState(() {
      _hasTradeOptionBeenTouched = true;
      selectedTradeOptions = newList;
    });
  }

  /// 가격 칸 탭 > 가격 입력 화면 (AI 추천 가능 여부 전달) > 고른 가격·AI 사용 여부 반영
  Future<void> _openPriceInputScreen() async {
    final initialPrice = int.tryParse(priceController.text.replaceAll(',', '')) ?? 0;
    await context.navigateTo(
      type: NavigationTypes.slideUp,
      screen: ItemPriceInputScreen(
        initialPrice: initialPrice,
        initialUseAiPrice: useAiPrice,
        canUseAiPrice: canUseAiPrice,
        itemName: titleController.text,
        itemDescription: descriptionController.text,
        itemCondition: selectedItemConditionTypes.isNotEmpty ? selectedItemConditionTypes.first.serverName : null,
        onPriceSelected: (price, aiUsed) {
          if (mounted) {
            setState(() {
              useAiPrice = aiUsed;
              priceController.value = const PriceCommaFormatter().formatEditUpdate(
                const TextEditingValue(),
                TextEditingValue(text: price.toString()),
              );
            });
          }
        },
      ),
    );
  }

  /// 위치 칸 탭 > 위치 선택 화면 > 주소 문구·좌표 반영
  Future<void> _openLocationScreen() async {
    await context.navigateTo<LocationAddress>(
      screen: ItemRegisterLocationScreen(
        initialLocation: _latitude != null && _longitude != null ? _selectedAddress : null,
        onLocationSelected: (address) {
          debugPrint('위치 선택됨: latitude=${address.latitude}, longitude=${address.longitude}');
          setState(() {
            locationController.text = address.siDoSiGunGuEupMyoenDongText;
            // 위치 좌표 저장
            _latitude = address.latitude;
            _longitude = address.longitude;
          });
          debugPrint('저장된 좌표: _latitude=$_latitude, _longitude=$_longitude');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _reportUnsavedChangesAfterFrame();

    if (_isInitLoading) {
      return const RegisterInputFormSkeleton();
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // 이미지 업로드 (사진 없음 안내 포함)
          RegisterImagePickerSection(
            existingImageUrls: _existingImageUrls,
            newImagePaths: _newImageFiles.map((file) => file.path).toList(growable: false),
            shouldShowEmptyImageError: _hasImageBeenTouched && _totalImageCount == 0,
            onAddImageTap: onPickImage,
            onImageTap: _openImageFullscreenViewer,
            onDeleteImageTap: onDeleteImage,
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
                    focusNode: _titleFocusNode,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
                  ),
                ),

                // 카테고리 필드
                RegisterCustomLabeledField(
                  label: ItemTextFieldPhrase.category.label,
                  field: RegisterCategoryField(
                    selectedCategory: selectedCategory,
                    shouldShowError: _hasCategoryBeenTouched || _forceValidateAll,
                    onTap: _onCategoryFieldTap,
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
                    focusNode: _descriptionFocusNode,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),

                // 물건 상태 필드
                RegisterCustomLabeledField(
                  label: ItemTextFieldPhrase.condition.label,
                  field: RegisterOptionSelector<ItemCondition>(
                    options: ItemCondition.values,
                    selectedOptions: selectedItemConditionTypes,
                    labelOf: (option) => option.label,
                    onOptionTap: _onConditionOptionTap,
                    shouldShowError: _hasConditionBeenTouched || _forceValidateAll,
                    errorText: ItemTextFieldPhrase.condition.errorText,
                    runSpacing: 8.w,
                  ),
                ),

                // 거래 방식 필드
                RegisterCustomLabeledField(
                  label: ItemTextFieldPhrase.tradeOption.label,
                  field: RegisterOptionSelector<ItemTradeOption>(
                    options: ItemTradeOption.values,
                    selectedOptions: selectedTradeOptions,
                    labelOf: (option) => option.label,
                    onOptionTap: _onTradeOptionTap,
                    shouldShowError: _hasTradeOptionBeenTouched || _forceValidateAll,
                    errorText: ItemTextFieldPhrase.tradeOption.errorText,
                  ),
                ),

                // 적정 가격 필드
                RegisterCustomLabeledField(
                  label: ItemTextFieldPhrase.price.label,
                  field: RegisterCustomTextField(
                    phrase: ItemTextFieldPhrase.price,
                    prefixText: '₩',
                    readOnly: true,
                    maxLength: 11,
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    forceValidate: _forceValidateAll,
                    suffixIcon: RegisterPriceSuffixIcon(isAiPredictedPrice: useAiPrice),
                    onTap: _openPriceInputScreen,
                  ),
                ),

                // 거래 희망 위치 필드
                RegisterCustomLabeledField(
                  label: ItemTextFieldPhrase.location.label,
                  field: RegisterCustomTextField(
                    readOnly: true,
                    phrase: ItemTextFieldPhrase.location,
                    suffixIcon: Icon(AppIcons.detailView, color: AppColors.opacity30White, size: 18.w),
                    controller: locationController,
                    forceValidate: _forceValidateAll,
                    onTap: _openLocationScreen,
                  ),
                ),

                // 등록 완료 버튼
                IgnorePointer(
                  ignoring: _isLoading,
                  child: CompletionButton(
                    isEnabled: isFormValid,
                    isLoading: _isLoading,
                    buttonText: widget.isEditMode ? '수정 완료' : '등록 완료',
                    enabledOnPressed: _onSubmitButtonPressed,
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
