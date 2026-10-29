import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/widgets/common/unsaved_changes_guard.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_input_form.dart';

/// 물품 등록 화면 (작성 중 이탈 시 확인 모달)
class ItemRegisterScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ItemRegisterScreen({super.key, this.onClose});

  @override
  State<ItemRegisterScreen> createState() => _ItemRegisterScreenState();
}

class _ItemRegisterScreenState extends State<ItemRegisterScreen> {
  // 폼이 갱신하는 미저장 변경 여부
  final ValueNotifier<bool> _hasUnsavedChangesNotifier = ValueNotifier<bool>(false);
  // 폼이 갱신하는 저장 진행 여부 (true면 이탈 차단)
  final ValueNotifier<bool> _isSaveInProgressNotifier = ValueNotifier<bool>(false);

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
            title: '물품 등록하기',
            onBackPressed: () => UnsavedChangesGuard.requestLeave(
              context: context,
              hasUnsavedChanges: _hasUnsavedChangesNotifier.value,
              isLeaveBlocked: _isSaveInProgressNotifier.value,
              onLeave: _closeScreen,
            ),
            showBottomBorder: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(top: 16.h, bottom: 24.h, left: 24.w),
            child: RegisterInputForm(
              isEditMode: false, // false면 등록화면
              hasUnsavedChangesNotifier: _hasUnsavedChangesNotifier,
              isSaveInProgressNotifier: _isSaveInProgressNotifier,
            ),
          ),
        ),
      ),
    );
  }
}
