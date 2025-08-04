import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_input_form.dart';

/// 물품 등록 화면
class ItemRegisterScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ItemRegisterScreen({super.key, this.onClose});

  @override
  State<ItemRegisterScreen> createState() => _ItemRegisterScreenState();
}

class _ItemRegisterScreenState extends State<ItemRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonAppBar(
          title: '물건 등록하기',
          onBackPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            }
          },
          showBottomBorder: true,
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.only(top: 24.h, bottom: 24.h, left: 24.w),
            child: const RegisterInputForm(
              isEditMode: false, // false면 등록화면
            )),
      ),
    );
  }
}
