import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class MyProfileEditScreen extends StatefulWidget {
  const MyProfileEditScreen({super.key});

  @override
  State<MyProfileEditScreen> createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  String _nickname = '닉네임';
  String _location = '위치정보 없음';
  int _receivedLikes = 0;

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
          _nickname = memberResponse.member?.nickname ?? '닉네임';

          final location = memberResponse.memberLocation;
          if (location != null) {
            final siGunGu = location.siGunGu ?? '';
            final eupMyoenDong = location.eupMyoenDong ?? '';
            final combinedLocation = '$siGunGu $eupMyoenDong'.trim();
            _location = combinedLocation.isNotEmpty
                ? combinedLocation
                : '위치정보 없음';
          }

          // TODO: API에서 받은 좋아요 수 로드
          // _receivedLikes = memberResponse.receivedLikes ?? 0;
          _receivedLikes = 56; // 임시 데이터
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '프로필',
        showBottomBorder: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 56.h),

              // 프로필 이미지 + 카메라 아이콘
              _buildProfileImageSection(),

              SizedBox(height: 22.h),

              // 닉네임 + 편집 버튼
              _buildNicknameSection(),

              SizedBox(height: 72.h),

              // 내 위치 섹션
              _buildInfoSection(label: '내 위치', value: _location),

              SizedBox(height: 16.h),

              // 받은 좋아요 수 섹션
              _buildLikesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 프로필 이미지 + 카메라 아이콘
  Widget _buildProfileImageSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 프로필 이미지
        const UserProfileCircularAvatar(avatarSize: Size(132, 132)),

        // 카메라 아이콘 (우하단)
        Positioned(
          right: 8.w,
          bottom: 8.h,
          child: GestureDetector(
            onTap: () {
              // TODO: 프로필 이미지 변경 기능
              debugPrint('프로필 이미지 변경');
            },
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: const BoxDecoration(
                color: AppColors.secondaryBlack2,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  AppIcons.camera,
                  size: 16.sp,
                  color: AppColors.textColorWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 닉네임 + 편집 버튼
  Widget _buildNicknameSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _nickname,
          style: CustomTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () {
            // TODO: 닉네임 수정 기능
            debugPrint('닉네임 수정');
          },
          child: Container(
            width: 24.w,
            height: 24.h,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBlack2,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                AppIcons.edit,
                size: 16.sp,
                color: AppColors.textColorWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 정보 섹션 (내 위치)
  Widget _buildInfoSection({required String label, required String value}) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400),
          ),
          Text(
            value,
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.opacity60White,
            ),
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
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '받은 좋아요 수',
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400),
          ),
          Row(
            children: [
              Icon(
                AppIcons.profilelikecount,
                size: 16.sp,
                color: AppColors.opacity60White,
              ),
              SizedBox(width: 4.w),
              Text(
                '$_receivedLikes',
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.opacity60White,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
