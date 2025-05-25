import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RequestManagementTabScreen extends StatelessWidget {
  const RequestManagementTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '요청 관리 페이지 내용',
        style: CustomTextStyles.h3,
      ),
    );
  }
}