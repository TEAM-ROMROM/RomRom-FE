import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/price_comma_format_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 아이템 가격 입력 화면
class ItemPriceInputScreen extends StatefulWidget {
  final int initialPrice;
  final bool initialUseAiPrice;
  final bool canUseAiPrice;
  final String itemName;
  final String itemDescription;
  final String? itemCondition;
  final void Function(int price, bool useAiPrice) onPriceSelected;

  const ItemPriceInputScreen({
    super.key,
    required this.initialPrice,
    required this.initialUseAiPrice,
    required this.canUseAiPrice,
    required this.itemName,
    required this.itemDescription,
    required this.itemCondition,
    required this.onPriceSelected,
  });

  @override
  State<ItemPriceInputScreen> createState() => _ItemPriceInputScreenState();
}

class _ItemPriceInputScreenState extends State<ItemPriceInputScreen> {
  late final TextEditingController _priceController;
  late bool _useAiPrice;
  bool _isAiPriceLoading = false;

  @override
  void initState() {
    super.initState();
    _useAiPrice = widget.initialUseAiPrice;
    if (widget.initialPrice > 0) {
      final formatted = const PriceCommaFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: widget.initialPrice.toString()),
      );
      _priceController = TextEditingController.fromValue(formatted);
    } else {
      _priceController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  int get _currentPrice => int.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;

  bool get _isConfirmEnabled => _currentPrice > 0 && !_isAiPriceLoading;

  final Set<String> _pendingRequests = <String>{};

  Future<void> _measureAiPrice() async {
    if (_pendingRequests.contains('pricePredict')) return;
    _pendingRequests.add('pricePredict');
    setState(() => _isAiPriceLoading = true);
    try {
      final predictedPrice = await ItemApi().pricePredict(
        ItemRequest(
          itemName: widget.itemName,
          itemDescription: widget.itemDescription,
          itemCondition: widget.itemCondition,
        ),
      );

      if (predictedPrice <= 0) {
        if (mounted) {
          setState(() => _useAiPrice = false);
          CommonSnackBar.show(context: context, message: 'AI가 적정 가격을 측정하지 못했어요. 직접 입력해 주세요.', type: SnackBarType.error);
        }
        return;
      }

      final formatted = const PriceCommaFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: predictedPrice.toString()),
      );

      if (mounted) {
        setState(() => _priceController.value = formatted);
        CommonSnackBar.show(context: context, message: 'AI로 적정 가격을 추천해드렸어요!');
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isAiPriceLoading = false);
    }
  }

  void _onToggleChanged(bool value) {
    setState(() => _useAiPrice = value);
    if (value) {
      FocusManager.instance.primaryFocus?.unfocus();
      _measureAiPrice();
    }
  }

  void _onToggleTapWhenDisabled(dynamic _) {
    CommonSnackBar.show(context: context, message: 'AI 가격 측정을 위해 제목, 설명, 물건 상태를 모두 입력해주세요', type: SnackBarType.info);
  }

  void _onConfirm() {
    widget.onPriceSelected(_currentPrice, _useAiPrice);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '적정 가격'),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _AiPriceCard(
                  useAiPrice: _useAiPrice,
                  isLoading: _isAiPriceLoading,
                  canUseAiPrice: widget.canUseAiPrice,
                  onChanged: _onToggleChanged,
                  onTapWhenDisabled: _onToggleTapWhenDisabled,
                ),
                SizedBox(height: 16.h),
                _PriceTextField(
                  controller: _priceController,
                  readOnly: _useAiPrice || _isAiPriceLoading,
                  isLoading: _isAiPriceLoading,
                  onChanged: (_) => setState(() {}),
                ),
                const Spacer(),
                CompletionButton(
                  isEnabled: _isConfirmEnabled,
                  isLoading: _isAiPriceLoading,
                  buttonText: '완료',
                  enabledOnPressed: _onConfirm,
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 가격 측정 토글 카드
class _AiPriceCard extends StatelessWidget {
  final bool useAiPrice;
  final bool isLoading;
  final bool canUseAiPrice;
  final void Function(bool) onChanged;
  final void Function(dynamic) onTapWhenDisabled;

  const _AiPriceCard({
    required this.useAiPrice,
    required this.isLoading,
    required this.canUseAiPrice,
    required this.onChanged,
    required this.onTapWhenDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.aiSuggestionContainerBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: GradientBoxBorder(
          gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.70, 1.0]),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlack,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset('assets/images/ai-recommend-price-star.svg', height: 16.h),
                          GradientText(
                            text: 'AI 추천 가격',
                            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600),
                            gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.7, 1.0]),
                          ),
                        ],
                      ),
                    ),
                    AnimatedToggleSwitch.dual(
                      current: useAiPrice,
                      first: false,
                      second: true,
                      spacing: 2.0.w,
                      height: 22.h,
                      style: ToggleStyle(
                        indicatorColor: AppColors.textColorWhite,
                        borderRadius: BorderRadius.all(Radius.circular(110.r)),
                        indicatorBoxShadow: const [
                          BoxShadow(color: AppColors.toggleSwitchIndicatorShadow, offset: Offset(-1, 0), blurRadius: 2),
                        ],
                      ),
                      indicatorSize: Size(20.w, 20.h),
                      borderWidth: 0,
                      padding: EdgeInsets.all(1.w),
                      onTap: canUseAiPrice ? null : onTapWhenDisabled,
                      onChanged: canUseAiPrice ? onChanged : null,
                      styleBuilder: (b) => ToggleStyle(
                        backgroundGradient: b
                            ? const LinearGradient(colors: AppColors.aiGradient)
                            : const LinearGradient(colors: [AppColors.opacity40White, AppColors.opacity40White]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text('AI가 물건의 적정 가격을 추천해드려요', style: CustomTextStyles.p2.copyWith(fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 가격 입력 텍스트 필드
class _PriceTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final bool isLoading;
  final void Function(String) onChanged;

  const _PriceTextField({
    required this.controller,
    required this.readOnly,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.opacity10White,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.opacity30White, width: 1.5.w),
      ),
      child: Row(
        children: [
          Text('₩', style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              inputFormatters: [const PriceCommaFormatter()],
              onChanged: onChanged,
              style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
                suffixIcon: isLoading
                    ? const Padding(padding: EdgeInsets.only(left: 8), child: CommonLoadingIndicator(size: 16.0))
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
