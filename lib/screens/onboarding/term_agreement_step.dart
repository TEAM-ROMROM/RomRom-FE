import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/term_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/term_contents.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/onboarding/term_detail_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
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

  // 약관 내용 저장용
  Map<TermsType, TermContents>? _termsContents;
  bool _isLoading = true;
  bool _isSaving = false; // API 호출 중 상태

  final MemberApi _memberApi = MemberApi();

  // 필수 약관만 체크하는 getter
  bool get _allRequiredChecked => TermsType.values
      .where((term) => term.isRequired)
      .every((term) => _termsChecked[term] == true);

  // 모든 약관이 체크되었는지 확인하는 getter
  bool get _allTermsChecked => _termsChecked.values.every((checked) => checked);

  @override
  void initState() {
    super.initState();
    _loadTermsContents();
  }

  // 약관 내용 로드
  Future<void> _loadTermsContents() async {
    try {
      final termsContents = await TermContents.loadAll();
      setState(() {
        _termsContents = termsContents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('약관 로드 실패: $e');
    }
  }

  // 약관 동의 처리 및 API 호출
  Future<void> _handleTermsAgreement() async {
    if (_isSaving) return; // 중복 호출 방지

    setState(() {
      _isSaving = true;
    });

    try {
      // 마케팅 동의 여부 확인
      final isMarketingAgreed = _termsChecked[TermsType.marketing] ?? false;

      // 약관 동의 정보 전송
      final isSuccess = await _memberApi.saveTermsAgreement(
        isMarketingInfoAgreed: isMarketingAgreed,
      );

      if (isSuccess) {
        // 사용자 정보 업데이트
        final userInfo = UserInfo();
        // 최신 회원 정보 재로드
        await userInfo.getUserInfo();

        // 다음 단계로 이동
        widget.onNext();
      } else {
        // 실패 시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('약관 동의 저장에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('약관 동의 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryYellow,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h), // 상단 공간

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
                  checkColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  side: BorderSide(
                    color: AppColors.primaryYellow,
                    width: 1.w,
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
            color: AppColors.textColorWhite.withValues(alpha: 0.2),
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
                        color: AppColors.textColorWhite.withValues(alpha: 0.6),
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
          }),

          // 하단 여백 채우기
          const Spacer(),

          // 동의하고 계속하기 버튼
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: CompletionButton(
              isEnabled: _allRequiredChecked && !_isSaving,
              enabledOnPressed: _handleTermsAgreement,
              buttonText: _isSaving ? '처리 중...' : '동의하고 계속하기',
            ),
          ),
        ],
      ),
    );
  }

  // 약관 항목 생성 함수
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
            checkColor: AppColors.primaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            side: BorderSide(
              color: AppColors.primaryYellow,
              width: 1.w,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          term.isRequired ? '[필수] ' : '[선택]',
          style: CustomTextStyles.p1.copyWith(
            color: AppColors.primaryYellow.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
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

        // 상세 보기 버튼
        GestureDetector(
          onTap: () async {
            if (_termsContents != null) {
              final termsContent = _termsContents![term]!;
              context.navigateTo(
                screen: TermDetailScreen(termsContent: termsContent),
                type: NavigationTypes.push,
              );
            }
          },
          child: Icon(
            AppIcons.dotsVertical,
            size: 18.h,
            color: AppColors.textColorWhite,
          ),
        ),
      ],
    );
  }
}
