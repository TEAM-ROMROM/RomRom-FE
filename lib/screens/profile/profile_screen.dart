import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/member_report_screen.dart';
import 'package:romrom_fe/screens/my_page/my_profile_edit_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 프로필 조회 화면
/// 내 프로필이면 "프로필 수정" 버튼 표시, 타인 프로필이면 읽기 전용
class ProfileScreen extends StatefulWidget {
  final String memberId;

  const ProfileScreen({super.key, required this.memberId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMyProfile = false;
  bool _isBlockedUser = false;
  bool _blockStatusChanged = false;
  bool _deleteModalShown = false;

  String _accountStatus = '';
  String _nickname = '';
  String _profileUrl = '';
  String _location = '위치정보 없음';
  int _totalLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // 내 프로필인지 확인
      _isMyProfile = await UserInfo().isSameMember(widget.memberId);

      if (_isMyProfile) {
        // 내 프로필이면 API로 최신 정보 조회
        await _loadMyProfileFromApi();
      } else {
        // 타인 프로필이면 API로 정보 조회
        await _loadOtherProfileFromApi();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      CommonModal.showOnceAfterFrame(
        context: context,
        isShown: () => _deleteModalShown,
        markShown: () => _deleteModalShown = true,
        shouldShow: () => _accountStatus == AccountStatus.deleteAccount.serverName,
        message: '존재하지 않거나 탈퇴한 사용자입니다.',
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        CommonSnackBar.show(context: context, message: '프로필을 불러오는데 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  Future<void> _loadMyProfileFromApi() async {
    final memberApi = MemberApi();
    final memberResponse = await memberApi.getMemberInfo();

    if (mounted) {
      setState(() {
        _accountStatus = memberResponse.member?.accountStatus ?? '';
        _nickname = memberResponse.member?.nickname ?? '닉네임';
        _profileUrl = memberResponse.member?.profileUrl ?? '';
        _totalLikeCount = memberResponse.member?.totalLikeCount ?? 0;

        final location = memberResponse.memberLocation;
        if (location != null) {
          final siGunGu = location.siGunGu ?? '';
          final eupMyoenDong = location.eupMyoenDong ?? '';
          final combinedLocation = '$siGunGu $eupMyoenDong'.trim();
          _location = combinedLocation.isNotEmpty ? combinedLocation : '위치정보 없음';
        }
      });
    }
  }

  /// 타인 프로필 API 조회
  Future<void> _loadOtherProfileFromApi() async {
    final memberApi = MemberApi();
    final memberResponse = await memberApi.getMemberProfile(widget.memberId);

    if (mounted) {
      setState(() {
        _accountStatus = memberResponse.member?.accountStatus ?? '';
        _nickname = memberResponse.member?.nickname ?? '닉네임';
        _profileUrl = memberResponse.member?.profileUrl ?? '';
        _totalLikeCount = memberResponse.member?.totalLikeCount ?? 0;
        _isBlockedUser = memberResponse.member?.isBlocked ?? false;

        // 백엔드에서 locationAddress 필드로 직접 반환
        _location = memberResponse.member?.locationAddress ?? '위치정보 없음';
      });
    }
  }

  Future<void> _navigateToEditScreen() async {
    final result = await context.navigateTo(screen: const MyProfileEditScreen());

    // 수정 후 돌아왔을 때 정보 새로고침
    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadProfileData();
    }
  }

  /// 차단/차단해제 토글 처리
  Future<void> _handleBlockToggle() async {
    final memberApi = MemberApi();
    bool success;

    if (_isBlockedUser) {
      success = await memberApi.unblockMember(widget.memberId);
      if (success && mounted) {
        CommonSnackBar.show(context: context, message: '차단이 해제되었습니다', type: SnackBarType.success);
      }
    } else {
      success = await memberApi.blockMember(widget.memberId);
      if (success && mounted) {
        CommonSnackBar.show(context: context, message: '사용자를 차단했습니다', type: SnackBarType.success);
      }
    }

    if (success && mounted) {
      setState(() => _isBlockedUser = !_isBlockedUser);
      _blockStatusChanged = true;
    }
  }

  /// 뒤로가기 처리 - 차단 상태 변경 시 결과 반환
  void _handleBackPressed() {
    if (_blockStatusChanged) {
      Navigator.pop(context, {'memberId': widget.memberId, 'isBlocked': _isBlockedUser});
    } else {
      Navigator.pop(context);
    }
  }

  /// 신고하기 처리
  Future<void> _handleReport() async {
    final bool? reported = await context.navigateTo(screen: MemberReportScreen(memberId: widget.memberId));

    if (reported == true && mounted) {
      await CommonModal.success(
        context: context,
        message: '신고가 접수되었습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: CommonAppBar(title: '프로필', showBottomBorder: true, onBackPressed: () => _handleBackPressed()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.opacity60White),
              SizedBox(height: 16.h),
              Text('프로필을 불러올 수 없습니다', style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White)),
            ],
          ),
        ),
      );
    }

    if (_accountStatus == AccountStatus.deleteAccount.serverName) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: CommonAppBar(title: '프로필', showBottomBorder: true, onBackPressed: () => _handleBackPressed()),
        body: const SizedBox.shrink(),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: CommonAppBar(
          title: '프로필',
          showBottomBorder: true,
          actions: _isMyProfile ? null : [_buildProfileMenu()],
          onBackPressed: () => _handleBackPressed(),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 56.h),

                // 프로필 이미지
                _buildProfileImageSection(),

                SizedBox(height: 24.h),

                // 닉네임
                _buildNicknameSection(),

                SizedBox(height: 50.h),

                // 위치 섹션
                _buildInfoSection(label: '위치', value: _location),

                SizedBox(height: 16.h),

                // 받은 좋아요 수 섹션
                _buildLikesSection(),

                // 내 프로필인 경우 수정 버튼
                if (_isMyProfile) ...[SizedBox(height: 40.h), _buildEditButton()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 프로필 이미지 섹션
  Widget _buildProfileImageSection() {
    return UserProfileCircularAvatar(
      avatarSize: Size(132.w, 132.h),
      profileUrl: _profileUrl.isNotEmpty ? _profileUrl : null,
      hasBorder: true,
      isDeleteAccount: _accountStatus == AccountStatus.deleteAccount.serverName,
    );
  }

  /// 닉네임 섹션
  Widget _buildNicknameSection() {
    return Text(_nickname, style: CustomTextStyles.h2, textAlign: TextAlign.center);
  }

  /// 정보 섹션 (위치)
  Widget _buildInfoSection({required String label, required String value}) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400)),
          Text(
            value,
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White),
          ),
        ],
      ),
    );
  }

  /// 받은 좋아요 수 섹션
  Widget _buildLikesSection() {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('받은 좋아요 수', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400)),
          Row(
            children: [
              Icon(AppIcons.profilelikecount, size: 16.sp, color: AppColors.opacity60White),
              SizedBox(width: 4.w),
              Text(
                '$_totalLikeCount',
                style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400, color: AppColors.opacity60White),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 프로필 수정 버튼 (내 프로필인 경우만)
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _navigateToEditScreen,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(10.r)),
        alignment: Alignment.center,
        child: Text(
          '프로필 수정',
          style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack),
        ),
      ),
    );
  }

  /// 프로필 메뉴 (타인 프로필인 경우 - 신고/차단)
  Widget _buildProfileMenu() {
    return Padding(
      padding: EdgeInsets.only(right: 16.w, bottom: 8.h),
      child: RomRomContextMenu(
        items: [
          ContextMenuItem(
            id: 'report',
            title: '신고하기',
            icon: AppIcons.report,
            iconColor: AppColors.opacity60White,
            onTap: _handleReport,
            showDividerAfter: true,
          ),
          ContextMenuItem(
            id: 'block',
            title: _isBlockedUser ? '차단 해제하기' : '차단하기',
            icon: AppIcons.slashCircle,
            iconColor: _isBlockedUser ? AppColors.opacity60White : AppColors.warningRed,
            textColor: _isBlockedUser ? AppColors.textColorWhite : AppColors.warningRed,
            onTap: _handleBlockToggle,
          ),
        ],
      ),
    );
  }
}
