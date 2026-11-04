import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/chat_quick_replies.dart';
import 'package:romrom_fe/utils/chat_input_convenience_rules.dart';

/// 빠른 답장 노출·넣기 (#987): 빈 입력·포커스일 때만, 탭하면 입력창에 넣기만 (전송 안 함)
void main() {
  group('shouldShowQuickReplies', () {
    test('입력 가능·포커스·빈 입력 > 노출', () {
      expect(shouldShowQuickReplies(isInputDisabled: false, isInputFocused: true, inputText: '  '), isTrue);
    });

    test('글 있음·포커스 없음·입력 불가 > 숨김', () {
      expect(shouldShowQuickReplies(isInputDisabled: false, isInputFocused: true, inputText: '안녕'), isFalse);
      expect(shouldShowQuickReplies(isInputDisabled: false, isInputFocused: false, inputText: ''), isFalse);
      expect(shouldShowQuickReplies(isInputDisabled: true, isInputFocused: true, inputText: ''), isFalse);
    });
  });

  group('applyQuickReplyToInput', () {
    test('빈 입력 > 문구로 교체, 커서 문구 끝', () {
      final phrase = chatQuickReplyPhrases.first;
      final nextValue = applyQuickReplyToInput(currentValue: TextEditingValue.empty, phrase: phrase);

      expect(nextValue.text, phrase);
      expect(nextValue.selection, TextSelection.collapsed(offset: phrase.length));
    });

    test('글 있음 > 커서 자리에 삽입', () {
      const currentValue = TextEditingValue(text: '네 ', selection: TextSelection.collapsed(offset: 2));
      final nextValue = applyQuickReplyToInput(currentValue: currentValue, phrase: '감사합니다');

      expect(nextValue.text, '네 감사합니다');
      expect(nextValue.selection.baseOffset, 7);
    });

    test('선택 영역 없음 > 글 끝에 붙임', () {
      const currentValue = TextEditingValue(text: '네');
      expect(applyQuickReplyToInput(currentValue: currentValue, phrase: '!').text, '네!');
    });
  });

  test('빠른 답장 문구 원본 > 비어 있지 않고 중복 없음', () {
    expect(chatQuickReplyPhrases, isNotEmpty);
    expect(chatQuickReplyPhrases.toSet(), hasLength(chatQuickReplyPhrases.length));
  });
}
