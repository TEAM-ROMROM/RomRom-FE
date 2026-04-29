import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/my_page/my_like_list_screen.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/screens/my_page/my_category_settings_screen.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/screens/my_page/my_profile_edit_screen.dart';
import 'package:romrom_fe/screens/my_page/terms_screen.dart';
import 'package:romrom_fe/screens/my_page/block_management_screen.dart';
import 'package:romrom_fe/screens/search_range_setting_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class MyPageTabScreen extends StatefulWidget {
  const MyPageTabScreen({super.key});

  @override
  State<MyPageTabScreen> createState() => _MyPageTabScreenState();
}

class _MyPageTabScreenState extends State<MyPageTabScreen> {
  String _nickname = '닉네임';
  String _location = '위치정보 없음';
  String? _profileUrl;
  String? _accountStatus;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAppVersion();
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final memberApi = MemberApi();
      final memberResponse = await memberApi.getMemberInfo();

      if (mounted) {
        setState(() {
          // 닉네임
          _nickname = memberResponse.member?.nickname ?? '닉네임';

          // 프로필 이미지
          _profileUrl = memberResponse.member?.profileUrl;

          // 계정 상태
          _accountStatus = memberResponse.member?.accountStatus;

          // 위치 정보 (주소 조합)
          final location = memberResponse.memberLocation;
          if (location != null) {
            final siGunGu = location.siGunGu ?? '';
            final eupMyoenDong = location.eupMyoenDong ?? '';
            final combinedLocation = '$siGunGu $eupMyoenDong'.trim();

            _location = combinedLocation.isNotEmpty ? combinedLocation : '위치정보 없음';
          }
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 실패: $e');
      // 기본값 유지
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = packageInfo.version);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: "마이페이지"
            Padding(
              padding: EdgeInsets.only(top: 29.h, bottom: 13.h),
              child: Text('마이페이지', style: CustomTextStyles.h1),
            ),

            // 닉네임 박스
            SizedBox(height: 16.h),
            _buildNicknameBox(),

            // 메뉴 섹션 1
            SizedBox(height: 16.h),
            _buildMenuSection([
              _MenuItem(
                label: '좋아요 목록',
                icon: AppIcons.profilelikecount,
                onTap: () {
                  context.navigateTo(screen: const MyLikeListScreen());
                },
              ),
              _MenuItem(
                label: '내 위치인증',
                icon: AppIcons.location,
                onTap: () {
                  context.navigateTo(screen: const MyLocationVerificationScreen());
                },
              ),
              _MenuItem(
                label: '선호 카테고리 설정',
                icon: AppIcons.preferCategory,
                onTap: () {
                  context.navigateTo(screen: const MyCategorySettingsScreen());
                },
              ),
              _MenuItem(
                label: '탐색 범위 설정',
                icon: AppIcons.target,
                onTap: () {
                  context.navigateTo(screen: const SearchRangeSettingScreen());
                },
              ),
              _MenuItem(
                label: '차단 관리',
                icon: AppIcons.slashCircle,
                onTap: () {
                  context.navigateTo(screen: const BlockManagementScreen());
                },
              ),
              _MenuItem(
                label: '알림 설정',
                icon: AppIcons.alert,
                onTap: () {
                  context.navigateTo(screen: const NotificationSettingsScreen());
                },
              ),
            ]),
            SizedBox(height: 16.h),

            // 이용약관 / 앱 버전 / 로그아웃 / 회원탈퇴 섹션
            _buildMenuSection([
              _MenuItem(
                label: '이용 약관',
                icon: AppIcons.infoCircle,
                onTap: () {
                  context.navigateTo(screen: const TermsScreen());
                },
              ),
              _MenuItem(
                label: '앱 버전 정보',
                icon: AppIcons.infoCircle,
                onTap: () {},
                trailingText: _appVersion.isNotEmpty ? 'v$_appVersion' : '',
              ),
              _MenuItem(label: '로그아웃', onTap: () => AuthService().logout(context), isDestructive: true),
              _MenuItem(label: '회원탈퇴', onTap: () => _handleDeleteMemberButtonTap(context), isDestructive: true),
            ]),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  /// 닉네임 박스 위젯
  Widget _buildNicknameBox() {
    return AppPressable(
      onTap: () async {
        final result = await context.navigateTo<bool>(screen: const MyProfileEditScreen());

        if (result == true) {
          await _loadUserInfo();
        }
      },
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 16, right: 18, top: 16, bottom: 16),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        child: Row(
          children: [
            // 프로필 이미지
            UserProfileCircularAvatar(
              avatarSize: const Size(50, 50),
              profileUrl: _profileUrl,
              hasBorder: true,
              isDeleteAccount: _accountStatus == AccountStatus.deleteAccount.serverName,
            ),
            SizedBox(width: 16.w),

            // 닉네임 및 장소
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_nickname, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(AppIcons.location, size: 13.sp, color: AppColors.opacity60White),
                      SizedBox(width: 3.w),
                      Text(
                        _location,
                        style: CustomTextStyles.p3.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.opacity60White,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 오른쪽 화살표 아이콘
            Icon(AppIcons.detailView, size: 18.sp, color: AppColors.opacity30White),
          ],
        ),
      ),
    );
  }

  /// 메뉴 섹션 위젯
  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Wrap(
        runSpacing: 0.w,
        children: items.map((item) {
          return _buildMenuItem(
            label: item.label,
            icon: item.icon,
            onTap: item.onTap,
            isDestructive: item.isDestructive,
            trailingText: item.trailingText,
          );
        }).toList(),
      ),
    );
  }

  /// 메뉴 아이템 위젯
  Widget _buildMenuItem({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    bool isDestructive = false,
    String? trailingText,
  }) {
    final bool hasTrailingText = trailingText != null && trailingText.isNotEmpty;

    return AppPressable(
      onTap: hasTrailingText ? null : onTap,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Container(
        height: 60.h,
        padding: EdgeInsets.only(left: 16.w, right: 18.w),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.only(right: 16.0.w),
                child: Icon(icon, size: 18.sp, color: AppColors.textColorWhite),
              ),
            Expanded(
              child: Text(
                label,
                style: CustomTextStyles.p2.copyWith(
                  color: isDestructive ? AppColors.warningRed : AppColors.textColorWhite,
                ),
              ),
            ),
            if (hasTrailingText)
              Text(trailingText, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White))
            else if (!isDestructive)
              Icon(AppIcons.detailView, size: 18.sp, color: AppColors.opacity30White),
          ],
        ),
      ),
    );
  }

  /// 회원 탈퇴 처리
  Future<void> _handleDeleteMemberButtonTap(BuildContext context) async {
    final result = await context.showDeleteDialog(title: '회원 탈퇴', description: '정말 탈퇴하시겠습니까?', confirmText: '탈퇴하기');

    if (result == true) {
      await _confirmDeleteMember(context);
    }
  }

  /// 회원 탈퇴 확인 후 처리
  Future<void> _confirmDeleteMember(BuildContext context) async {
    final isSuccess = await AuthService().deleteAccount();
    if (!context.mounted) return;
    if (isSuccess) {
      context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.pushAndRemoveUntil);
    } else {
      CommonSnackBar.show(context: context, message: '회원 탈퇴에 실패했습니다. 다시 시도해주세요.', type: SnackBarType.error);
    }
  }
}

/// 메뉴 아이템 데이터 클래스
class _MenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final String? trailingText;

  _MenuItem({required this.label, this.icon, required this.onTap, this.isDestructive = false, this.trailingText});
}
