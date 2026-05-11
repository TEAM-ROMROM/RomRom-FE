import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/my_page/profile_image_crop_screen.dart';
import 'package:romrom_fe/services/apis/image_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class ProfileOverviewSection extends StatefulWidget {
  final String nickname;
  final String imageUrl;
  final String location;
  final int receivedLikes;
  final String accountStatus;
  final bool isEditable;
  final VoidCallback? onShowSaveButton;
  final VoidCallback? onUploadFailed;
  final void Function(String imageUrl)? onImageUploaded;
  final void Function(String nickname)? onNicknameChanged;

  const ProfileOverviewSection({
    super.key,
    required this.nickname,
    required this.imageUrl,
    required this.location,
    required this.receivedLikes,
    required this.accountStatus,
    this.isEditable = true,
    this.onShowSaveButton,
    this.onUploadFailed,
    this.onImageUploaded,
    this.onNicknameChanged,
  });

  @override
  State<ProfileOverviewSection> createState() => _ProfileOverviewSectionState();
}

class _ProfileOverviewSectionState extends State<ProfileOverviewSection> {
  bool _hasImageBeenTouched = false;
  bool _isEditingNickname = false;
  String _nickname = '';
  String _imageUrl = '';
  XFile? imageFile;

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController nicknameController;
  late final FocusNode nicknameFocusNode;

  @override
  void initState() {
    super.initState();
    _nickname = widget.nickname;
    _imageUrl = widget.imageUrl;
    nicknameController = TextEditingController(text: _nickname);
    nicknameFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ProfileOverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nickname != widget.nickname && !_isEditingNickname) {
      _nickname = widget.nickname;
      nicknameController.text = _nickname;
    }
    if (oldWidget.imageUrl != widget.imageUrl && !_hasImageBeenTouched) {
      _imageUrl = widget.imageUrl;
    }
  }

  @override
  void dispose() {
    nicknameController.dispose();
    nicknameFocusNode.dispose();
    super.dispose();
  }

  /// 갤러리에서 이미지 선택 및 크롭 후 업로드
  Future<void> _onPickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        debugPrint('프로필 이미지 변경 취소');
        return;
      }

      if (!mounted) return;
      final XFile? croppedFile = await context.navigateTo<XFile>(screen: ProfileImageCropScreen(imageFile: picked));

      if (!mounted) return;
      if (croppedFile == null) {
        debugPrint('프로필 이미지 크롭 취소');
        return;
      }

      setState(() {
        _hasImageBeenTouched = true;
        imageFile = picked;
      });
      widget.onShowSaveButton?.call();

      try {
        final List<String> urls = await ImageApi().uploadImages([croppedFile]);
        if (mounted) {
          if (urls.isNotEmpty) {
            setState(() => _imageUrl = urls.first);
            widget.onImageUploaded?.call(urls.first);
            debugPrint('프로필 이미지 변경 성공: $_imageUrl');
          } else {
            widget.onUploadFailed?.call();
          }
        }
      } catch (e) {
        if (context.mounted) {
          CommonSnackBar.show(context: context, message: '이미지 업로드에 실패했습니다: $e', type: SnackBarType.error);
        }
        if (mounted) widget.onUploadFailed?.call();
      } finally {
        if (mounted) setState(() => _hasImageBeenTouched = false);
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지 선택에 실패했습니다: $e', type: SnackBarType.error);
      }
    }
  }

  /// 텍스트의 실제 렌더링된 너비를 계산하여 아이콘 위치 조정에 활용
  double _measureTextWidth(BuildContext context, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp.width;
  }

  /// 프로필 이미지 섹션
  Widget _buildProfileImageSection() {
    if (!widget.isEditable) {
      return UserProfileCircularAvatar(
        avatarSize: Size(70.w, 70.h),
        profileUrl: _imageUrl,
        hasBorder: true,
        isDeleteAccount: widget.accountStatus == AccountStatus.deleteAccount.serverName,
      );
    }
    return GestureDetector(
      onTap: _onPickImage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _hasImageBeenTouched
              ? Container(
                  width: 70.w,
                  height: 70.w,
                  padding: EdgeInsets.all(48.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textColorWhite, width: 1.w),
                  ),
                  child: const CommonLoadingIndicator(),
                )
              : UserProfileCircularAvatar(
                  avatarSize: Size(70.w, 70.h),
                  profileUrl: _imageUrl,
                  hasBorder: true,
                  isDeleteAccount: widget.accountStatus == AccountStatus.deleteAccount.serverName,
                ),
          Positioned(
            right: 0.w,
            bottom: 0.h,
            child: Container(
              width: 24.w,
              height: 24.w,
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

  /// 닉네임 섹션 (편집 모드에서는 TextField, 일반 모드에서는 텍스트 + 편집 아이콘)
  Widget _buildNicknameSection() {
    final TextStyle style = CustomTextStyles.h2;

    if (!widget.isEditable) {
      return Text(_nickname, style: style);
    }

    final double textW = _measureTextWidth(context, _nickname, style);
    final double gap = 8.w;
    final double iconW = 24.w;
    final double iconOffsetX = (textW + iconW) / 2 + gap;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: _isEditingNickname || nicknameFocusNode.hasFocus || _nickname.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 243.w, maxHeight: 44),
                      child: TextField(
                        controller: nicknameController,
                        focusNode: nicknameFocusNode,
                        style: style,
                        textAlign: TextAlign.start,
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
                          hintText: '롬롬유저1234',
                          hintStyle: style.copyWith(color: AppColors.opacity30White),
                          contentPadding: const EdgeInsets.all(8),
                          suffix: GestureDetector(
                            onTap: () {
                              nicknameController.clear();
                              setState(() => _nickname = '');
                              widget.onNicknameChanged?.call('');
                            },
                            child: Container(
                              width: 16.w,
                              height: 16.h,
                              decoration: const BoxDecoration(color: AppColors.secondaryBlack2, shape: BoxShape.circle),
                              child: Center(
                                child: Icon(AppIcons.cancel, size: 11.sp, color: AppColors.textColorWhite),
                              ),
                            ),
                          ),
                        ),
                        onTap: widget.onShowSaveButton,
                        onTapOutside: (_) => setState(() {
                          nicknameFocusNode.unfocus();
                          _isEditingNickname = false;
                        }),
                        onChanged: (value) {
                          setState(() => _nickname = value);
                          widget.onNicknameChanged?.call(value);
                        },
                      ),
                    ),
                    if (_nickname.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('닉네임을 입력해주세요', style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder)),
                      ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() => _isEditingNickname = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) FocusScope.of(context).requestFocus(nicknameFocusNode);
                    });
                  },
                  child: Text(
                    _nickname,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        if (!nicknameFocusNode.hasFocus && _nickname.isNotEmpty)
          Transform.translate(
            offset: Offset(iconOffsetX, 0.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _isEditingNickname = true);
                widget.onShowSaveButton?.call();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) FocusScope.of(context).requestFocus(nicknameFocusNode);
                });
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

  /// 프로필 정보 행 (위치, 좋아요 수 등) - 공통 스타일 적용
  Widget _buildProfileInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(AppIcons.location, size: 16.sp, color: AppColors.textColorWhite),
              SizedBox(width: 16.w),
              Text(label, style: CustomTextStyles.p2),
            ],
          ),
          Text(
            value,
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400, color: AppColors.opacity60White),
          ),
        ],
      ),
    );
  }

  /// 좋아요 수 행 - 아이콘과 숫자 함께 표시
  Widget _buildLikesRow(String label, int likeCount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(AppIcons.profilelikecount, size: 16.sp, color: AppColors.textColorWhite),
              SizedBox(width: 16.w),
              Text(label, style: CustomTextStyles.p2),
            ],
          ),
          Text(
            '$likeCount',
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        children: [
          Row(
            children: [
              _buildProfileImageSection(),
              SizedBox(width: 16.w),
              _buildNicknameSection(),
            ],
          ),
          SizedBox(height: 28.h),
          _buildProfileInfoRow('위치', widget.location),
          SizedBox(height: 16.h),
          _buildLikesRow('받은 좋아요', widget.receivedLikes),
        ],
      ),
    );
  }
}
