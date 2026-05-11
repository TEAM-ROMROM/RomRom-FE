import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/profile/profile_exchange_section.dart';
import 'package:romrom_fe/widgets/profile/profile_overview_section.dart';
import 'package:romrom_fe/widgets/profile/profile_review_section.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

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
  String _imageUrl = '';

  bool _showProfileSaveButton = false;
  bool _isProfileEdited = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final memberApi = MemberApi();
      final memberResponse = await memberApi.getMemberInfo();

      if (mounted) {
        setState(() {
          _nickname = memberResponse.member?.nickname ?? '닉네임';
          _accountStatus = memberResponse.member?.accountStatus ?? '';
          _imageUrl = memberResponse.member?.profileUrl ?? '';

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
                Navigator.pop(context);
                Navigator.pop(context);
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
                  if (_isSaving) return;
                  if (_isProfileEdited && _nickname.isNotEmpty) {
                    setState(() => _isSaving = true);
                    try {
                      await MemberApi().updateMemberProfile(_nickname, _imageUrl);
                      if (context.mounted) {
                        CommonSnackBar.show(
                          context: context,
                          message: '프로필이 성공적으로 업데이트되었습니다.',
                          type: SnackBarType.success,
                        );
                        Navigator.of(context).pop(true);
                      }
                    } on UgcViolationException catch (e) {
                      if (context.mounted) {
                        final ugcMessage = e.violatingText.isNotEmpty
                            ? '\'${e.violatingText}\'이(가) 포함된\n부적절한 표현입니다.\n수정 후 다시 시도해주세요.'
                            : '부적절한 표현이 포함되어 있습니다.\n수정 후 다시 시도해주세요.';
                        CommonModal.error(
                          context: context,
                          message: ugcMessage,
                          onConfirm: () => Navigator.of(context).pop(),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CommonSnackBar.show(
                          context: context,
                          message: ErrorUtils.getErrorMessage(e),
                          type: SnackBarType.error,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  }
                },
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
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Wrap(
            runSpacing: 16.h,
            children: [
              ProfileOverviewSection(
                nickname: _nickname,
                imageUrl: _imageUrl,
                location: _location,
                receivedLikes: _receivedLikes,
                accountStatus: _accountStatus,
                onShowSaveButton: () => setState(() => _showProfileSaveButton = true),
                onUploadFailed: () {
                  if (!_isProfileEdited) setState(() => _showProfileSaveButton = false);
                },
                onImageUploaded: (url) => setState(() {
                  _imageUrl = url;
                  _isProfileEdited = true;
                }),
                onNicknameChanged: (nickname) => setState(() {
                  _nickname = nickname;
                  _isProfileEdited = true;
                  _showProfileSaveButton = true;
                }),
              ),
              const ProfileExchangeSection(),
              const ProfileReviewSection(),
            ],
          ),
        ),
      ),
    );
  }
}
