// 물품 등록 필드 입력 처리: 카테고리·희망 교환 카테고리 선택, 사용감·거래 방식 칩, 가격·위치 화면 이동
part of '../register_input_form.dart';

mixin _RegisterInputFormFieldHandlers on _RegisterInputFormStateFields {
  /// AI 가격 추천 가능 여부 (제목·설명·사용감 입력 완료)
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

  /// 희망 교환 카테고리 칸 탭 > 복수 선택 바텀시트 (최대 3개) > 완료 시 반영, 그냥 닫으면 유지
  Future<void> _onWantedCategoryFieldTap() async {
    final pickedCategories = await ItemCategoryMultiSelectBottomSheet.show(
      context: context,
      title: wantedItemCategoryTitle,
      initialCategories: selectedWantedCategories,
      maximumSelectionCount: maximumWantedItemCategoryCount,
    );
    if (pickedCategories == null || !mounted) return;
    setState(() => selectedWantedCategories = pickedCategories);
  }

  /// 사용감 칩 탭 > 단일 선택 (이미 고른 칩이면 해제) > AI 가격 기준 바뀌면 AI 표시 해제
  void _onConditionOptionTap(ItemCondition option) {
    final newList = <ItemCondition>[];
    if (!selectedItemConditionTypes.contains(option)) newList.add(option);
    setState(() {
      _hasConditionBeenTouched = true;
      selectedItemConditionTypes = newList;
      _clearAiPriceIfBasisChanged();
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

  /// 가격 칸 탭 > 가격 입력 화면 (AI 추천 가능 여부 전달) > 고른 가격·AI 사용 여부·AI 측정 기준 반영
  Future<void> _openPriceInputScreen() async {
    final initialPrice = int.tryParse(priceController.text.replaceAll(',', '')) ?? 0;
    // 가격 화면에 보낸 입력 = AI 측정 기준
    final priceInputBasis = AiPriceBasis(
      itemName: titleController.text,
      itemDescription: descriptionController.text,
      itemCondition: _selectedConditionServerName,
    );
    await context.navigateTo(
      type: NavigationTypes.slideUp,
      screen: ItemPriceInputScreen(
        initialPrice: initialPrice,
        initialUseAiPrice: useAiPrice,
        canUseAiPrice: canUseAiPrice,
        itemName: priceInputBasis.itemName,
        itemDescription: priceInputBasis.itemDescription,
        itemCondition: priceInputBasis.itemCondition,
        onPriceSelected: (price, aiUsed) {
          if (mounted) {
            setState(() {
              useAiPrice = aiUsed;
              _aiPriceBasis = aiUsed ? priceInputBasis : null;
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
}
