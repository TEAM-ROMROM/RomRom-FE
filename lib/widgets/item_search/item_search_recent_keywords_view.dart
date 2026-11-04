// 물품 검색 전 화면: 최근 검색어 목록(탭 > 다시 검색, X > 삭제), 전체 삭제, 없으면 안내 문구
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ItemSearchRecentKeywordsView extends StatelessWidget {
  static const String emptyGuideText = '찾고 싶은 물건의 이름이나 설명을 검색해 보세요';

  final List<String> recentKeywords;
  final ValueChanged<String> onKeywordTap;
  final ValueChanged<String> onKeywordRemove;
  final VoidCallback onClearAll;

  const ItemSearchRecentKeywordsView({
    super.key,
    required this.recentKeywords,
    required this.onKeywordTap,
    required this.onKeywordRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentKeywords.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Text(emptyGuideText, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
      );
    }
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('최근 검색어', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: onClearAll,
              child: Text('전체 삭제', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
            ),
          ],
        ),
        for (final recentKeyword in recentKeywords)
          InkWell(
            onTap: () => onKeywordTap(recentKeyword),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recentKeyword,
                      style: CustomTextStyles.p2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onKeywordRemove(recentKeyword),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.opacity60White),
                    tooltip: '$recentKeyword 삭제',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
