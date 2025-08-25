import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/user_info.dart';

class UserProfileCircularAvatar extends StatefulWidget {
  final Size avatarSize;
  final String? profileUrl;

  const UserProfileCircularAvatar({
    super.key,
    required this.avatarSize,
    this.profileUrl,
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
    if (widget.profileUrl != null && widget.profileUrl!.isNotEmpty) {
      _avatarUrl = widget.profileUrl;
      _isLoading = false;
    } else {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo(); // 사용자 정보 로딩
      setState(() {
        _avatarUrl = userInfo.profileUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _avatarUrl = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.avatarSize.width.w;
    final double height = widget.avatarSize.height.h;

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? Image.network(
                    _avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultImage();
                    },
                  )
                : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 40, // 아이콘 크기 조정
        color: Colors.grey[700], // 아이콘 색상
      ),
    );
  }
}
