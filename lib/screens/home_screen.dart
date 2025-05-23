import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/social_logout_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';
import 'package:romrom_fe/widgets/item_card.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // 상태 클래스 추가
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 선택된 탭 인덱스 관리

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈', style: CustomTextStyles.h3),
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 85.w,
                  child: const ItemCard(
                    itemCategoryLabel: '스포츠/레저',
                    itemName: '윌슨 블레이드 V9',
                    itemId: 'demoCard1',
                  ),
                ),
                _buildActionButton(
                  onPressed: () => _handleLogoutBtnTap(context),
                  backgroundColor: Colors.pink[300],
                  text: '로그아웃',
                ),
                SizedBox(height: 20.h),
                _buildActionButton(
                  onPressed: () => _handleDeleteMemberBtnTap(context),
                  backgroundColor: Colors.red[400],
                  text: '회원탈퇴',
                ),
              ],
            ),
          ),
        ],
      ),
      // 바텀 네비게이션 바 추가
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // 여기에 각 탭에 대한 처리를 추가할 수 있습니다
          // 지금은 상태만 업데이트하고 나중에 화면 전환 로직을 구현할 수 있습니다
        },
      ),
    );
  }

  /// 액션 버튼 위젯 생성
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color? backgroundColor,
    required String text,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
      ),
      child: Text(text,
          style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
    );
  }

  /// 로그아웃 처리
  void _handleLogoutBtnTap(BuildContext context) async {
    try {
      // 로그아웃 API 호출 시도
      final authApi = RomAuthApi();
      await authApi.logoutWithSocial(context);
    } catch (e) {
      debugPrint('로그아웃 중 오류 발생: $e');
    } finally {
      // API 성공/실패 여부와 관계없이 로그인 화면으로 이동
      if (context.mounted) {
        context.navigateTo(
            screen: const LoginScreen(),
            type: NavigationTypes.pushAndRemoveUntil);
      }
    }
  }

  /// 회원 탈퇴 처리
  void _handleDeleteMemberBtnTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primaryBlack,
        title: Text('회원 탈퇴', style: CustomTextStyles.h3),
        content: Text(
          '정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: CustomTextStyles.p2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: CustomTextStyles.p2),
          ),
          TextButton(
            onPressed: () => _confirmDeleteMember(dialogContext, context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('탈퇴하기', style: CustomTextStyles.p2),
          ),
        ],
      ),
    );
  }

  /// 회원 탈퇴 확인 후 처리
  Future<void> _confirmDeleteMember(
      BuildContext dialogContext, BuildContext context) async {
    Navigator.pop(dialogContext); // 다이얼로그 닫기

    // 회원 탈퇴 진행
    final memberApi = MemberApi();
    final isSuccess = await memberApi.deleteMember();

    // context가 여전히 유효한지 확인
    if (!context.mounted) return;

    if (isSuccess) {
      // 토큰 삭제 후 로그인 화면으로 이동
      final tokenManager = TokenManager();
      await tokenManager.deleteTokens();

      // 소셜 플랫폼별 로그아웃 처리
      final socialLogoutService = SocialLogoutService();
      await socialLogoutService.performSocialLogout();

      // context가 여전히 유효한지 다시 확인
      if (!context.mounted) return;

      // 로그인 페이지로 이동
      context.navigateTo(
          screen: const LoginScreen(),
          type: NavigationTypes.pushAndRemoveUntil);
    } else {
      // 실패 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }
}
