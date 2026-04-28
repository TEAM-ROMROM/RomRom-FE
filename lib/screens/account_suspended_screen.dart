import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 제재된 사용자 안내 화면
/// suspendedUntil >= 2100-01-01 이면 영구 정지, 아니면 일시 정지
class AccountSuspendedScreen extends StatefulWidget {
  final String suspendReason;
  final String suspendedUntil;

  const AccountSuspendedScreen({super.key, required this.suspendReason, required this.suspendedUntil});

  @override
  State<AccountSuspendedScreen> createState() => _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState extends State<AccountSuspendedScreen> {
  String _nickname = '사용자';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  @override
  void dispose() {
    ApiClient.resetSuspendedFlag();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo();
      if (mounted) {
        setState(() {
          _nickname = userInfo.nickname ?? '사용자';
        });
      }
    } catch (_) {
      // 토큰 삭제 후 진입 시 API 실패 가능 → 기본값 유지
    }
  }

  /// 영구 정지 여부 판별
  bool get _isPermanentBan {
    try {
      final dateTime = DateTime.parse(widget.suspendedUntil);
      return dateTime.year >= 2100;
    } catch (_) {
      return false;
    }
  }

  /// 제재 기간 포맷 (일시 정지용)
  String get _formattedSuspendedUntil {
    try {
      final dateTime = DateTime.parse(widget.suspendedUntil);
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}까지';
    } catch (_) {
      return widget.suspendedUntil;
    }
  }

  /// 문의하기 mailto 링크 실행
  Future<void> _launchContactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'romrom.noreply@gmail.com',
      queryParameters: {'subject': '[롬롬 이용 제한 문의] 계정명: $_nickname'},
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

  /// X 버튼 터치 시 로그인 화면으로 이동 (로그아웃 처리)
  Future<void> _handleClose(BuildContext context) async {
    final authService = AuthService();
    await authService.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPermanent = _isPermanentBan;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // X 닫기 버튼 (터치 영역 44x44 확보)
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 16.h),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleClose(context),
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
                    TextSpan(text: '서비스 이용이\n'.noBreak),
                    TextSpan(
                      text: (isPermanent ? '영구적으로 제한' : '일시적으로 제한').noBreak,
                      style: CustomTextStyles.h1.copyWith(height: 1.2, color: AppColors.primaryYellow),
                    ),
                    TextSpan(text: '되었습니다'.noBreak),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // 부제목
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: CustomTextStyles.p1.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AppColors.opacity60White,
                  ),
                  children: [
                    TextSpan(text: '안녕하세요, $_nickname님. '.noBreak),
                    TextSpan(text: (isPermanent ? '운영 정책 위반으로 인해\n' : '롬롬 커뮤니티 가이드라인\n위반으로 ').noBreak),
                    TextSpan(
                      text: (isPermanent ? '롬롬 서비스 이용이 영구적으로 제한' : '서비스 이용이 제한').noBreak,
                      style: CustomTextStyles.p1.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: AppColors.warningRed,
                      ),
                    ),
                    TextSpan(text: (isPermanent ? '되었습니다.' : '되었음을 알려드립니다.').noBreak),
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
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제재 사유
                    _buildInfoRow('제재 사유', widget.suspendReason),

                    // 제재 기간 (일시 정지만)
                    if (!isPermanent) ...[SizedBox(height: 8.h), _buildInfoRow('제재 기간', _formattedSuspendedUntil)],

                    SizedBox(height: 16.h),

                    // 하단 안내 문구
                    Text(
                      (isPermanent ? '* 영구 제재 시 동일한 계정 및 기기로는 재가입이 불가능합니다.' : '* 해당 기간이 지나면 자동으로 제한이 해제됩니다.').noBreak,
                      style: CustomTextStyles.p3.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.0,
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
                height: 56.h,
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
        // 불릿 점
        Padding(
          padding: EdgeInsets.only(top: 7.h),
          child: Container(
            width: 4.w,
            height: 4.w,
            decoration: const BoxDecoration(color: AppColors.textColorWhite, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: 8.w),
        // 라벨
        Text('$label : '.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        // 값
        Expanded(
          child: Text(value.noBreak, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
        ),
      ],
    );
  }
}
