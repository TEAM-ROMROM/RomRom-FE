import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/utils/installed_app_version.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/utils/app_store_launcher.dart';
import 'package:romrom_fe/services/recommended_update_prompt_service.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/enums/token_refresh_outcome.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/app_version_repository_provider.dart';
import 'package:romrom_fe/providers/auth_repository_provider.dart';
import 'package:romrom_fe/repositories/app_version_repository.dart';
import 'package:romrom_fe/repositories/auth_repository.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/onboarding_flow_screen.dart';
import 'package:romrom_fe/services/splash_startup_sequence.dart';
import 'package:romrom_fe/screens/app_update_screen.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:romrom_fe/utils/log_http_client_interceptor.dart';
import 'package:romrom_fe/utils/user_session_lifecycle.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _loginTransitionController;
  late Animation<Alignment> _logoAlignmentAnim;
  late Animation<double> _loginUIFadeAnim;
  bool _showLoginUI = false;
  bool _loginTransitionStarted = false;
  String _appVersion = '';

  // 시작 실행 세대 (다시 시도·실패마다 증가 > 이전 실행의 늦은 완료 무시)
  int _startupGeneration = 0;
  // 시작 실패 설명 문구 (null이면 실패 아님)
  String? _startupFailureDescription;
  // 실패 화면에서 로그인 화면 이동 진행 중 (중복 탭 차단)
  bool _isLeavingToLogin = false;

  @override
  void initState() {
    super.initState();

    _loginTransitionController = AnimationController(vsync: this, duration: AppMotion.slow);

    // 로고 이동: 화면 중앙(-0.075) → 로그인 화면 로고 위치
    // end 값은 postFrameCallback에서 실제 레이아웃 측정값으로 교체됨
    _logoAlignmentAnim = AlignmentTween(
      begin: const Alignment(0, -0.075),
      end: const Alignment(0, -0.52),
    ).animate(CurvedAnimation(parent: _loginTransitionController, curve: AppMotion.standard));

    // 로그인 UI fade in: 30~100% 구간
    _loginUIFadeAnim = CurvedAnimation(
      parent: _loginTransitionController,
      curve: const Interval(0.3, 1.0, curve: AppMotion.entry),
    );

    unawaited(_initAndNavigate());
    unawaited(_loadAppVersion());
  }

  /// 로그인 UI 우하단에 표시할 앱 버전 로드 (LoginScreen과 동일 구현)
  Future<void> _loadAppVersion() async {
    // 조회 실패 시 빈 문자열 > 버전 문구 미표시
    final installedAppVersion = await fetchInstalledAppVersion();
    if (mounted) {
      setState(() => _appVersion = installedAppVersion);
    }
  }

  /// 스플래시 초기화 전체 타임아웃 (20초 = 버전 확인 제한 5초 + HTTP 요청 제한 15초)
  /// 버전 확인·개별 HTTP 요청 제한 시간이 1차 방어, 이 값은 2차 안전망
  static final Duration _splashTimeout = AppVersionRepository.versionCheckTimeout + LoggingHttpClient.defaultTimeout;

  /// 스플래시 최소 노출 시간 (2초, 버전 확인과 동시에 시작)
  static const Duration _minimumSplashDuration = Duration(seconds: 2);

  /// 시작 흐름: 버전·초기 화면 결정(타임아웃) > 실패 시 다시 시도 화면 > 강제 업데이트 화면 또는 권장 업데이트 안내 > 다음 화면 이동
  /// 다시 시도마다 세대 증가 > 타임아웃된 이전 실행이 늦게 끝나도 화면 이동 안 함
  Future<void> _initAndNavigate() async {
    final generation = ++_startupGeneration;
    bool isStale() => generation != _startupGeneration || !mounted;

    final SplashStartupResult<Widget> startupResult;
    try {
      // timeout() onTimeout 미제공 시 TimeoutException을 자동으로 throw
      startupResult = await _runStartupSequence(isStale).timeout(_splashTimeout);
    } catch (e, st) {
      debugPrint('[SplashScreen] 초기화 실패: $e\n$st');
      if (isStale()) return;
      _startupGeneration++; // 진행 중 실행 무효화
      setState(() => _startupFailureDescription = describeStartupFailure(e));
      return;
    }
    if (isStale() || startupResult.isAborted) return;

    if (startupResult.isForcedUpdate) {
      unawaited(AppUpdateScreen.showForcedUpdate(context));
      return;
    }
    if (startupResult.isRecommendedUpdate) {
      // 안내 실패(저장소·모달 오류)는 시작을 막지 않음
      try {
        await _showRecommendedUpdatePromptIfDue();
      } catch (error) {
        debugPrint('[SplashScreen] recommended update prompt failed : $error');
      }
      if (isStale()) return;
    }
    await _navigateToNextScreen(startupResult.nextScreen!);
  }

  /// 다시 시도: 실패 화면 해제 > 시작 흐름 재실행
  void _retryStartup() {
    setState(() => _startupFailureDescription = null);
    unawaited(_initAndNavigate());
  }

  /// 반복 실패 탈출: 로컬 토큰만 삭제 > 로그인 화면 (세션 종료 전환 경유, 서버 로그아웃은 연결 불가 상황이라 생략)
  Future<void> _moveToLoginAfterStartupFailure() async {
    if (_isLeavingToLogin) return;
    setState(() => _isLeavingToLogin = true);
    _startupGeneration++;
    try {
      await TokenManager().deleteTokens();
      SessionNavigationHandler.notifyLoggedOut();
    } catch (error) {
      debugPrint('[SplashScreen] leave to login failed : $error');
    } finally {
      // (성공·실패 공통)
      if (mounted) setState(() => _isLeavingToLogin = false);
    }
  }

  Future<SplashStartupResult<Widget>> _runStartupSequence(bool Function() isStale) {
    // 첫 await 전 캡처 (타임아웃으로 흐름이 이어져도 이후 ref 사용 불가)
    final appVersionRepository = ref.read(appVersionRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    return runSplashStartupSequence<Widget>(
      checkUpdateType: appVersionRepository.checkUpdateType,
      determineInitialScreen: () => _determineInitialScreen(authRepository),
      isAborted: isStale,
      minimumSplashDuration: _minimumSplashDuration,
    );
  }

  /// 권장 업데이트 안내 (주기 경과 시 1회, 닫으면 그대로 진행)
  Future<void> _showRecommendedUpdatePromptIfDue() async {
    final promptService = RecommendedUpdatePromptService();
    if (!await promptService.shouldShowPrompt() || !mounted) return;
    await promptService.markPromptShown();
    if (!mounted) return;
    await CommonModal.confirm(
      context: context,
      message: '새 버전이 나왔어요.\n업데이트하고 더 편하게 이용해 보세요.',
      cancelText: '나중에',
      confirmText: '업데이트',
      icon: AppIcons.infoCircle,
      iconColor: AppColors.primaryYellow,
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      onCancel: () => Navigator.of(context).pop(),
      // 스토어 열기 끝난 뒤 닫기 (실패 안내 스낵바가 루트 오버레이에 남도록 화면 이동 전에 표시)
      onConfirm: () async {
        await openAppStorePage(context);
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  /// 다음 화면 이동: 로그인 > 로그인 UI 전환 (링크 보관 유지), 그 외 > 세션 시작 (메인이면 보관 링크 열기)
  Future<void> _navigateToNextScreen(Widget nextScreen) async {
    if (nextScreen is LoginScreen) {
      await _playLoginTransitionAnimation();
      return;
    }
    startUserSession(
      invalidate: ref.invalidate,
      navigateToSessionScreen: () => context.navigateTo(screen: nextScreen, type: NavigationTypes.fadeTransition),
    );
    if (nextScreen is MainScreen) RomRomDeepLinkRouter.onMainScreenEntered();
  }

  /// 로고 이동 + 로그인 UI fade in.
  /// LoginScreen으로 교체하지 않음 — 스플래시 자체가 로그인 화면 역할을 함.
  /// clearStackImmediate 교체가 없으므로 순간이동 현상이 원천 차단됨.
  Future<void> _playLoginTransitionAnimation() async {
    if (!mounted || _loginTransitionStarted) return;
    _loginTransitionStarted = true;

    setState(() => _showLoginUI = true);

    // 로그인 UI가 렌더링된 후 실제 로고 위치를 측정하여 애니메이션 end값 교체
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        completer.complete();
        return;
      }
      final endY = _calculateLoginLogoAlignmentY(context);
      _logoAlignmentAnim = AlignmentTween(
        begin: const Alignment(0, -0.075),
        end: Alignment(0, endY),
      ).animate(CurvedAnimation(parent: _loginTransitionController, curve: AppMotion.standard));
      completer.complete();
    });
    await completer.future;
    if (!mounted) return;

    await _loginTransitionController.forward();
  }

  /// Scaffold.body(Stack) 기준으로 로고의 최종 Alignment Y를 계산한다.
  /// Align의 좌표계는 부모(Stack = Scaffold.body)의 크기 기준이므로
  /// screenHeight 대신 MediaQuery에서 padding을 뺀 실제 body 높이를 사용한다.
  double _calculateLoginLogoAlignmentY(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Scaffold.body의 실제 높이 = 전체 화면 - 상단 padding(status bar)
    // (Scaffold는 기본적으로 body를 status bar 아래부터 배치)
    final bodyHeight = mq.size.height - mq.padding.top;
    final logoSize = 108.w;

    // 로그인 화면(LoginScreen)과 동일한 레이아웃 수치
    final fixedBelowLogo = 45.h + 16.sp + 17.h + 17.h;
    final buttonCount = Platform.isIOS ? 3 : 2;
    final buttonGroupHeight = buttonCount * 56.h + (buttonCount - 1) * 12.h;
    final totalFixed = logoSize + fixedBelowLogo + buttonGroupHeight + 48.h;

    // SafeArea가 제거하는 top/bottom padding
    final safeTop = mq.padding.top;
    final safeBottom = mq.padding.bottom;
    final safeAreaHeight = mq.size.height - safeTop - safeBottom;

    final spacerTotal = safeAreaHeight - totalFixed;
    final topSpacerHeight = spacerTotal * 2 / 5;

    // 로고 중심 Y — body(Scaffold.body = status bar 아래) 기준
    final logoCenterY = safeTop + topSpacerHeight + logoSize / 2;

    // Align Y: Scaffold.body(=bodyHeight) 기준
    // Align Y = (logoCenterY_in_body / (bodyHeight / 2)) - 1
    final logoCenterInBody = logoCenterY - mq.padding.top; // body 안에서의 상대 Y
    return (logoCenterInBody / (bodyHeight / 2)) - 1;
  }

  /// 초기 화면 결정: 토큰 없음·재발급 거절 > 로그인, 재발급 연결 실패·서버 오류 > 예외(다시 시도 화면)
  Future<Widget> _determineInitialScreen(AuthRepository authRepository) async {
    final tokenManager = TokenManager();
    final String? refreshToken = await tokenManager.getRefreshToken();

    if (refreshToken == null) return const LoginScreen();

    switch (await authRepository.tryRefreshAccessToken()) {
      case TokenRefreshOutcome.rejected:
        return const LoginScreen();
      case TokenRefreshOutcome.retryableFailure:
        throw const SplashStartupRetryableException();
      case TokenRefreshOutcome.success:
        break;
    }

    // 회원 정보 조회: 연결·서버 오류 > 예외 전달(다시 시도 화면), 4xx·로컬 오류 > 로그인 화면
    final userInfo = UserInfo();
    try {
      await userInfo.getUserInfo();
      await MemberManager.getCurrentMember();
    } catch (error) {
      if (isRetryableMemberLoadError(error)) rethrow;
      debugPrint('[SplashScreen] member load failed, move to login : $error');
      return const LoginScreen();
    }

    if (userInfo.needsOnboarding) {
      return OnboardingFlowScreen(initialStep: userInfo.nextOnboardingStep);
    }

    // FCM 토큰 저장은 화면 이동과 무관 (권한 응답 대기 포함, 실패 로그는 handleFcmToken 내부)
    unawaited(FirebaseService().handleFcmToken());
    return const MainScreen();
  }

  @override
  void dispose() {
    _loginTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: _startupFailureDescription != null
            ? _buildStartupFailureView(_startupFailureDescription!)
            : Stack(
                children: [
                  // 로그인 UI (애니메이션 중에만 표시) — 로그인 화면과 동일한 SafeArea + Spacer 구조
                  if (_showLoginUI)
                    FadeTransition(
                      opacity: _loginUIFadeAnim,
                      child: Stack(
                        children: [
                          SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(flex: 2),
                                SizedBox(height: 108.w), // 로고 자리 확보
                                SizedBox(height: 45.h),
                                Text(
                                  '손쉬운 물품 교환',
                                  style: CustomTextStyles.p1.copyWith(
                                    color: AppColors.textColorWhite.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 17.h),
                                SvgPicture.asset('assets/images/login-romrom-text.svg', width: 124.w, height: 17.h),
                                const Spacer(flex: 3),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                                  child: AuthButtonGroup(
                                    buttons: [
                                      LoginPlatforms.kakao,
                                      if (Platform.isIOS) LoginPlatforms.apple,
                                      LoginPlatforms.google,
                                    ].map((platform) => LoginButton(platform: platform)).toList(),
                                  ),
                                ),
                                SizedBox(height: 48.h),
                              ],
                            ),
                          ),
                          // 우하단 버전 정보 (LoginScreen과 동일 — 고정 픽셀 사용, iPad 대응)
                          if (_appVersion.isNotEmpty)
                            Positioned(
                              right: 20,
                              bottom: 40,
                              child: Text(
                                'v$_appVersion',
                                style: CustomTextStyles.p4.copyWith(
                                  color: AppColors.textColorWhite.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // 로고: 항상 Align으로 표시, 애니메이션 중 이동
                  AnimatedBuilder(
                    animation: _loginTransitionController,
                    builder: (context, child) {
                      return Align(alignment: _logoAlignmentAnim.value, child: child);
                    },
                    child: SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 108.w),
                  ),
                ],
              ),
      ),
    );
  }

  /// 시작 실패 화면: 다시 시도 + 로그인 화면 이동 (서버 오류 반복 시 탈출 경로)
  Widget _buildStartupFailureView(String failureDescription) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: EmptyStateView.error(
              centerText: '롬롬을 시작하지 못했어요',
              descriptionText: failureDescription,
              onRetry: _retryStartup,
            ),
          ),
          TextButton(
            onPressed: _isLeavingToLogin ? null : _moveToLoginAfterStartupFailure,
            child: Text(
              '로그인 화면으로 이동',
              style: CustomTextStyles.p2.copyWith(
                color: AppColors.opacity60White,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.opacity60White,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
