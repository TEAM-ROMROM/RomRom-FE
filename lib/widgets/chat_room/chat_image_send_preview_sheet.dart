// 채팅 사진 보내기 전 미리보기 시트: 고른 사진 가로 목록 > X로 빼기 > 보내기 (모두 빼면 닫힘, 닫기 > 전송 안 함)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 미리보기 시트 띄우기 > 보낼 사진 목록 (닫기·모두 빼기 > null)
Future<List<XFile>?> showChatImageSendPreviewSheet({required BuildContext context, required List<XFile> images}) {
  return showModalBottomSheet<List<XFile>>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (_) => ChatImageSendPreviewSheet(images: images),
  );
}

class ChatImageSendPreviewSheet extends StatefulWidget {
  final List<XFile> images;

  const ChatImageSendPreviewSheet({super.key, required this.images});

  // 썸네일 한 변·간격·빼기 버튼 크기 (시트는 고정 px, iPad 확대 방지)
  static const double thumbnailSidePixels = 96;
  static const double thumbnailGapPixels = 8;
  static const double removeButtonSidePixels = 22;

  @override
  State<ChatImageSendPreviewSheet> createState() => _ChatImageSendPreviewSheetState();
}

class _ChatImageSendPreviewSheetState extends State<ChatImageSendPreviewSheet> {
  late final List<XFile> _selectedImages = [...widget.images];

  /// 사진 빼기 (마지막 장이면 시트 닫기 > 전송 안 함)
  void _removeImageAt(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    if (_selectedImages.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _selectedImages.removeAt(index));
  }

  void _onSendPressed() => Navigator.of(context).pop(List<XFile>.unmodifiable(_selectedImages));

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    // 썸네일 디코딩 크기 (물리 px, 원본 디코딩 시 10장 메모리 급증 방지)
    final thumbnailDecodePixels = (ChatImageSendPreviewSheet.thumbnailSidePixels * devicePixelRatio).round();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '사진 ${_selectedImages.length}장',
              style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            // 빼기 버튼이 썸네일 밖으로 6px 걸침 > 위 여백 포함
            height: ChatImageSendPreviewSheet.thumbnailSidePixels + 6,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 6),
              itemCount: _selectedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: ChatImageSendPreviewSheet.thumbnailGapPixels),
              itemBuilder: (_, index) => _buildThumbnail(index, thumbnailDecodePixels),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CompletionButton(
              isEnabled: _selectedImages.isNotEmpty,
              buttonText: '보내기',
              enabledOnPressed: _onSendPressed,
            ),
          ),
        ],
      ),
    );
  }

  /// 썸네일 1장: 사진 + 우상단 빼기 버튼
  Widget _buildThumbnail(int index, int thumbnailDecodePixels) {
    const side = ChatImageSendPreviewSheet.thumbnailSidePixels;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_selectedImages[index].path),
              key: ValueKey(_selectedImages[index].path),
              width: side,
              height: side,
              fit: BoxFit.cover,
              cacheWidth: thumbnailDecodePixels,
              errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.opacity10White),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removeImageAt(index),
              child: Container(
                width: ChatImageSendPreviewSheet.removeButtonSidePixels,
                height: ChatImageSendPreviewSheet.removeButtonSidePixels,
                decoration: const BoxDecoration(
                  color: AppColors.itemPictureRemoveButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.cancel, color: AppColors.textColorBlack, size: 12, semanticLabel: '사진 빼기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
