import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/utils/price_comma_format_utils.dart';
import 'package:romrom_fe/widgets/common/ai_price_chip.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/register_text_field.dart';

/// 적정 가격 입력 페이지
/// 가격(int)을 pop으로 반환. 0 반환 시 취소로 간주.
class ItemPriceScreen extends StatefulWidget {
  final int initialPrice;
  final bool initialIsAiRecommended; // 재진입 시 AI 토글 상태 복원
  final String itemName;
  final String itemDescription;
  final String? itemCondition; // ItemCondition.serverName

  const ItemPriceScreen({
    super.key,
    required this.initialPrice,
    this.initialIsAiRecommended = false,
    required this.itemName,
    required this.itemDescription,
    this.itemCondition,
  });

  @override
  State<ItemPriceScreen> createState() => _ItemPriceScreenState();
}

class _ItemPriceScreenState extends State<ItemPriceScreen> {
  late final TextEditingController _priceController;
  late final FocusNode _priceFocusNode;

  late bool _useAiPrice;
  bool _isAiPriceLoading = false;
  // 직접 수정 감지용 — AI가 채운 가격값 저장
  String _aiFilledPriceText = '';

  bool get _isFormValid {
    final text = _priceController.text.replaceAll(',', '').trim();
    final price = int.tryParse(text) ?? 0;
    return price > 0;
  }

  int get _currentPrice {
    final text = _priceController.text.replaceAll(',', '').trim();
    return int.tryParse(text) ?? 0;
  }

  // AI 토글 활성 조건: 제목 + 설명 + 상태 모두 비어있지 않아야 함
  bool get _canUseAiPrice =>
      widget.itemName.trim().isNotEmpty &&
      widget.itemDescription.trim().isNotEmpty &&
      (widget.itemCondition?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _priceFocusNode = FocusNode();
    _priceController = TextEditingController();
    _useAiPrice = widget.initialIsAiRecommended;

    // 기존 가격이 있으면 초기값 세팅
    if (widget.initialPrice > 0) {
      final formatted = const PriceCommaFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: widget.initialPrice.toString()),
      );
      _priceController.value = formatted;
      // AI 추천 상태로 진입했으면 해당 가격을 AI 채움 값으로 기억
      if (widget.initialIsAiRecommended) {
        _aiFilledPriceText = formatted.text;
      }
    }

    _priceController.addListener(_onPriceChanged);

    // 진입 즉시 숫자 키패드 올라오게 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _priceFocusNode.requestFocus();
    });
  }

  void _onPriceChanged() {
    // AI 추천 가격이 채워진 상태에서 사용자가 직접 수정하면 AI 토글 OFF
    if (_useAiPrice && !_isAiPriceLoading && _priceController.text != _aiFilledPriceText) {
      setState(() {
        _useAiPrice = false;
        _aiFilledPriceText = '';
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _priceFocusNode.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _measureAiPrice() async {
    setState(() => _isAiPriceLoading = true);
    try {
      final predictedPrice = await ItemApi().pricePredict(
        ItemRequest(
          itemName: widget.itemName.trim(),
          itemDescription: widget.itemDescription.trim(),
          itemCondition: widget.itemCondition,
        ),
      );

      if (predictedPrice <= 0) {
        setState(() => _useAiPrice = false);
        if (mounted) {
          CommonSnackBar.show(context: context, message: 'AI가 적정 가격을 측정하지 못했어요. 직접 입력해 주세요.', type: SnackBarType.error);
        }
        return;
      }

      final formatted = const PriceCommaFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: predictedPrice.toString()),
      );
      setState(() {
        _priceController.value = formatted;
        _aiFilledPriceText = formatted.text; // 직접 수정 감지 기준값 저장
      });

      if (mounted) {
        CommonSnackBar.show(context: context, message: 'AI로 적정 가격을 추천해드렸어요!');
      }
    } catch (e) {
      setState(() => _useAiPrice = false);
      if (mounted) {
        CommonSnackBar.show(context: context, message: 'AI 가격 예측에 실패했습니다.', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isAiPriceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CommonAppBar(title: '적정 가격', showBottomBorder: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI 추천 가격 카드 (그라디언트 테두리 + 어두운 배경)
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.7, 1.0]),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.aiCardBackground,
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AiPriceChipWidget(),
                                SizedBox(height: 8.h),
                                Text('AI가 물건의 적정 가격을 추천해드려요', style: CustomTextStyles.p2.copyWith(height: 1.4)),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          AnimatedToggleSwitch.dual(
                            current: _useAiPrice,
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
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            indicatorSize: Size(18.w, 18.h),
                            borderWidth: 0,
                            padding: EdgeInsets.all(1.w),
                            onTap: _canUseAiPrice
                                ? null
                                : (b) {
                                    if (context.mounted) {
                                      CommonSnackBar.show(
                                        context: context,
                                        message: 'AI 가격 측정을 위해 제목, 설명, 물건 상태를 모두 입력해주세요',
                                        type: SnackBarType.info,
                                      );
                                    }
                                  },
                            onChanged: _canUseAiPrice
                                ? (b) {
                                    setState(() {
                                      _useAiPrice = b as bool;
                                      if (!_useAiPrice) _priceController.clear();
                                    });
                                    if (_useAiPrice) _measureAiPrice();
                                  }
                                : null,
                            styleBuilder: (b) => ToggleStyle(
                              backgroundGradient: b
                                  ? const LinearGradient(colors: AppColors.aiGradient)
                                  : const LinearGradient(colors: [AppColors.opacity40White, AppColors.opacity40White]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  RegisterCustomTextField(
                    phrase: ItemTextFieldPhrase.price,
                    hintTextOverride: '가격을 입력해 주세요',
                    prefixText: '₩',
                    maxLength: 11,
                    keyboardType: TextInputType.number,
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    readOnly: _useAiPrice || _isAiPriceLoading,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    suffixIcon: _isAiPriceLoading
                        ? Padding(
                            padding: EdgeInsets.all(12.w),
                            child: SizedBox(
                              width: 10.w,
                              height: 10.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 24 + MediaQuery.of(context).padding.bottom,
              top: 12,
            ),
            child: CompletionButton(
              isEnabled: _isFormValid && !_isAiPriceLoading,
              isLoading: _isAiPriceLoading,
              buttonText: '완료',
              enabledOnPressed: () => Navigator.pop(context, (_currentPrice, _useAiPrice)),
            ),
          ),
        ],
      ),
    );
  }
}
