import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

/// 작성 중 이탈 가드: 저장 중이면 이탈 무시, 미저장 변경 있으면 나가기 확인 모달 > 확인 시 [onLeave]
/// 변경 없으면 그대로 pop 허용, 코드상 Navigator.pop(저장 성공 등)은 가드 대상 아님
class UnsavedChangesGuard extends StatelessWidget {
  final ValueListenable<bool> hasUnsavedChangesListenable;
  // 이탈 차단 여부 (저장 진행 중 true > 뒤로가기·나가기 모달 모두 무시), 미지정 시 차단 없음
  final ValueListenable<bool>? isLeaveBlockedListenable;
  // 실제 화면 닫기 (확인 모달에서 나가기 선택 시)
  final VoidCallback onLeave;
  final Widget child;

  static const String leaveConfirmMessage = '작성 중인 내용이 사라져요.\n나가시겠어요?';
  static const String leaveConfirmText = '나가기';

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChangesListenable,
    this.isLeaveBlockedListenable,
    required this.onLeave,
    required this.child,
  });

  /// 이탈 요청 (앱바 뒤로가기 등): 차단 중이면 무시 > 변경 없으면 바로 [onLeave], 있으면 확인 후 [onLeave]
  static Future<void> requestLeave({
    required BuildContext context,
    required bool hasUnsavedChanges,
    bool isLeaveBlocked = false,
    required VoidCallback onLeave,
  }) async {
    if (isLeaveBlocked) return;
    if (!hasUnsavedChanges) {
      onLeave();
      return;
    }
    final bool? isLeaveConfirmed = await CommonModal.confirm(
      context: context,
      message: leaveConfirmMessage,
      confirmText: leaveConfirmText,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isLeaveConfirmed == true && context.mounted) onLeave();
  }

  @override
  Widget build(BuildContext context) {
    final isLeaveBlockedListenable = this.isLeaveBlockedListenable;
    return ListenableBuilder(
      listenable: Listenable.merge([hasUnsavedChangesListenable, ?isLeaveBlockedListenable]),
      builder: (context, guardedChild) {
        final hasUnsavedChanges = hasUnsavedChangesListenable.value;
        final isLeaveBlocked = isLeaveBlockedListenable?.value ?? false;
        return PopScope(
          // 변경 있거나 저장 중이면 시스템 뒤로가기·iOS 스와이프 차단
          canPop: !hasUnsavedChanges && !isLeaveBlocked,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            requestLeave(
              context: context,
              hasUnsavedChanges: hasUnsavedChanges,
              isLeaveBlocked: isLeaveBlocked,
              onLeave: onLeave,
            );
          },
          child: guardedChild!,
        );
      },
      child: child,
    );
  }
}
