import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';

class RegisterTabScreen extends StatelessWidget {
  const RegisterTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ItemRegisterScreen()),
          );
        },
        label: const Text(
          '등록하기',
          style: TextStyle(color: AppColors.textColorBlack),
        ),
        icon: const Icon(Icons.add),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primaryYellow),
          iconColor: WidgetStateProperty.all(AppColors.primaryBlack),
        ),
      ),
    );
  }
}
