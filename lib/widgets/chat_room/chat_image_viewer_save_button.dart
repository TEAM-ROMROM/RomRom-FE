// 채팅 사진 전체 보기 저장 버튼: 오른쪽 위, 현재 장 앨범 저장 > 결과 토스트 (권한 거부 > 설정 열기 안내, 채팅은 그대로)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/chat_image_save_result.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/providers/chat_image_gallery_saver_provider.dart';
import 'package:romrom_fe/utils/permission_settings_modal.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 전체 보기 현재 장 번호 (뷰어 onPageChanged가 갱신, 저장 버튼이 탭 시점에 읽음)
class PhotoViewerPageTracker {
  int currentPageIndex;

  PhotoViewerPageTracker({required this.currentPageIndex});
}

class ChatImageViewerSaveButton extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final PhotoViewerPageTracker pageTracker;

  const ChatImageViewerSaveButton({super.key, required this.imageUrls, required this.pageTracker});

  // 저장 버튼 크기 (모달·오버레이 고정 px, iPad 확대 방지)
  static const double buttonSize = 40;

  @override
  ConsumerState<ChatImageViewerSaveButton> createState() => _ChatImageViewerSaveButtonState();
}

class _ChatImageViewerSaveButtonState extends ConsumerState<ChatImageViewerSaveButton> {
  // 저장 중복 실행 방지 (finally에서 해제)
  bool _isSaving = false;

  /// 현재 장 저장: 중복 무시 > 저장 > 로딩 해제 > 결과 안내 (안내 모달 떠 있는 동안 로딩 표시 안 함)
  Future<void> _onSavePressed() async {
    if (_isSaving || widget.imageUrls.isEmpty) return;
    setState(() => _isSaving = true);
    final ChatImageSaveResult saveResult;
    try {
      final pageIndex = widget.pageTracker.currentPageIndex.clamp(0, widget.imageUrls.length - 1);
      saveResult = await ref.read(chatImageGallerySaverProvider).saveNetworkImage(widget.imageUrls[pageIndex]);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (mounted) await _showSaveResult(saveResult);
  }

  /// 저장 결과 안내 (성공·실패 토스트, 권한 거부 > 설정 열기 모달)
  Future<void> _showSaveResult(ChatImageSaveResult saveResult) async {
    switch (saveResult) {
      case ChatImageSaveResult.saved:
        CommonSnackBar.show(context: context, message: '사진을 앨범에 저장했어요.', type: SnackBarType.success);
      case ChatImageSaveResult.failed:
        CommonSnackBar.show(context: context, message: '사진을 저장하지 못했어요. 다시 시도해 주세요.', type: SnackBarType.error);
      case ChatImageSaveResult.permissionDenied:
        await showPermissionSettingsModal(context: context, message: '사진 저장 권한이 꺼져 있어요.\n설정에서 사진 추가를 허용해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Semantics(
            button: true,
            label: '사진 저장',
            child: AppPressable(
              onTap: _isSaving ? null : _onSavePressed,
              scaleDown: AppPressable.scaleIcon,
              enableRipple: false,
              child: SizedBox(
                width: ChatImageViewerSaveButton.buttonSize,
                height: ChatImageViewerSaveButton.buttonSize,
                child: Center(
                  child: _isSaving
                      ? const CommonLoadingIndicator.white()
                      : const Icon(Icons.file_download_outlined, color: AppColors.textColorWhite, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
