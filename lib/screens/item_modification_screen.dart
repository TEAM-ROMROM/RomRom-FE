import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/unsaved_changes_guard.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_input_form.dart';

/// 물품 수정 화면 (수정 중 이탈 시 확인 모달)
class ItemModificationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final String? itemId;

  const ItemModificationScreen({super.key, required this.itemId, this.onClose});

  @override
  ConsumerState<ItemModificationScreen> createState() => _ItemModificationScreenState();
}

class _ItemModificationScreenState extends ConsumerState<ItemModificationScreen> {
  bool _isLoading = true;
  Item? _myItem;
  // 폼이 갱신하는 미저장 변경 여부 (불러온 물품 기준)
  final ValueNotifier<bool> _hasUnsavedChangesNotifier = ValueNotifier<bool>(false);
  // 폼이 갱신하는 저장 진행 여부 (true면 이탈 차단)
  final ValueNotifier<bool> _isSaveInProgressNotifier = ValueNotifier<bool>(false);

  /// 내 물품 리스트 로드
  Future<void> _loadMyItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ref.read(itemRepositoryProvider).getItemDetail(widget.itemId);
      if (!mounted) return;

      setState(() {
        _myItem = response.item!;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  @override
  void dispose() {
    _hasUnsavedChangesNotifier.dispose();
    _isSaveInProgressNotifier.dispose();
    super.dispose();
  }

  /// 화면 닫기 (onClose 우선, 없으면 pop)
  void _closeScreen() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      hasUnsavedChangesListenable: _hasUnsavedChangesNotifier,
      isLeaveBlockedListenable: _isSaveInProgressNotifier,
      onLeave: _closeScreen,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: CommonAppBar(
            title: '수정하기',
            onBackPressed: () => UnsavedChangesGuard.requestLeave(
              context: context,
              hasUnsavedChanges: _hasUnsavedChangesNotifier.value,
              isLeaveBlocked: _isSaveInProgressNotifier.value,
              onLeave: _closeScreen,
            ),
            showBottomBorder: true,
          ),
          body: _isLoading
              ? const Center(child: CommonLoadingIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.only(top: 24.h, bottom: 24.h, left: 24.w),
                  child: RegisterInputForm(
                    isEditMode: true, // true면 수정화면
                    item: _myItem, // 수정 모드에서 사용
                    hasUnsavedChangesNotifier: _hasUnsavedChangesNotifier,
                    isSaveInProgressNotifier: _isSaveInProgressNotifier,
                  ),
                ),
        ),
      ),
    );
  }
}
