import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  State<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen> {
  bool showRegisterScreen = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemRegisterScreen(
                onClose: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
          // 등록 화면에서 돌아온 뒤 필요한 상태 갱신
          setState(() {});
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
