import 'package:flutter/material.dart';

class AuthButtonGroup extends StatelessWidget {
  final List<Widget> buttons;

  const AuthButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: buttons);
  }
}
