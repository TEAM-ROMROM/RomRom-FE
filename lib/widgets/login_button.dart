import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/email_already_registered_exception.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/onboarding_flow_screen.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/apple_auth_service.dart';
import 'package:romrom_fe/services/google_auth_service.dart';
import 'package:romrom_fe/services/kakao_auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 버튼
class LoginButton extends StatefulWidget {
  const LoginButton({super.key, required this.platform});

  final LoginPlatforms platform;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();
  final AppleAuthService appleAuthService = AppleAuthService();
  bool _isLoading = false;

  Future<void> handleLogin(BuildContext context) async {
    if (_isLoading) return; // 이미 로그인 중이면 무시
    ApiClient.resetSuspendedFlag(); // 재로그인 시 제재 플래그 리셋
    setState(() => _isLoading = true);

    // 로딩 오버레이 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.opacity50Black,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      ),
    );

    try {
      bool isSuccess = false;

      switch (widget.platform) {
        case LoginPlatforms.kakao:
          isSuccess = await kakaoAuthService.loginWithKakao(context);
          break;
        case LoginPlatforms.apple:
          isSuccess = await appleAuthService.logInWithApple();
          break;
        case LoginPlatforms.google:
          isSuccess = await googleAuthService.logInWithGoogle();
          break;
      }

      if (!mounted) return; // 로그인 완료 후 context가 유효한지 체크

      // 로딩 오버레이 닫기
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (isSuccess) {
        var userInfo = UserInfo();
        await userInfo.getUserInfo();

        final prefs = await SharedPreferences.getInstance();

        if (userInfo.isFirstLogin == true) {
          await prefs.setBool('isFirstMainScreen', true);
          await prefs.setBool('dontShowCoachMark', false);
        } else {
          if (!prefs.containsKey('isFirstMainScreen')) {
            await prefs.setBool('isFirstMainScreen', false);
          }
        }

        Widget nextScreen;
        if (userInfo.needsOnboarding) {
          nextScreen = OnboardingFlowScreen(initialStep: userInfo.nextOnboardingStep);
        } else {
          await RomAuthApi().fetchAndSaveMemberInfo();
          // 기존 회원 로그인: FCM 토큰 저장
          await FirebaseService().handleFcmToken();
          nextScreen = MainScreen(key: MainScreen.globalKey);
        }

        if (context.mounted) {
          context.navigateTo(screen: nextScreen, type: NavigationTypes.pushReplacement);
        }
      }
    } on AccountSuspendedException catch (e) {
      // 정지된 계정: 로딩 닫고 제재 안내 화면으로 이동
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        context.navigateTo(
          screen: AccountSuspendedScreen(suspendReason: e.suspendReason, suspendedUntil: e.suspendedUntil),
          type: NavigationTypes.pushReplacement,
        );
      }
    } on EmailAlreadyRegisteredException catch (e) {
      // 이메일 중복 가입: 로딩 닫고 기존 가입 플랫폼 안내 모달 표시
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        await CommonModal.error(
          context: context,
          message: '이미 ${e.displayPlatformName} 계정으로\n가입된 이메일입니다.\n해당 계정으로 로그인해주세요.',
          onConfirm: () => Navigator.of(context).pop(),
        );
      }
    } catch (e) {
      debugPrint("로그인 처리 중 오류: $e");
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '로그인에 실패했습니다. 다시 시도해 주세요.', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      scaleDown: AppPressable.scaleButton,
      enableRipple: false,
      onTap: _isLoading
          ? null
          : () async {
              await handleLogin(context);
            },
      child: Material(
        color: widget.platform.backgroundColor,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: double.infinity,
          height: 56.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 70.w,
                child: SvgPicture.asset(
                  widget.platform.iconPath,
                  width: 22.h,
                  height: 22.h,
                  placeholderBuilder: (context) => Icon(Icons.error, size: 24.sp, color: AppColors.warningRed),
                ),
              ),
              Center(
                child: Text(
                  widget.platform.displayText,
                  style: CustomTextStyles.p2.copyWith(color: widget.platform.textColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
