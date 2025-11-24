import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

class MyProfileEditScreen extends StatefulWidget {
  const MyProfileEditScreen({super.key});

  @override
  State<MyProfileEditScreen> createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  String _nickname = '닉네임';
  String _location = '위치정보 없음';
  String? _profileUrl;
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
          _profileUrl = memberResponse.member?.profileUrl;

          final location = memberResponse.memberLocation;
          if (location != null) {
            final siGunGu = location.siGunGu ?? '';
            final eupMyoenDong = location.eupMyoenDong ?? '';
            final combinedLocation = '$siGunGu $eupMyoenDong'.trim();
            _location =
                combinedLocation.isNotEmpty ? combinedLocation : '위치정보 없음';
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

              SizedBox(height: 24.h),

              // 닉네임 + 편집 버튼
              _buildNicknameSection(),

              SizedBox(height: 72.h),

              // 내 위치 섹션
              _buildInfoSection(
                label: '내 위치',
                value: _location,
              ),

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
        Container(
          width: 132.w,
          height: 132.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textColorWhite,
              width: 1,
            ),
          ),
          child: ClipOval(
            child: _profileUrl != null && _profileUrl!.isNotEmpty
                ? Image.network(
                    _profileUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileImage();
                    },
                  )
                : _buildDefaultProfileImage(),
          ),
        ),

        // 카메라 아이콘 (우하단)
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              // TODO: 프로필 이미지 변경 기능
              debugPrint('프로필 이미지 변경');
            },
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/camera.svg',
                  width: 16.w,
                  height: 16.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.textColorWhite,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 기본 프로필 이미지
  Widget _buildDefaultProfileImage() {
    return SvgPicture.asset(
      'assets/images/basicProfile.svg',
      fit: BoxFit.cover,
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
            decoration: BoxDecoration(
              color: AppColors.secondaryBlack1,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/editPen.svg',
                width: 16.w,
                height: 16.h,
                colorFilter: ColorFilter.mode(
                  AppColors.textColorWhite,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 정보 섹션 (내 위치)
  Widget _buildInfoSection({
    required String label,
    required String value,
  }) {
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
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.opacity60White,
            ),
            textAlign: TextAlign.right,
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
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '받은 좋아요 수',
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/like-heart-icon.svg',
                width: 16.w,
                height: 16.h,
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
