import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

const String _kDefaultProfileAsset = 'assets/images/basicProfile.svg';

class UserProfileCircularAvatar extends StatefulWidget {
  final Size avatarSize;
  final String? profileUrl;
  final bool hasBorder;

  const UserProfileCircularAvatar({
    super.key,
    required this.avatarSize,
    this.profileUrl,
    this.hasBorder = false,
  });

  @override
  State<UserProfileCircularAvatar> createState() =>
      _UserProfileCircularAvatarState();
}

class _UserProfileCircularAvatarState extends State<UserProfileCircularAvatar> {
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(UserProfileCircularAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // widget.profileUrl이 변경되면 다시 로드
    if (oldWidget.profileUrl != widget.profileUrl) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    if (widget.profileUrl != null && widget.profileUrl!.isNotEmpty) {
      setState(() {
        _avatarUrl = widget.profileUrl;
        _isLoading = false;
      });
    } else {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo(); // 사용자 정보 로딩
      setState(() {
        _avatarUrl = userInfo.profileUrl ?? _kDefaultProfileAsset;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _avatarUrl = _kDefaultProfileAsset;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.avatarSize.width.w;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textColorWhite,
        border: widget.hasBorder
            ? Border.all(
                color: AppColors.textColorWhite, // 테두리 색상
                width: 1.0, // 테두리 두께
              )
            : null,
      ),
      child: ClipOval(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _avatarUrl != null &&
                  _avatarUrl!.isNotEmpty &&
                  _avatarUrl != _kDefaultProfileAsset
            ? CachedImage(
                imageUrl: _avatarUrl!,
                fit: BoxFit.contain,
                errorWidget: _buildDefaultImage(),
              )
            : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return SvgPicture.asset(
      _kDefaultProfileAsset,
      fit: BoxFit.cover,
    );
  }
}
