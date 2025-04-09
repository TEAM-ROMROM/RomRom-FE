import 'package:flutter/material.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/screens/login_screen.dart';

/// 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void handleLogoutBtnTap() {
      final authApi = RomAuthApi();
      authApi.logoutWithSocial(context);
    }

void handleDeleteMemberBtnTap() {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('회원 탈퇴'),
      content: const Text('정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext); // 다이얼로그 닫기

            // 회원 탈퇴 진행
            final memberApi = MemberApi();
            final isSuccess = await memberApi.deleteMember();

            if (isSuccess && context.mounted) {
              // 토큰 삭제 후 로그인 화면으로 이동
              final tokenManager = TokenManager();
              await tokenManager.deleteTokens();

              // 로그인 페이지로 이동
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // 모든 이전 라우트 제거
              );
            } else if (context.mounted) {
              // 실패 안내
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('회원 탈퇴에 실패했습니다. 다시 시도해주세요.')),
              );
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('탈퇴하기'),
        ),
      ],
    ),
  );
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: handleLogoutBtnTap,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.pink[300]),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              child: const Text('로그아웃', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: handleDeleteMemberBtnTap,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red[400]),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              child: const Text('회원탈퇴', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
