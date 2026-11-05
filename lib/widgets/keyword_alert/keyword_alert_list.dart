import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 등록 키워드 목록: 키워드 + 삭제(X) 버튼 (삭제 중 > 스피너), 비었으면 안내 문구 (#1020)
class KeywordAlertList extends StatelessWidget {
  final List<KeywordAlert> keywordAlerts;
  final Set<String> deletingKeywordAlertIds;
  final ValueChanged<KeywordAlert> onDeletePressed;

  const KeywordAlertList({
    super.key,
    required this.keywordAlerts,
    required this.deletingKeywordAlertIds,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (keywordAlerts.isEmpty) return _buildEmptyGuide();
    return ListView.separated(
      padding: EdgeInsets.only(bottom: 24.h),
      itemCount: keywordAlerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildKeywordRow(keywordAlerts[index]),
    );
  }

  /// 빈 목록 안내 (키보드가 올라와도 넘치지 않게 스크롤)
  Widget _buildEmptyGuide() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 40.h),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 48.sp, color: AppColors.opacity40White),
          SizedBox(height: 16.h),
          Text(
            '등록한 키워드가 없어요',
            style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '찾는 물건 이름을 등록해 보세요',
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordRow(KeywordAlert keywordAlert) {
    final keyword = keywordAlert.keyword ?? '';
    final isDeleting = deletingKeywordAlertIds.contains(keywordAlert.keywordAlertId);
    return Container(
      padding: EdgeInsets.only(left: 16.w),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              keyword,
              style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 터치 영역 48px (IconButton 기본)
          isDeleting
              ? const SizedBox(width: 48, height: 48, child: Center(child: CommonLoadingIndicator(size: 18)))
              : IconButton(
                  onPressed: () => onDeletePressed(keywordAlert),
                  tooltip: '$keyword 삭제',
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.opacity60White),
                ),
        ],
      ),
    );
  }
}
