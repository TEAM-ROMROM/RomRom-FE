import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/my_page/my_like_list_screen.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
import 'package:romrom_fe/screens/profile/member_profile_screen.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/screens/my_page/my_category_settings_screen.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/screens/my_page/terms_screen.dart';
import 'package:romrom_fe/screens/my_page/block_management_screen.dart';
import 'package:romrom_fe/screens/search_range_setting_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class MyPageTabScreen extends ConsumerStatefulWidget {
  const MyPageTabScreen({super.key});

  @override
  ConsumerState<MyPageTabScreen> createState() => _MyPageTabScreenState();
}

class _MyPageTabScreenState extends ConsumerState<MyPageTabScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = packageInfo.version);
      }
    } catch (_) {}
  }

  /// 이메일 마스킹: "abc@gmail.com" → "ab***@gmail.com" (@앞 2자 유지, 나머지 ***)
  String? _maskEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email;
    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    if (local.length <= 2) return '$local***$domain';
    return '${local.substring(0, 2)}***$domain';
  }

  /// socialPlatform 서버값(KAKAO/APPLE/GOOGLE) → 한글 표시명
  String? _platformDisplayName(String? platform) {
    switch (platform?.toUpperCase()) {
      case 'KAKAO':
        return '카카오 로그인';
      case 'APPLE':
        return 'Apple 로그인';
      case 'GOOGLE':
        return '구글 로그인';
      case 'NAVER':
        return '네이버 로그인';
      default:
        return platform;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(memberProfileProvider);
    final profileState = profileAsync.valueOrNull;

    final memberId = profileState?.member?.memberId ?? '';
    final nickname = profileState?.member?.nickname ?? '닉네임';
    final profileUrl = profileState?.member?.profileUrl;
    final accountStatus = profileState?.member?.accountStatus;
    final loginEmail = _maskEmail(profileState?.member?.email);
    final socialPlatform = _platformDisplayName(profileState?.member?.socialPlatform);

    final location = profileState?.location;
    String locationText = '위치정보 없음';
    if (location != null) {
      final siGunGu = location.siGunGu ?? '';
      final eupMyoenDong = location.eupMyoenDong ?? '';
      final combined = '$siGunGu $eupMyoenDong'.trim();
      if (combined.isNotEmpty) locationText = combined;
    }

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
            _buildNicknameBox(
              memberId: memberId,
              nickname: nickname,
              profileUrl: profileUrl,
              accountStatus: accountStatus,
              location: locationText,
            ),

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
                onTap: () async {
                  final result = await context.navigateTo<bool>(screen: const MyLocationVerificationScreen());
                  if (result == true) {
                    ref.read(memberProfileProvider.notifier).reload();
                  }
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
              if (loginEmail != null) _MenuItem(label: '로그인 계정', onTap: () {}, trailingText: loginEmail),
              if (socialPlatform != null) _MenuItem(label: '연결 플랫폼', onTap: () {}, trailingText: socialPlatform),
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
  Widget _buildNicknameBox({
    required String memberId,
    required String nickname,
    required String? profileUrl,
    required String? accountStatus,
    required String location,
  }) {
    return AppPressable(
      onTap: () async {
        if (memberId.isEmpty) return;
        final result = await context.navigateTo<bool>(screen: MemberProfileScreen(memberId: memberId));

        if (result == true) {
          // 프로필 수정 후 provider 갱신 (member_profile_screen이 notifier.updateProfile로 이미 갱신하나
          // 화면이 pop true를 반환하는 다른 경로(예: 차단 변경)도 있으므로 명시적 reload)
          ref.read(memberProfileProvider.notifier).reload();
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
              profileUrl: profileUrl,
              hasBorder: true,
              isDeleteAccount: accountStatus == AccountStatus.deleteAccount.serverName,
            ),
            SizedBox(width: 16.w),

            // 닉네임 및 장소
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(nickname, style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(AppIcons.location, size: 13.sp, color: AppColors.opacity60White),
                      SizedBox(width: 3.w),
                      Text(
                        location,
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
