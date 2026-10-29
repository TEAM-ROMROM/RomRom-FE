// 물품 등록 이탈 경고: 폼 값 스냅샷, 진입 시점 대비 변경 여부, 부모 notifier 프레임 후 전달
part of '../register_input_form.dart';

mixin _RegisterInputFormUnsavedChanges on _RegisterInputFormStateFields {
  /// 현재 폼 값 > 스냅샷
  RegisterFormSnapshot _captureFormSnapshot() {
    return RegisterFormSnapshot(
      existingImageUrls: List.unmodifiable(_existingImageUrls),
      newImagePaths: _newImageFiles.map((file) => file.path).toList(growable: false),
      itemName: titleController.text,
      itemDescription: descriptionController.text,
      category: selectedCategory,
      conditions: List.unmodifiable(selectedItemConditionTypes),
      tradeOptions: selectedTradeOptions.toSet(),
      priceText: priceController.text,
      isAiPredictedPrice: useAiPrice,
      latitude: _latitude,
      longitude: _longitude,
    );
  }

  /// 미저장 변경 여부 (초기화 전·저장 성공 후 false)
  bool get _hasUnsavedChanges {
    final initialFormSnapshot = _initialFormSnapshot;
    if (initialFormSnapshot == null || _isSubmitSucceeded) return false;
    return _captureFormSnapshot().hasChangesFrom(initialFormSnapshot);
  }

  /// 미저장 변경 여부 부모 전달 (build 중 부모 갱신 금지 > 프레임 후)
  void _reportUnsavedChangesAfterFrame() {
    final hasUnsavedChangesNotifier = widget.hasUnsavedChangesNotifier;
    if (hasUnsavedChangesNotifier == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) hasUnsavedChangesNotifier.value = _hasUnsavedChanges;
    });
  }
}
