// 물품 등록·수정 제출: 검증 > 새 사진 업로드 > 요청 생성 > 등록·수정 notifier 호출 > 저장 성공 시 닫기
part of '../register_input_form.dart';

mixin _RegisterInputFormSubmission on _RegisterInputFormStateFields {
  /// 완료 버튼: 미입력 > 오류 전체 표시, 위치 없음 > 안내, 그 외 저장 (저장 중 이탈 차단)
  Future<void> _onSubmitButtonPressed() async {
    if (!isFormValid) {
      _revealAllValidationErrors();
      return;
    }

    if (_longitude == null || _latitude == null) {
      CommonSnackBar.show(context: context, message: ItemTextFieldPhrase.location.errorText, type: SnackBarType.info);
      return;
    }

    try {
      debugPrint('물품 $_modeText 시작 - longitude: $_longitude, latitude: $_latitude');
      setState(() {
        _isLoading = true;
      });
      widget.isSaveInProgressNotifier?.value = true;

      final List<String> newImageUrls = await _uploadNewImages();
      // 기존 서버 이미지 URL + 새로 업로드된 URL 합치기
      final itemRequest = _buildItemRequest([..._existingImageUrls, ...newImageUrls]);

      if (widget.isEditMode) {
        await _submitEditedItem(itemRequest);
      } else {
        await _submitNewItem(itemRequest);
      }
    } on UgcViolationException catch (e) {
      if (context.mounted) _showUgcViolationModal(e);
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        // 저장 종료 > 이탈 차단 해제 (성공·실패 공통, 해제된 화면의 notifier 접근 금지)
        widget.isSaveInProgressNotifier?.value = false;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 제출 시도 > 모든 필드 강제 검증 (오류 문구 전체 표시)
  void _revealAllValidationErrors() {
    setState(() {
      _forceValidateAll = true;
      _hasCategoryBeenTouched = true;
      _hasConditionBeenTouched = true;
      _hasTradeOptionBeenTouched = true;
      _hasImageBeenTouched = true;
    });
  }

  /// 새 로컬 사진 압축본 수거 > 업로드 > 서버 주소 목록 (일부 실패 시 예외)
  Future<List<String>> _uploadNewImages() async {
    if (_newImageFiles.isEmpty) return [];
    // 선택 시 시작한 압축 순서 보존 수거 (_compressing <-> _newImageFiles 인덱스 1:1, 보통 대기 0)
    final List<XFile> compressed = await Future.wait(_compressing);
    final List<String> newImageUrls = await ref.read(imageRepositoryProvider).uploadImages(compressed);
    if (newImageUrls.length != compressed.length) {
      throw Exception('일부 이미지 업로드에 실패했습니다 (${newImageUrls.length}/${compressed.length})');
    }
    return newImageUrls;
  }

  /// 현재 폼 값 + 전체 사진 주소 > 등록·수정 요청
  ItemRequest _buildItemRequest(List<String> allImageUrls) {
    return ItemRequest(
      itemId: widget.isEditMode ? widget.item?.itemId : null,
      itemName: titleController.text.trim(),
      itemDescription: descriptionController.text.trim(),
      itemCategory: selectedCategory!.serverName,
      itemCondition: selectedItemConditionTypes.isNotEmpty ? selectedItemConditionTypes.first.serverName : null,
      itemTradeOptions: selectedTradeOptions.map((e) => e.serverName).toList(),
      itemPrice: int.parse(priceController.text.replaceAll(',', '')),
      itemCustomTags: [],
      itemImageUrls: allImageUrls,
      longitude: _longitude,
      latitude: _latitude,
      isAiPredictedPrice: useAiPrice,
    );
  }

  /// 수정 모드: notifier.edit가 수정 API + 내 물건 재조회 (다른 탭 즉시 반영)
  Future<void> _submitEditedItem(ItemRequest itemRequest) async {
    await ref.read(myItemsProvider.notifier).edit(itemRequest);
    if (context.mounted) {
      _popAfterSubmitSucceeded({'updated': true});
      CommonSnackBar.show(context: context, message: '물품이 성공적으로 $_modeText되었습니다.');
    }
  }

  /// 등록 모드: notifier.register가 postItem + reload + isFirstItemPosted 반환을 통합 처리
  Future<void> _submitNewItem(ItemRequest itemRequest) async {
    final isFirst = await ref.read(myItemsProvider.notifier).register(itemRequest);
    debugPrint('====================================');
    debugPrint('물품 등록 응답: isFirstItemPosted=$isFirst');
    debugPrint('====================================');

    final userInfo = UserInfo();
    await userInfo.getUserInfo();

    if (isFirst) {
      debugPrint('첫 물품 등록 확인! UserInfo 업데이트 중...');
      await userInfo.saveLoginStatus(
        isFirstLogin: false,
        isFirstItemPosted: true,
        isItemCategorySaved: userInfo.isItemCategorySaved ?? false,
        isMemberLocationSaved: userInfo.isMemberLocationSaved ?? false,
        isMarketingInfoAgreed: userInfo.isMarketingInfoAgreed ?? false,
        isRequiredTermsAgreed: userInfo.isRequiredTermsAgreed ?? false,
        isCoachMarkShown: userInfo.isCoachMarkShown,
      );
    }

    if (context.mounted) {
      _popAfterSubmitSucceeded({'isFirstItemPosted': isFirst});
      CommonSnackBar.show(context: context, message: '물품이 성공적으로 $_modeText되었습니다.');
    }
  }

  /// 부적절한 표현 거부 > 위반 문구 포함 오류 모달
  void _showUgcViolationModal(UgcViolationException violation) {
    final ugcMessage = violation.violatingText.isNotEmpty
        ? '\'${violation.violatingText}\'이(가) 포함된\n부적절한 표현입니다.\n수정 후 다시 시도해주세요.'
        : '부적절한 표현이 포함되어 있습니다.\n수정 후 다시 시도해주세요.';
    CommonModal.error(context: context, message: ugcMessage, onConfirm: () => Navigator.of(context).pop());
  }

  /// 저장 성공 > 이탈 경고 해제 후 결과와 함께 닫기
  void _popAfterSubmitSucceeded(Map<String, dynamic> submitResult) {
    _isSubmitSucceeded = true;
    widget.hasUnsavedChangesNotifier?.value = false;
    final navigator = Navigator.of(context);
    final formRoute = ModalRoute.of(context);
    // 저장 중 이미 나가기로 닫힌 화면이면 중복 pop 금지
    if (formRoute == null || !formRoute.isActive) return;
    // 저장 중 띄운 이탈 확인 모달 등 위에 쌓인 라우트 정리 > 폼 화면만 닫기
    navigator.popUntil((route) => route == formRoute);
    navigator.pop(submitResult);
  }
}
