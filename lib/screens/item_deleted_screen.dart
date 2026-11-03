import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/support_email_launcher.dart';

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
  // 알림 값 누락 시 대체 문구 (빈 칸 대신 표시)
  static const String _missingItemTitleText = '게시글 정보 없음';
  static const String _missingDeleteReasonText = '사유 정보 없음';

  String get _displayItemTitle => widget.itemTitle.trim().isEmpty ? _missingItemTitleText : widget.itemTitle;
  String get _displayDeleteReason =>
      widget.deleteReason.trim().isEmpty ? _missingDeleteReasonText : widget.deleteReason;

  /// X 버튼: 화면 닫기 (계정 제재와 달리 로그아웃 없음)
  void _handleClose() {
    Navigator.of(context).pop();
  }

  /// 문의하기 메일 (메일 앱 없으면 주소 안내)
  Future<void> _launchContactEmail() => launchSupportEmail(context, subject: '[롬롬 게시글 삭제 문의] 게시글: $_displayItemTitle');

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
                    child: Icon(AppIcons.cancel, size: 24.sp, color: AppColors.textColorWhite, semanticLabel: '닫기'),
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
                    _buildInfoRow('콘텐츠 정보', _displayItemTitle),
                    SizedBox(height: 8.h),
                    _buildInfoRow('삭제 사유', _displayDeleteReason),
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
