import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

class UserInfoStep extends StatefulWidget {
  final VoidCallback onNext;

  const UserInfoStep({super.key, required this.onNext});

  @override
  State<UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<UserInfoStep> {
  bool _serviceTermsChecked = false;
  bool _privacyPolicyChecked = false;
  bool _locationServiceChecked = false;
  bool _marketingChecked = false;

  bool get _allRequiredChecked =>
      _serviceTermsChecked &&
      _privacyPolicyChecked &&
      _locationServiceChecked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 56.h), // 상단 공간

          // 약관 전체 동의
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Checkbox(
                  value: _serviceTermsChecked &&
                      _privacyPolicyChecked &&
                      _locationServiceChecked &&
                      _marketingChecked,
                  onChanged: (value) {
                    setState(() {
                      _serviceTermsChecked = value ?? false;
                      _privacyPolicyChecked = value ?? false;
                      _locationServiceChecked = value ?? false;
                      _marketingChecked = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryYellow,
                  checkColor: AppColors.textColorBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '약관 전체 동의',
                style: CustomTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),

          SizedBox(height: 16.h), // 약관 전체 동의와 다음 항목 사이 공간

          // 구분선
          Container(
            width: 345.w,
            height: 1.h,
            color: Color(0xFFFFFF33).withOpacity(0.2),
          ),

          SizedBox(height: 24.h,),

          // 서비스 이용약관
          _buildTermsItem(
            isChecked: _serviceTermsChecked,
            onChanged: (value) {
              setState(() => _serviceTermsChecked = value ?? false);
            },
            title: '서비스 이용약관',
            isRequired: true,
            onDetailPressed: () {
              // TODO: 서비스 이용약관 상세 보기
            },
          ),

          SizedBox(height: 32.h),

          // 개인정보 수집 및 이용동의
          _buildTermsItem(
            isChecked: _privacyPolicyChecked,
            onChanged: (value) {
              setState(() => _privacyPolicyChecked = value ?? false);
            },
            title: '개인정보 수집 및 이용동의',
            isRequired: true,
            onDetailPressed: () {
              // TODO: 개인정보 수집 및 이용동의 상세 보기
            },
          ),

          SizedBox(height: 32.h),

          // 위치정보서비스 이용약관
          _buildTermsItem(
            isChecked: _locationServiceChecked,
            onChanged: (value) {
              setState(() => _locationServiceChecked = value ?? false);
            },
            title: '위치정보서비스 이용약관',
            isRequired: true,
            onDetailPressed: () {
              // TODO: 위치정보서비스 이용약관 상세 보기
            },
          ),

          SizedBox(height: 32.h),

          // 마케팅정보수신 동의
          _buildTermsItem(
            isChecked: _marketingChecked,
            onChanged: (value) {
              setState(() => _marketingChecked = value ?? false);
            },
            title: '마케팅정보수신 동의',
            isRequired: false,
            onDetailPressed: () {
              // TODO: 마케팅정보수신 동의 상세 보기
            },
          ),

          SizedBox(height: 8.h),

          // 마케팅 정보 수신 동의 부가 설명
          Padding(
            padding: EdgeInsets.only(left: 80.0.w),
            child: Text(
              '(이메일, SMS, 푸시알림 등)',
              style: CustomTextStyles.p3.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textColorWhite.withOpacity(0.6),
              ),
            ),
          ),

          // 하단 여백 채우기
          const Spacer(),

          // 동의하고 계속하기 버튼
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: CompletionButton(
              isEnabled: _allRequiredChecked,
              enabledOnPressed: () {
                widget.onNext();
              },
              buttonText: '동의하고 계속하기',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsItem({
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required String title,
    required bool isRequired,
    required VoidCallback onDetailPressed,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20.w,
          height: 20.h,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: AppColors.primaryYellow,
            checkColor: AppColors.textColorBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          isRequired ? '[필수] ' : '[선택]',
          style: CustomTextStyles.p1.copyWith(
            color: AppColors.primaryYellow,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          // 텍스트를 Expanded로 감싸 남은 공간을 차지하도록 함
          child: Text(
            title,
            style: CustomTextStyles.h3,
            overflow: TextOverflow.ellipsis, // 텍스트가 너무 길면 ...으로 표시
          ),
        ),
        GestureDetector(
            onTap: onDetailPressed,
            child: SizedBox(
                width: 18.w,
                height: 18.h,
                child: SvgPicture.asset(
                  'assets/images/detailView.svg',
                  width: 18.w,
                  height: 18.h,
                )))
      ],
    );
  }
}
