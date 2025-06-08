import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/data/terms_data.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/term_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/onboarding/term_detail_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

class TermAgreementStep extends StatefulWidget {
  final VoidCallback onNext;

  const TermAgreementStep({super.key, required this.onNext});

  @override
  State<TermAgreementStep> createState() => _TermAgreementStepState();
}

class _TermAgreementStepState extends State<TermAgreementStep> {
  // enum 활용한 약관 동의 상태 관리
  final Map<TermsType, bool> _termsChecked = {
    TermsType.service: false,
    TermsType.privacy: false,
    TermsType.location: false,
    TermsType.marketing: false,
  };

  // 필수 약관만 체크하는 getter
  bool get _allRequiredChecked => TermsType.values
      .where((term) => term.isRequired)
      .every((term) => _termsChecked[term] == true);

  // 모든 약관이 체크되었는지 확인하는 getter
  bool get _allTermsChecked => _termsChecked.values.every((checked) => checked);

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
                  value: _allTermsChecked,
                  onChanged: (value) {
                    setState(() {
                      for (var term in TermsType.values) {
                        _termsChecked[term] = value ?? false;
                      }
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
            color: const Color(0xFFFFFF33).withOpacity(0.2),
          ),

          SizedBox(height: 24.h),

          // 각 약관 항목 생성
          ...TermsType.values.map((term) {
            final widget = _buildTermsItem(term);

            // 마케팅 동의에만 부가 설명 추가
            if (term == TermsType.marketing && term.description != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget,
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.only(left: 80.0.w),
                    child: Text(
                      term.description!,
                      style: CustomTextStyles.p3.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorWhite.withOpacity(0.6),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              );
            }

            return Column(
              children: [
                widget,
                SizedBox(height: 32.h),
              ],
            );
          }).toList(),

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

  // enum을 활용한 약관 항목 생성 함수
  Widget _buildTermsItem(TermsType term) {
    return Row(
      children: [
        SizedBox(
          width: 20.w,
          height: 20.h,
          child: Checkbox(
            value: _termsChecked[term],
            onChanged: (value) {
              setState(() {
                _termsChecked[term] = value ?? false;
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
          term.isRequired ? '[필수] ' : '[선택]',
          style: CustomTextStyles.p1.copyWith(
            color: AppColors.primaryYellow,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            term.title,
            style: CustomTextStyles.h3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () {
            final termsContent = TermsData.termsContents[term]!;
            context.navigateTo(
              screen: TermDetailScreen(termsContent: termsContent),
              type: NavigationTypes.push,
            );
          },
          child: SizedBox(
            width: 18.w,
            height: 18.h,
            child: SvgPicture.asset(
              'assets/images/detailView.svg',
              width: 18.w,
              height: 18.h,
            ),
          ),
        ),
      ],
    );
  }
}
