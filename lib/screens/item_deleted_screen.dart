import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 게시글 삭제 제재 안내 화면
/// 관리자가 게시글을 삭제했을 때 표시되는 알림 화면
class ItemDeletedScreen extends StatefulWidget {
  final String itemTitle;
  final String deleteReason;

  const ItemDeletedScreen({super.key, required this.itemTitle, required this.deleteReason});

  @override
  State<ItemDeletedScreen> createState() => _ItemDeletedScreenState();
}

class _ItemDeletedScreenState extends State<ItemDeletedScreen> {
  /// X 버튼: 화면 닫기 + 플래그 리셋 (계정 제재와 달리 로그아웃 없음)
  void _handleClose() {
    ApiClient.resetItemDeletedFlag();
    Navigator.of(context).pop();
  }

  /// 문의하기 mailto 링크 실행
  Future<void> _launchContactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'romrom.noreply@gmail.com',
      queryParameters: {'subject': '[롬롬 게시글 삭제 문의] 게시글: ${widget.itemTitle}'},
    );

    final launched = await canLaunchUrl(uri);
    if (launched) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        CommonSnackBar.show(
          context: context,
          message: '메일 앱이 없습니다. romrom.noreply@gmail.com 으로 문의해 주세요.',
          type: SnackBarType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // X 닫기 버튼 (44x44 터치 영역)
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 16.h),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleClose,
                child: SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: Center(
                    child: Icon(AppIcons.cancel, size: 24.sp, color: AppColors.textColorWhite),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 제목
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: RichText(
                text: TextSpan(
                  style: CustomTextStyles.h1.copyWith(height: 1.2),
                  children: [
                    TextSpan(text: '게시글이 커뮤니티 가이드라인\n위반으로 '.noBreak),
                    TextSpan(
                      text: '삭제'.noBreak,
                      style: CustomTextStyles.h1.copyWith(height: 1.2, color: AppColors.warningRed),
                    ),
                    TextSpan(text: '되었습니다'.noBreak),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 정보 박스
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('콘텐츠 정보', widget.itemTitle),
                    SizedBox(height: 8.h),
                    _buildInfoRow('삭제 사유', widget.deleteReason),
                    SizedBox(height: 16.h),
                    Text(
                      '* 반복적인 가이드라인 위반 시 서비스 이용이 제한될 수 있습니다.'.noBreak,
                      style: CustomTextStyles.p3.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: AppColors.opacity60White,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 문의하기 버튼
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Material(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: _launchContactEmail,
                    borderRadius: BorderRadius.circular(10.r),
                    child: Center(
                      child: Text(
                        '문의하기',
                        style: CustomTextStyles.p1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorBlack,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯 (• 라벨 : 값)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 7.h),
          child: Container(
            width: 4.w,
            height: 4.w,
            decoration: const BoxDecoration(color: AppColors.textColorWhite, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: 8.w),
        Text('$label : '.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        Expanded(
          child: Text(value.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        ),
      ],
    );
  }
}
