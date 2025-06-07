import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/category_completion_button.dart';

class UserInfoStep extends StatefulWidget {
  final VoidCallback onNext;

  const UserInfoStep({super.key, required this.onNext});

  @override
  State<UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<UserInfoStep> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _birthdayFocus = FocusNode();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_checkButtonState);
    _birthdayController.addListener(_checkButtonState);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdayController.dispose();
    _nicknameFocus.dispose();
    _birthdayFocus.dispose();
    super.dispose();
  }

  void _checkButtonState() {
    final bool isEnabled = _nicknameController.text.isNotEmpty &&
        _birthdayController.text.isNotEmpty;
    if (isEnabled != _isButtonEnabled) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),

          // 닉네임 입력 필드
          TextField(
            controller: _nicknameController,
            focusNode: _nicknameFocus,
            decoration: InputDecoration(
              labelText: '닉네임',
              hintText: '2~8자 이내로 입력해주세요',
              labelStyle: CustomTextStyles.p2,
              hintStyle: CustomTextStyles.p3.copyWith(
                color: AppColors.opacity50White,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.opacity50White, width: 1.w),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            style: CustomTextStyles.p2,
          ),

          SizedBox(height: 32.h),

          // 생년월일 입력 필드
          TextField(
            controller: _birthdayController,
            focusNode: _birthdayFocus,
            decoration: InputDecoration(
              labelText: '생년월일',
              hintText: 'YYYY-MM-DD 형식으로 입력해주세요',
              labelStyle: CustomTextStyles.p2,
              hintStyle: CustomTextStyles.p3.copyWith(
                color: AppColors.opacity50White,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.opacity50White, width: 1.w),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            style: CustomTextStyles.p2,
          ),

          // 하단 여백 채우기
          const Spacer(),

          // 다음 단계 버튼
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: CategoryCompletionButton(
              isEnabled: _isButtonEnabled,
              enabledOnPressed: () async {
                //TODO: 로직 추가
                widget.onNext();
              },
              buttonText: '다음',
            ),
          ),
        ],
      ),
    );
  }
}
