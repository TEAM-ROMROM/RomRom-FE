// 채팅 입력창 위 빠른 답장 줄: 가로 스크롤 문구 칩, 탭 > 입력창에 넣기 (전송 안 함)
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/chat_quick_replies.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

class ChatQuickReplyBar extends StatelessWidget {
  // 노출 여부 (입력 가능·포커스·빈 입력일 때 true)
  final bool isVisible;
  final ValueChanged<String> onPhraseSelected;
  final List<String> phrases;

  const ChatQuickReplyBar({
    super.key,
    required this.isVisible,
    required this.onPhraseSelected,
    this.phrases = chatQuickReplyPhrases,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.bottomCenter,
      child: isVisible ? _buildPhraseRow() : const SizedBox(width: double.infinity),
    );
  }

  Widget _buildPhraseRow() {
    // 입력창 밖 탭으로 키보드가 닫히지 않게 입력 탭 영역으로 묶음, 높이는 글자 크기 따라 (iPad·큰 글씨 잘림 방지)
    return TextFieldTapRegion(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
        child: Row(
          children: [
            for (final (index, phrase) in phrases.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              _buildPhraseChip(phrase),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseChip(String phrase) {
    return AppPressable(
      onTap: () => onPhraseSelected(phrase),
      enableRipple: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.opacity10White),
        ),
        child: Text(
          phrase,
          style: CustomTextStyles.p3.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
