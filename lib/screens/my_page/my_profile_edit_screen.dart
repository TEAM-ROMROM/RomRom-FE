import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/image_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
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
  String _accountStatus = '';

  bool _hasImageBeenTouched = false;
  bool _showProfileSaveButton = false;
  bool _isProfileEdited = false;

  // 이미지 관련 변수들
  final ImagePicker _picker = ImagePicker();
  XFile? imageFile; // 선택된 이미지 저장
  String imageUrl = ''; // 서버에 업로드된 이미지 URL 저장

  // nickname 수정 컨트롤러
  TextEditingController nicknameController = TextEditingController();
  FocusNode nicknameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    nicknameController.dispose();
    nicknameFocusNode.dispose();
    super.dispose();
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final memberApi = MemberApi();
      final memberResponse = await memberApi.getMemberInfo();

      if (mounted) {
        setState(() {
          _nickname = memberResponse.member?.nickname ?? '닉네임';
          _accountStatus = memberResponse.member?.accountStatus ?? '';
          nicknameController.text = _nickname;
          imageUrl = memberResponse.member?.profileUrl ?? '';

          final location = memberResponse.memberLocation;
          if (location != null) {
            final siGunGu = location.siGunGu ?? '';
            final eupMyoenDong = location.eupMyoenDong ?? '';
            final combinedLocation = '$siGunGu $eupMyoenDong'.trim();
            _location = combinedLocation.isNotEmpty ? combinedLocation : '위치정보 없음';
          }

          _receivedLikes = memberResponse.member?.totalLikeCount ?? 0;
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 실패: $e');
    }
  }

  // 상품사진 갤러리에서 가져오는 함수 (다중 선택 지원)
  Future<void> onPickImage() async {
    try {
      setState(() {
        _hasImageBeenTouched = true;
        _showProfileSaveButton = true;
      });

      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

      // 사용자가 취소했거나 선택 없음
      if (picked == null) {
        debugPrint('프로필 이미지 변경 취소');
        return;
      }

      setState(() {
        // 선택한 사진으로 사진 변경
        imageFile = picked;
      });

      try {
        // 여러 장 업로드 (API가 List<XFile> -> List<String> 반환한다고 가정)
        final List<String> urls = await ImageApi().uploadImages([picked]);

        if (mounted) {
          setState(() {
            // 서버 URL 추가 (개수 불일치 대비하여 안전하게 처리)
            if (urls.isNotEmpty) {
              imageUrl = urls.first;
              _isProfileEdited = true;
            } else {
              // 필요 시: 업로드 실패한 항목 처리 로직 추가 가능
            }
          });
          debugPrint('프로필 이미지 변경 성공: $imageUrl');
        }
      } catch (e) {
        if (context.mounted) {
          CommonSnackBar.show(context: context, message: '이미지 업로드에 실패했습니다: $e', type: SnackBarType.error);
        }
      } finally {
        if (mounted) {
          setState(() {
            _hasImageBeenTouched = false;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지 선택에 실패했습니다: $e', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '프로필',
        showBottomBorder: true,
        onBackPressed: () {
          if (_isProfileEdited) {
            CommonModal.confirm(
              context: context,
              message: '변경 사항이 저장되지 않았습니다.\n저장하지 않고 나가시겠습니까?',
              confirmText: '나가기',
              cancelText: '취소',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 화면 닫기
              },
            );

            return;
          }
          Navigator.pop(context);
        },
        actions: [
          if (_showProfileSaveButton)
            Padding(
              padding: EdgeInsets.only(right: 24.0.w),
              child: GestureDetector(
                onTap: () async {
                  if (_isProfileEdited && (_nickname.isNotEmpty)) {
                    await MemberApi()
                        .updateMemberProfile(nicknameController.text, imageUrl)
                        .then((_) {
                          if (context.mounted) {
                            CommonSnackBar.show(
                              context: context,
                              message: '프로필이 성공적으로 업데이트되었습니다.',
                              type: SnackBarType.success,
                            );
                            Navigator.of(context).pop(true);
                          }
                        })
                        .catchError((e) {
                          if (context.mounted) {
                            CommonSnackBar.show(
                              context: context,
                              message: '프로필 업데이트에 실패했습니다: $e',
                              type: SnackBarType.error,
                            );
                          }
                        });
                  }
                },
                child: Text(
                  '저장',
                  style: CustomTextStyles.h2.copyWith(
                    color: _isProfileEdited && (_nickname.isNotEmpty)
                        ? AppColors.primaryYellow
                        : AppColors.secondaryBlack2,
                  ),
                ),
              ),
            ),
        ],
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

              SizedBox(height: 50.h),

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
    return GestureDetector(
      onTap: () async {
        await onPickImage();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 프로필 이미지
          _hasImageBeenTouched && imageFile != null
              ? Container(
                  width: 132.w,
                  height: 132.w,
                  padding: EdgeInsets.all(48.w),
                  child: const CircularProgressIndicator(color: AppColors.primaryYellow),
                )
              : UserProfileCircularAvatar(
                  avatarSize: Size(132.w, 132.h),
                  profileUrl: imageUrl,
                  hasBorder: true,
                  isDeleteAccount: _accountStatus == AccountStatus.deleteAccount.serverName,
                ),

          // 카메라 아이콘 (우하단)
          Positioned(
            right: 8.w,
            bottom: 8.h,
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: const BoxDecoration(color: AppColors.secondaryBlack2, shape: BoxShape.circle),
              child: Center(
                child: Icon(AppIcons.camera, size: 16.sp, color: AppColors.textColorWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 텍스트 폭 측정 함수
  double _measureTextWidth(BuildContext context, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp.width;
  }

  /// 닉네임 + 편집 버튼
  Widget _buildNicknameSection() {
    // 포커스 아닐 때만 우측 아이콘 노출 중이니, 이 상태에서 텍스트 실측
    final String viewText = _nickname; // 포커스 없을 때 표시되는 텍스트
    final TextStyle style = CustomTextStyles.h2;
    final double textW = _measureTextWidth(context, viewText, style); // 실제 폭
    final double gap = 8.w; // 8px(스케일 반영)
    final double iconW = 24.w; // 아이콘 컨테이너 폭
    final double iconOffsetX = (textW + iconW) / 2 + gap; // “텍스트 중심”에서 오른쪽으로 이동할 양

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 중앙 텍스트 or 입력창
        SizedBox(
          height: 48.h,
          child: Align(
            alignment: const Alignment(0, -1.0),
            child: nicknameFocusNode.hasFocus || _nickname.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 244.w, maxHeight: 28.h),
                        child: TextField(
                          controller: nicknameController,
                          focusNode: nicknameFocusNode,
                          style: style,
                          textAlign: TextAlign.center,
                          cursorColor: AppColors.textColorWhite,
                          textAlignVertical: TextAlignVertical.bottom,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: _nickname.isEmpty
                                ? const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.errorBorder))
                                : InputBorder.none,
                            focusedBorder: _nickname.isEmpty
                                ? const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.errorBorder))
                                : const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryBlack2)),
                            isDense: true,
                            hintText: '닉네임을 입력하세요',
                            hintStyle: style.copyWith(color: AppColors.opacity30White),
                            contentPadding: const EdgeInsets.all(8),

                            suffix: GestureDetector(
                              onTap: () {
                                nicknameController.clear();
                                setState(() {
                                  _nickname = '';
                                  _isProfileEdited = true;
                                });
                              },
                              child: Container(
                                width: 16.w,
                                height: 16.h,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryBlack2,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(AppIcons.cancel, size: 11.sp, color: AppColors.textColorWhite),
                                ),
                              ),
                            ),
                          ),
                          onTap: () => setState(() => _showProfileSaveButton = true),
                          onTapOutside: (_) => setState(() => nicknameFocusNode.unfocus()),
                          onChanged: (_) => setState(() {
                            _nickname = nicknameController.text;
                            _isProfileEdited = true;
                          }),
                        ),
                      ),
                      if (_nickname.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text('닉네임을 입력해주세요', style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder)),
                        ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(nicknameFocusNode);
                    },
                    child: Text(
                      viewText,
                      style: style,
                      maxLines: 1, // 실측과 표시를 일치시키기 위해 한 줄 고정
                      overflow: TextOverflow.clip, // 필요 시 ellipsis로 교체 가능
                      softWrap: false,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),

        // 텍스트 "오른쪽 끝 + 8px" 위치에 버튼
        if (!nicknameFocusNode.hasFocus && _nickname.isNotEmpty)
          Transform.translate(
            offset: Offset(iconOffsetX, -14.0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(nicknameFocusNode);
              },
              child: Container(
                width: 24.w,
                height: 24.h,
                decoration: const BoxDecoration(color: AppColors.secondaryBlack2, shape: BoxShape.circle),
                child: Center(
                  child: Icon(AppIcons.edit, size: 16.sp, color: AppColors.textColorWhite),
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
                '$_receivedLikes',
                style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400, color: AppColors.opacity60White),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
