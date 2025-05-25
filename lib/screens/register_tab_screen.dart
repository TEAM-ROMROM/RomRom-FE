import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RegisterTabScreen extends StatelessWidget {
  const RegisterTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '등록 페이지 내용',
        style: CustomTextStyles.h3,
      ),
    );
  }
}