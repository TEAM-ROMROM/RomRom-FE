import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/term_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/term_contents.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 이용약관 화면
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  Map<TermsType, TermContents>? _termsContents;
  bool _isLoading = true;

  // 각 약관별 펼침 상태 관리
  final Map<TermsType, bool> _expandedState = {
    for (var term in TermsType.values) term: false,
  };

  @override
  void initState() {
    super.initState();
    _loadTermsContents();
  }

  /// 약관 내용 로드
  Future<void> _loadTermsContents() async {
    try {
      final termsContents = await TermContents.loadAll();
      if (mounted) {
        setState(() {
          _termsContents = termsContents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('약관 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '이용 약관',
        showBottomBorder: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryYellow,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // 약관 아코디언 목록
                  ...TermsType.values.map((term) => _buildTermAccordion(term)),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  /// 약관 아코디언 아이템
  Widget _buildTermAccordion(TermsType term) {
    final isExpanded = _expandedState[term] ?? false;
    final content = _termsContents?[term]?.content ?? '';

    return Column(
      children: [
        // 아코디언 헤더 (클릭 영역)
        InkWell(
          onTap: () {
            setState(() {
              _expandedState[term] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                // 펼침/접힘 아이콘
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24.sp,
                    color: AppColors.textColorWhite,
                  ),
                ),
                SizedBox(width: 8.w),
                // 약관 제목
                Expanded(
                  child: Text(
                    term.title,
                    style: CustomTextStyles.p1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 아코디언 내용 (펼쳤을 때만 표시)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 300.h),
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.secondaryBlack1,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: CustomTextStyles.p3.copyWith(
                  color: AppColors.textColorWhite.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        // 구분선
        if (term != TermsType.values.last)
          Container(
            height: 1.h,
            color: AppColors.opacity10White,
          ),
      ],
    );
  }
}
