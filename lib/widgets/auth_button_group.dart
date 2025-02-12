import 'package:flutter/material.dart';

/// 버튼 그룹화해놓은 건데 디자인 나오면 수정
class AuthButtonGroup extends StatelessWidget {
  final List<Widget> buttons;

  const AuthButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }
}
