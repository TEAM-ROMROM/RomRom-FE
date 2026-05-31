import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

const String _kDefaultProfileAsset = 'assets/images/basicProfile.svg';

class UserProfileCircularAvatar extends StatefulWidget {
  final Size avatarSize;
  final String? profileUrl;
  final bool hasBorder;
  final bool isDeleteAccount;

  const UserProfileCircularAvatar({
    super.key,
    required this.avatarSize,
    this.profileUrl,
    this.hasBorder = false,
    required this.isDeleteAccount,
  });

  @override
  State<UserProfileCircularAvatar> createState() => _UserProfileCircularAvatarState();
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
      setState(() {
        _avatarUrl = _kDefaultProfileAsset;
        _isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.avatarSize.width;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.hasBorder
            ? Border.all(
                color: widget.isDeleteAccount
                    ? AppColors.profileBorderGray
                    : _avatarUrl == _kDefaultProfileAsset
                    ? AppColors.opacity60White
                    : AppColors.profileBorderWhite,
                width: 1.0,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
            : null,
      ),
      child: ClipOval(
        child: _isLoading
            ? const Center(child: CommonLoadingIndicator())
            : _avatarUrl != null && _avatarUrl!.isNotEmpty && _avatarUrl != _kDefaultProfileAsset
            ? CachedImage(imageUrl: _avatarUrl!, fit: BoxFit.cover, errorWidget: _buildDefaultImage())
            : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return SvgPicture.asset(_kDefaultProfileAsset, fit: BoxFit.cover);
  }
}
