import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/social_logout_service.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/screens/my_page/my_category_settings_screen.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/screens/my_page/my_profile_edit_screen.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPageTabScreen extends StatefulWidget {
  const MyPageTabScreen({super.key});

  @override
  State<MyPageTabScreen> createState() => _MyPageTabScreenState();
}

class _MyPageTabScreenState extends State<MyPageTabScreen> {
  String _nickname = '닉네임';
  String _location = '위치정보 없음';
  String? _profileUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: "마이페이지"
            SizedBox(height: 16.h),
            Text('마이페이지', style: CustomTextStyles.h1),
            SizedBox(height: 37.h),

            // 닉네임 박스
            _buildNicknameBox(),
            SizedBox(height: 16.h),

            // 메뉴 섹션 1
            _buildMenuSection([
              _MenuItem(
                label: '좋아요 목록',
                onTap: () {
                  // TODO: 좋아요 목록 화면으로 이동
                },
              ),
              _MenuItem(
                label: '내 위치인증',
                onTap: () {
                  context.navigateTo(
                    screen: const MyLocationVerificationScreen(),
                  );
                },
              ),
              _MenuItem(
                label: '선호 카테고리 설정',
                onTap: () {
                  context.navigateTo(
                    screen: const MyCategorySettingsScreen(),
                  );
                },
              ),
              _MenuItem(
                label: '탐색 범위 설정',
                onTap: () {
                  // TODO: 탐색 범위 설정 화면으로 이동
                },
              ),
              _MenuItem(
                label: '차단 관리',
                onTap: () {
                  // TODO: 차단 관리 화면으로 이동
                },
              ),
            ]),
            SizedBox(height: 16.h),

            // 메뉴 섹션 2
            _buildMenuSection([
              _MenuItem(
                label: '이용 약관',
                onTap: () {
                  // TODO: 이용 약관 화면으로 이동
                },
              ),
            ]),
            SizedBox(height: 16.h),

            // 로그아웃/회원탈퇴 섹션
            _buildMenuSection(
              [
                _MenuItem(
                  label: '로그아웃',
                  onTap: () => AuthService().logout(context),
                  isDestructive: true,
                ),
                _MenuItem(
                  label: '회원탈퇴',
                  onTap: () => _handleDeleteMemberButtonTap(context),
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 닉네임 박스 위젯
  Widget _buildNicknameBox() {
    return GestureDetector(
      onTap: () {
        context.navigateTo(
          screen: const MyProfileEditScreen(),
        );
      },
      child: Container(
        width: double.infinity,
        height: 82.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            // 프로필 이미지
            _buildProfileImage(),
            SizedBox(width: 12.w),

            // 닉네임 및 장소
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_nickname, style: CustomTextStyles.h3),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12.sp,
                        color: AppColors.opacity60White,
                      ),
                      SizedBox(width: 2.w),
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
            Icon(
              Icons.chevron_right,
              size: 30.sp,
              color: AppColors.textColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 이미지 위젯
  Widget _buildProfileImage() {
    if (_profileUrl != null && _profileUrl!.isNotEmpty) {
      // 네트워크 이미지 (API에서 받은 프로필 이미지)
      return ClipOval(
        child: Image.network(
          _profileUrl!,
          width: 50.w,
          height: 50.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 이미지 로드 실패 시 기본 아이콘 표시
            return _buildDefaultProfileIcon();
          },
        ),
      );
    } else {
      // 기본 프로필 아이콘 (SVG)
      return _buildDefaultProfileIcon();
    }
  }

  /// 기본 프로필 아이콘 (SVG)
  Widget _buildDefaultProfileIcon() {
    return ClipOval(
      child: SvgPicture.asset(
        'assets/images/basicProfile.svg',
        width: 50.w,
        height: 50.h,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 메뉴 섹션 위젯
  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            return Column(
              children: [
                _buildMenuItem(
                  label: item.label,
                  onTap: item.onTap,
                  isDestructive: item.isDestructive,
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: AppColors.opacity10White,
                    indent: 24.w,
                    endIndent: 24.w,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 메뉴 아이템 위젯
  Widget _buildMenuItem({
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 54.h,
        padding: EdgeInsets.only(left: 24.w, right: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w400,
                  color: isDestructive
                      ? AppColors.warningRed
                      : AppColors.textColorWhite,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 30.sp,
              color: isDestructive
                  ? AppColors.warningRed
                  : AppColors.textColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  /// 회원 탈퇴 처리
  void _handleDeleteMemberButtonTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primaryBlack,
        title: Text('회원 탈퇴', style: CustomTextStyles.h3),
        content: Text(
          '정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: CustomTextStyles.p2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: CustomTextStyles.p2),
          ),
          TextButton(
            onPressed: () => _confirmDeleteMember(dialogContext, context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warningRed,
            ),
            child: Text(
              '탈퇴하기',
              style: CustomTextStyles.p2.copyWith(
                color: AppColors.warningRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 회원 탈퇴 확인 후 처리
  Future<void> _confirmDeleteMember(
      BuildContext dialogContext, BuildContext context) async {
    Navigator.pop(dialogContext); // 다이얼로그 닫기

    // 회원 탈퇴 진행
    final memberApi = MemberApi();
    final isSuccess = await memberApi.deleteMember();

    // context가 여전히 유효한지 확인
    if (!context.mounted) return;

    if (isSuccess) {
      // 토큰 삭제 후 로그인 화면으로 이동
      final tokenManager = TokenManager();
      await tokenManager.deleteTokens();

      // 소셜 플랫폼별 로그아웃 처리
      final socialLogoutService = SocialLogoutService();
      await socialLogoutService.performSocialLogout();

      // 메인 화면 블러 처리 변수 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isFirstMainScreen');

      // context가 여전히 유효한지 다시 확인
      if (!context.mounted) return;

      // 로그인 페이지로 이동
      context.navigateTo(
          screen: const LoginScreen(),
          type: NavigationTypes.pushAndRemoveUntil);
    } else {
      // 실패 안내
      CommonSnackBar.show(
        context: context,
        message: '회원 탈퇴에 실패했습니다. 다시 시도해주세요.',
        type: SnackBarType.error,
      );
    }
  }
}

/// 메뉴 아이템 데이터 클래스
class _MenuItem {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
