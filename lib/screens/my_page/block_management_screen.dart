import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 차단 관리 화면
class BlockManagementScreen extends StatefulWidget {
  const BlockManagementScreen({super.key});

  @override
  State<BlockManagementScreen> createState() => _BlockManagementScreenState();
}

class _BlockManagementScreenState extends State<BlockManagementScreen> {
  List<Member> _blockedMembers = [];
  bool _isLoading = true;

  /// 페이지 내에서 차단 해제된 멤버 ID 추적 (버튼 상태 토글용)
  final Set<String> _unblockedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedMembers();
  }

  /// 차단된 회원 목록 로드
  Future<void> _loadBlockedMembers() async {
    try {
      final memberApi = MemberApi();
      final response = await memberApi.getBlockedMembers();

      if (mounted) {
        setState(() {
          _blockedMembers = response.members ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('차단 회원 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.show(context: context, message: '차단 목록을 불러오는데 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  /// 차단 해제 처리 - SnackBar 없이 버튼 상태만 변경
  Future<void> _handleUnblock(String memberId) async {
    try {
      final success = await MemberApi().unblockMember(memberId);
      if (success && mounted) {
        setState(() => _unblockedMemberIds.add(memberId));
      }
    } catch (e) {
      debugPrint('차단 해제 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: '차단 해제에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  /// 다시 차단하기 처리
  Future<void> _handleBlock(String memberId) async {
    try {
      final success = await MemberApi().blockMember(memberId);
      if (success && mounted) {
        setState(() => _unblockedMemberIds.remove(memberId));
      }
    } catch (e) {
      debugPrint('차단 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: '차단에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '차단 관리', showBottomBorder: false, onBackPressed: () => Navigator.pop(context)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : _blockedMembers.isEmpty
          ? _buildEmptyState()
          : _buildBlockedMembersList(),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_outlined, size: 48.sp, color: AppColors.opacity60White),
          SizedBox(height: 16.h),
          Text('차단한 사용자가 없습니다', style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White)),
        ],
      ),
    );
  }

  /// 차단된 회원 목록 위젯
  Widget _buildBlockedMembersList() {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h), // Figma: 헤더에서 16px 아래
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: _blockedMembers.length,
        separatorBuilder: (_, __) => Column(
          children: [
            SizedBox(height: 16.h), // 아이템 사이 간격
            const Divider(color: AppColors.opacity10White, thickness: 1),
            SizedBox(height: 16.h), // Divider 아래도 간격까지 원하면 유지
          ],
        ),
        itemBuilder: (context, index) {
          final member = _blockedMembers[index];
          return _buildBlockedMemberItem(member);
        },
      ),
    );
  }

  /// 차단된 회원 아이템 위젯
  Widget _buildBlockedMemberItem(Member member) {
    return GestureDetector(
      onTap: () async {
        if (member.memberId != null) {
          final result = await context.navigateTo(screen: ProfileScreen(memberId: member.memberId!));

          // 프로필 화면에서 차단 상태 변경됐으면 동기화
          if (result != null && result is Map<String, dynamic> && mounted) {
            final memberId = result['memberId'] as String;
            final isBlocked = result['isBlocked'] as bool;

            setState(() {
              if (isBlocked) {
                _unblockedMemberIds.remove(memberId);
              } else {
                _unblockedMemberIds.add(memberId);
              }
            });
          }
        }
      },
      child: Container(
        color: AppColors.transparent,
        child: Row(
          children: [
            // 프로필 이미지 (50x50px)
            UserProfileCircularAvatar(
              avatarSize: Size(50.w, 50.h),
              profileUrl: member.profileUrl,
              hasBorder: true,
              isDeleteAccount: member.accountStatus == AccountStatus.deleteAccount.serverName,
            ),
            SizedBox(width: 16.w), // Figma: 이미지 오른쪽 16px
            // 닉네임 및 위치
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Figma: 16px Medium
                  Text(member.nickname ?? '닉네임', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.h), // Figma: 닉네임 아래 8px
                  // Figma: 12px Medium, opacity 60%
                  Text(
                    member.locationAddress ?? '위치 정보 없음',
                    style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White),
                  ),
                ],
              ),
            ),

            // 차단/차단 해제 버튼
            _buildBlockButton(member.memberId!),
          ],
        ),
      ),
    );
  }

  /// 차단/차단 해제 버튼 (상태에 따라 디자인 변경)
  Widget _buildBlockButton(String memberId) {
    final isUnblocked = _unblockedMemberIds.contains(memberId);

    return GestureDetector(
      onTap: () => isUnblocked ? _handleBlock(memberId) : _handleUnblock(memberId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          color: isUnblocked ? AppColors.primaryYellow : AppColors.secondaryBlack1,
        ),
        child: Text(
          isUnblocked ? '차단하기' : '차단 해제',
          style: CustomTextStyles.p2.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.32,
            color: isUnblocked ? AppColors.textColorBlack : AppColors.textColorWhite,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}
