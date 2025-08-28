import 'package:flutter/services.dart';

class PriceCommaFormatter extends TextInputFormatter {
  const PriceCommaFormatter();

  static final _digitsOnly = RegExp(r'\d');

  /// 1234567 -> 1,234,567
  String _format(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      buf.write(digits[i]);
      final posFromEnd = len - i - 1;
      if (posFromEnd % 3 == 0 && posFromEnd != 0) buf.write(',');
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 커서 위치 이전 숫자 개수
    final selectionIndex =
        newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final left = newValue.text.substring(0, selectionIndex);
    final digitsBeforeCursor =
        left.split('').where((c) => _digitsOnly.hasMatch(c)).length;

    // 숫자만 추출
    var digits =
        newValue.text.split('').where((c) => _digitsOnly.hasMatch(c)).join();

    // 앞자리 0 처리
    if (digits.length > 1 && digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    if (digits.isEmpty) digits = '0';

    // 포맷 적용
    final formatted = _format(digits);

    // 새 포맷에서 커서 위치 보정
    int newCursor = 0, seenDigits = 0;
    for (; newCursor < formatted.length; newCursor++) {
      if (_digitsOnly.hasMatch(formatted[newCursor])) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) {
          newCursor++;
          break;
        }
      }
    }
    if (digitsBeforeCursor == 0) newCursor = 0;
    if (newCursor > formatted.length) newCursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }

  /// 간단히 포맷 문자열만 얻고 싶을 때
  static String formatNumber(int number) {
    final raw = number.toString();
    var digits = raw.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';
    final buf = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      buf.write(digits[i]);
      final posFromEnd = len - i - 1;
      if (posFromEnd % 3 == 0 && posFromEnd != 0) buf.write(',');
    }
    return buf.toString();
  }
}
