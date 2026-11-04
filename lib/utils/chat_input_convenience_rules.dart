// 채팅 입력 편의 판정 순수 함수: 빠른 답장 노출·넣기
import 'package:flutter/services.dart';

/// 빠른 답장 노출 여부 (입력 가능·포커스·입력 글 없음)
bool shouldShowQuickReplies({required bool isInputDisabled, required bool isInputFocused, required String inputText}) =>
    !isInputDisabled && isInputFocused && inputText.trim().isEmpty;

/// 빠른 답장 넣기: 빈 입력 > 문구로 교체, 글 있음 > 선택 영역(커서) 자리에 삽입 (커서는 문구 끝, 전송 안 함)
TextEditingValue applyQuickReplyToInput({required TextEditingValue currentValue, required String phrase}) {
  if (currentValue.text.trim().isEmpty) {
    return TextEditingValue(
      text: phrase,
      selection: TextSelection.collapsed(offset: phrase.length),
    );
  }
  final selection = currentValue.selection;
  // 선택 영역 없음(-1) > 글 끝에 붙임
  final start = selection.isValid ? selection.start : currentValue.text.length;
  final end = selection.isValid ? selection.end : currentValue.text.length;
  final nextText = currentValue.text.replaceRange(start, end, phrase);
  return TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: start + phrase.length),
  );
}
