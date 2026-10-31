import 'dart:async';

import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 공통 모달 위젯: success, error, confirm 팩토리 + 비동기 확인 중 버튼 잠금
/// 모달 박스는 고정 px (iPad에서도 312 폭 유지)
class CommonModal extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String message;
  final String? cancelText;
  final String confirmText;
  final Color confirmButtonColor;
  final Color confirmTextColor;
  final VoidCallback? onCancel;
  // Future 반환 시 완료까지 확인·취소 잠금, 동기 콜백은 기존처럼 즉시 실행
  final FutureOr<void> Function() onConfirm;

  // 모달 박스 식별 키 (폭 검증 테스트용)
  @visibleForTesting
  static const Key modalBoxKey = ValueKey<String>('commonModalBox');

  const CommonModal._({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.message,
    this.cancelText,
    required this.confirmText,
    required this.confirmButtonColor,
    required this.confirmTextColor,
    this.onCancel,
    required this.onConfirm,
  });

  //  앱 내에서 특정 조건에서 한 번만 보여줘야 하는 모달 처리 헬퍼
  static void showOnceAfterFrame({
    required BuildContext context,
    required bool Function() shouldShow, // 보여줘야 하는지 판단하는 함수
    required VoidCallback markShown, // 보여줬다고 표시하는 함수
    required bool Function() isShown, // 이미 보여줬는지 체크하는 함수
    required String message,
    required FutureOr<void> Function() onConfirm,
  }) {
    if (isShown()) return;
    if (!shouldShow()) return;

    markShown();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await CommonModal.error(context: context, message: message, onConfirm: onConfirm);
    });
  }

  /// 모달 등장 애니메이션: fade + scale (0.92→1.0)
  static Widget _buildTransition(Widget child, Animation<double> animation) {
    final curvedAnim = CurvedAnimation(parent: animation, curve: AppMotion.decelerate);
    return FadeTransition(
      opacity: curvedAnim,
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim), child: child),
    );
  }

  /// 성공 모달 (노란색 체크 아이콘, 1버튼)
  static Future<void> success({
    required BuildContext context,
    required String message,
    String buttonText = '확인',
    required FutureOr<void> Function() onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
        icon: AppIcons.onboardingProgressCheck,
        iconColor: AppColors.primaryYellow,
        iconBackgroundColor: AppColors.primaryYellow.withValues(alpha: 0.2),
        message: message,
        confirmText: buttonText,
        confirmButtonColor: AppColors.primaryYellow,
        confirmTextColor: AppColors.textColorBlack,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 에러 모달 (빨간색 경고 아이콘, 1버튼)
  static Future<void> error({
    required BuildContext context,
    required String message,
    String buttonText = '확인',
    required FutureOr<void> Function() onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
        icon: AppIcons.warning,
        iconColor: AppColors.warningRed,
        iconBackgroundColor: AppColors.warningRed.withValues(alpha: 0.2),
        message: message,
        confirmText: buttonText,
        confirmButtonColor: AppColors.warningRed,
        confirmTextColor: AppColors.textColorWhite,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 확인 모달 (2버튼)
  /// confirmText를 통해 '삭제', '나가기', '탈퇴' 등 커스텀 가능
  /// icon/iconColor/confirmButtonColor 미지정 시 기본 경고(빨간색) 스타일 적용
  static Future<bool?> confirm({
    required BuildContext context,
    required String message,
    String cancelText = '취소',
    String confirmText = '확인',
    required VoidCallback onCancel,
    required FutureOr<void> Function() onConfirm,
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
    Color? confirmTextColor,
  }) {
    final resolvedIcon = icon ?? AppIcons.warning;
    final resolvedIconColor = iconColor ?? AppColors.warningRed;
    final resolvedConfirmButtonColor = confirmButtonColor ?? AppColors.warningRed;
    final resolvedConfirmTextColor = confirmTextColor ?? AppColors.textColorWhite;
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
        icon: resolvedIcon,
        iconColor: resolvedIconColor,
        iconBackgroundColor: resolvedIconColor.withValues(alpha: 0.2),
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmButtonColor: resolvedConfirmButtonColor,
        confirmTextColor: resolvedConfirmTextColor,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CommonModal> createState() => _CommonModalState();
}

class _CommonModalState extends State<CommonModal> {
  // 모달 박스 폭 (고정 px)
  static const double _modalWidth = 312;
  // 단일 버튼 폭 (고정 px)
  static const double _singleButtonWidth = 264;
  // 버튼 높이 (고정 px)
  static const double _buttonHeight = 44;
  // 확인 버튼 자리 로딩 스피너 크기
  static const double _confirmLoadingIndicatorSize = 18;
  // 본문·버튼 글자 크기 (고정 px — 박스가 고정 폭이라 .sp 확대 시 태블릿에서 줄바꿈 깨짐)
  static const double _messageFontSize = 14;
  static const double _buttonFontSize = 16;

  // 비동기 onConfirm 진행 여부 (true면 확인·취소 비활성)
  bool _isConfirmInProgress = false;

  /// 확인 탭: 진행 중이면 무시 > 실행 > Future면 완료까지 잠금
  void _onConfirmPressed() {
    if (_isConfirmInProgress) return;
    final confirmResult = widget.onConfirm();
    if (confirmResult is! Future<void>) return;
    // onConfirm이 동기 구간에서 모달을 닫아 해제된 경우 잠금 생략 (완료·에러 보고는 유지)
    if (mounted) setState(() => _isConfirmInProgress = true);
    unawaited(_unlockWhenConfirmCompleted(confirmResult));
  }

  /// 확인 Future 완료 > 실패 시 FlutterError 보고 > 잠금 해제 (성공·실패 공통)
  Future<void> _unlockWhenConfirmCompleted(Future<void> pendingConfirm) async {
    try {
      await pendingConfirm;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'common modal',
          context: ErrorDescription('while running CommonModal onConfirm'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirmInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTwoButton = widget.cancelText != null && widget.onCancel != null;

    // 확인 진행 중 시스템 뒤로가기 차단 (모달만 닫힌 뒤 호출부 pop이 아래 화면 닫는 문제)
    return PopScope(
      canPop: !_isConfirmInProgress,
      child: _buildDialog(isTwoButton: isTwoButton),
    );
  }

  /// 모달 박스: 아이콘 > 메시지 > 버튼
  Widget _buildDialog({required bool isTwoButton}) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      backgroundColor: AppColors.secondaryBlack1,
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 200 : 40),
      child: Container(
        key: CommonModal.modalBoxKey,
        width: _modalWidth,
        constraints: const BoxConstraints(maxWidth: _modalWidth),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: AppColors.opacity15Black, blurRadius: 10, offset: Offset(2, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: widget.iconBackgroundColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(widget.icon, size: 40, color: widget.iconColor),
                ),
              ),
              const SizedBox(height: 16),
              // 메시지
              Text(
                widget.message,
                style: CustomTextStyles.p2.copyWith(
                  fontSize: _messageFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.opacity80White,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 버튼
              isTwoButton ? _buildTwoButtons() : _buildSingleButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 확인 버튼 내용: 진행 중이면 로딩 스피너, 아니면 문구
  Widget _buildConfirmContent(TextStyle confirmTextStyle) {
    if (_isConfirmInProgress) {
      return CommonLoadingIndicator(color: widget.confirmTextColor, size: _confirmLoadingIndicatorSize);
    }
    return Text(widget.confirmText, style: confirmTextStyle, textAlign: TextAlign.center);
  }

  /// 단일 버튼 (success, error)
  Widget _buildSingleButton() {
    return SizedBox(
      width: _singleButtonWidth,
      height: _buttonHeight,
      child: AppPressable(
        onTap: _isConfirmInProgress ? null : _onConfirmPressed,
        borderRadius: BorderRadius.circular(10),
        rippleColor: darkenBlend(widget.confirmButtonColor),
        child: Container(
          decoration: BoxDecoration(color: widget.confirmButtonColor, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: _buildConfirmContent(
            CustomTextStyles.p1.copyWith(
              fontSize: _buttonFontSize,
              color: widget.confirmTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// 2버튼 (confirm)
  Widget _buildTwoButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 취소 버튼 (확인 진행 중 비활성)
        Expanded(
          child: SizedBox(
            height: _buttonHeight,
            child: AppPressable(
              onTap: _isConfirmInProgress ? null : widget.onCancel,
              borderRadius: BorderRadius.circular(10),
              rippleColor: darkenBlend(AppColors.opacity30PrimaryBlack),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.opacity30PrimaryBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.cancelText!,
                  style: CustomTextStyles.p1.copyWith(fontSize: _buttonFontSize),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 확인/삭제/나가기 버튼
        Expanded(
          child: SizedBox(
            height: _buttonHeight,
            child: AppPressable(
              onTap: _isConfirmInProgress ? null : _onConfirmPressed,
              borderRadius: BorderRadius.circular(10),
              rippleColor: darkenBlend(widget.confirmButtonColor),
              child: Container(
                decoration: BoxDecoration(color: widget.confirmButtonColor, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: _buildConfirmContent(CustomTextStyles.p1.copyWith(fontSize: _buttonFontSize)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
