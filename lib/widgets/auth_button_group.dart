import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButtonGroup extends StatelessWidget {
  final List<Widget> buttons;

  const AuthButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[buttons[i], if (i < buttons.length - 1) SizedBox(height: 12.h)],
      ],
    );
  }
}
