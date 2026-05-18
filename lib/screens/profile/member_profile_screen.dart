import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/member_report_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/skeletons/profile_screen_skeleton.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/profile/profile_exchange_section.dart';
import 'package:romrom_fe/widgets/profile/profile_overview_section.dart';
import 'package:romrom_fe/widgets/profile/profile_review_section.dart';

/// 멤버 프로필 조회 화면
/// 내 프로필이면 "프로필 수정" 버튼 표시, 타인 프로필이면 읽기 전용
class MemberProfileScreen extends StatefulWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMyProfile = false;
  bool _isBlockedUser = false;
  bool _blockStatusChanged = false;
  bool _deleteModalShown = false;

  // 내 프로필 인라인 편집 상태
  bool _showSaveButton = false;
  bool _isProfileEdited = false;
  bool _isSaving = false;

  // 섹션 로딩 조율
  bool _exchangeLoaded = false;
  bool _reviewLoaded = false;
  bool get _showContent => !_isLoading && _exchangeLoaded && _reviewLoaded;

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
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
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

  /// 내 프로필 저장
  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_isProfileEdited || _nickname.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await MemberApi().updateMemberProfile(_nickname, _profileUrl);
      if (mounted) {
        CommonSnackBar.show(context: context, message: '프로필이 업데이트되었습니다.', type: SnackBarType.success);
        setState(() {
          _showSaveButton = false;
          _isProfileEdited = false;
        });
      }
    } on UgcViolationException catch (e) {
      if (mounted) {
        final ugcMessage = e.violatingText.isNotEmpty
            ? '\'${e.violatingText}\'이(가) 포함된\n부적절한 표현입니다.\n수정 후 다시 시도해주세요.'
            : '부적절한 표현이 포함되어 있습니다.\n수정 후 다시 시도해주세요.';
        CommonModal.error(context: context, message: ugcMessage, onConfirm: () => Navigator.of(context).pop());
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  /// 뒤로가기 처리 - 미저장 변경 확인 후 차단 상태 변경 시 결과 반환
  void _handleBackPressed() {
    if (_isMyProfile && _isProfileEdited) {
      CommonModal.confirm(
        context: context,
        message: '변경 사항이 저장되지 않았습니다.\n저장하지 않고 나가시겠습니까?',
        confirmText: '나가기',
        cancelText: '취소',
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
      return;
    }
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
      return const Scaffold(backgroundColor: AppColors.primaryBlack, body: ProfileScreenSkeleton());
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
          actions: _isMyProfile
              ? (_showSaveButton
                    ? [
                        Padding(
                          padding: EdgeInsets.only(right: 24.0.w),
                          child: GestureDetector(
                            onTap: _handleSave,
                            child: Text(
                              '저장',
                              style: CustomTextStyles.h2.copyWith(
                                color: _isProfileEdited && _nickname.isNotEmpty
                                    ? AppColors.primaryYellow
                                    : AppColors.secondaryBlack2,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : null)
              : [_buildProfileMenu()],
          onBackPressed: () => _handleBackPressed(),
        ),
        body: Stack(
          children: [
            Offstage(offstage: !_showContent, child: _buildProfileContent()),
            if (!_showContent) const ProfileScreenSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Wrap(
          runSpacing: 16.h,
          children: [
            ProfileOverviewSection(
              isEditable: _isMyProfile,
              nickname: _nickname,
              imageUrl: _profileUrl,
              location: _location,
              receivedLikes: _totalLikeCount,
              accountStatus: _accountStatus,
              onShowSaveButton: _isMyProfile ? () => setState(() => _showSaveButton = true) : null,
              onUploadFailed: _isMyProfile
                  ? () {
                      if (!_isProfileEdited) setState(() => _showSaveButton = false);
                    }
                  : null,
              onImageUploaded: _isMyProfile
                  ? (url) => setState(() {
                      _profileUrl = url;
                      _isProfileEdited = true;
                    })
                  : null,
              onNicknameChanged: _isMyProfile
                  ? (nickname) => setState(() {
                      _nickname = nickname;
                      _isProfileEdited = true;
                      _showSaveButton = true;
                    })
                  : null,
            ),
            if (!_isMyProfile && _isBlockedUser)
              Center(
                child: Text('차단됨', style: CustomTextStyles.p2.copyWith(color: AppColors.isBlockedStatusText)),
              ),
            ProfileExchangeSection(
              memberId: _isMyProfile ? null : widget.memberId,
              onLoaded: () => setState(() => _exchangeLoaded = true),
            ),
            ProfileReviewSection(
              memberId: _isMyProfile ? null : widget.memberId,
              onLoaded: () => setState(() => _reviewLoaded = true),
            ),
          ],
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
