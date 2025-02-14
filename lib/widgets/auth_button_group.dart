import 'package:flutter/material.dart';

//FIXME: 버튼 그룹화 디자인 수정 필요

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
