import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '채팅 페이지 내용',
        style: CustomTextStyles.h3,
      ),
    );
  }
}