import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/member_withdrawal_reason.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/utils/withdrawal_ongoing_trade_message.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/my_page/member_withdrawal_reason_section.dart';

/// 탈퇴 요청 함수 형태 (사유·상세 사유 > 성공 여부)
typedef MemberWithdrawalRequest =
    Future<bool> Function({MemberWithdrawalReason? withdrawalReason, String? withdrawalReasonDetail});

/// 회원 탈퇴 화면: 사라지는 정보 안내 > 사유 선택(필수)·상세(선택) > 동의 체크 > 진행 중 거래 안내 > 탈퇴
/// 진행 중 거래(대기·채팅 중)는 확인 후 서버가 자동 취소, 성공 > 로그인 화면 전환 + 회원별 provider 초기화
class MemberWithdrawalScreen extends ConsumerStatefulWidget {
  // 탈퇴 시 더 이상 이용할 수 없는 정보 (서버 정책 문구 없이 일반 안내)
  static const List<String> deletedInformationLabels = ['등록한 물품과 교환 요청 내역', '채팅 내역', '받은 후기와 좋아요', '프로필과 활동 기록'];
  static const String agreementLabel = '안내 내용을 확인했으며 탈퇴에 동의해요';
  static const String ongoingTradeConfirmText = '취소하고 탈퇴';

  // 탈퇴 요청 > 성공 여부 (테스트 교체용, 기본 AuthService)
  final MemberWithdrawalRequest? deleteAccount;
  // 진행 중 거래 조회 (테스트 교체용, 기본 memberRepositoryProvider)
  final Future<List<TradeRequestHistory>> Function()? loadOngoingTrades;

  const MemberWithdrawalScreen({super.key, this.deleteAccount, this.loadOngoingTrades});

  @override
  ConsumerState<MemberWithdrawalScreen> createState() => _MemberWithdrawalScreenState();
}

class _MemberWithdrawalScreenState extends ConsumerState<MemberWithdrawalScreen> {
  final TextEditingController _reasonDetailController = TextEditingController();
  MemberWithdrawalReason? _selectedReason;
  bool _isAgreed = false;
  bool _isSubmitting = false;

  bool get _canSubmit => _isAgreed && _selectedReason != null;

  @override
  void dispose() {
    _reasonDetailController.dispose();
    super.dispose();
  }

  /// 탈퇴 요청: 사유·동의·중복 확인 > 진행 중 거래 안내(있으면 확인) > 요청 > 성공 시 세션 종료, 실패 시 안내
  /// 성공 시 화면 해제 여부와 무관하게 세션 종료 (계정·토큰 삭제 후 메인 잔류 > 401 반복 방지)
  Future<void> _submitWithdrawal() async {
    if (!_canSubmit || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final ongoingTrades = await _loadOngoingTradesOrEmpty();
      if (ongoingTrades.isNotEmpty) {
        if (!mounted) return;
        final isCancellationConfirmed = await _confirmOngoingTradeCancellation(ongoingTrades);
        if (!isCancellationConfirmed) return;
      }
      final deleteAccount = widget.deleteAccount ?? AuthService().deleteAccount;
      final isDeleted = await deleteAccount(
        withdrawalReason: _selectedReason,
        withdrawalReasonDetail: _reasonDetailController.text,
      );
      if (isDeleted) {
        SessionNavigationHandler.notifyLoggedOut();
        return;
      }
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '회원 탈퇴에 실패했습니다. 다시 시도해주세요.', type: SnackBarType.error);
    } catch (error) {
      debugPrint('[member withdrawal] failed : $error');
      if (mounted) {
        CommonSnackBar.show(context: context, message: '회원 탈퇴에 실패했습니다. 다시 시도해주세요.', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 진행 중 거래 조회 (실패·구버전 서버 > 빈 목록, 서버가 탈퇴 시 어차피 취소하므로 탈퇴는 계속)
  Future<List<TradeRequestHistory>> _loadOngoingTradesOrEmpty() async {
    try {
      final loadOngoingTrades =
          widget.loadOngoingTrades ?? ref.read(memberRepositoryProvider).getOngoingTradesBeforeWithdrawal;
      return await loadOngoingTrades();
    } catch (error) {
      debugPrint('[member withdrawal] ongoing trades load failed : $error');
      return const [];
    }
  }

  /// 진행 중 거래 취소 확인 모달 > 확인 여부
  Future<bool> _confirmOngoingTradeCancellation(List<TradeRequestHistory> ongoingTrades) async {
    final isConfirmed = await CommonModal.confirm(
      context: context,
      message: buildOngoingTradeCancellationMessage(ongoingTrades),
      confirmText: MemberWithdrawalScreen.ongoingTradeConfirmText,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    return isConfirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    // 탈퇴 요청 중 뒤로 가기 차단 (시스템 뒤로 가기·앱바)
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: CommonAppBar(
          title: '회원 탈퇴',
          showBottomBorder: true,
          onBackPressed: () {
            if (!_isSubmitting) Navigator.pop(context);
          },
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('탈퇴하기 전에 확인해 주세요', style: CustomTextStyles.h2),
                      SizedBox(height: 12.h),
                      Text(
                        '탈퇴하면 아래 정보를 더 이상 이용할 수 없고,\n탈퇴 후에는 되돌릴 수 없어요.',
                        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, height: 1.5),
                      ),
                      SizedBox(height: 24.h),
                      _buildDeletedInformationBox(),
                      SizedBox(height: 32.h),
                      MemberWithdrawalReasonSection(
                        selectedReason: _selectedReason,
                        onReasonSelected: (reason) => setState(() => _selectedReason = reason),
                        reasonDetailController: _reasonDetailController,
                        isEnabled: !_isSubmitting,
                      ),
                    ],
                  ),
                ),
              ),
              _buildAgreementRow(),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CompletionButton(
                  isEnabled: _canSubmit,
                  isLoading: _isSubmitting,
                  buttonText: '탈퇴하기',
                  enabledBackgroundColor: AppColors.warningRed,
                  disabledBackgroundColor: AppColors.secondaryBlack2,
                  enabledTextColor: AppColors.textColorWhite,
                  disabledTextColor: AppColors.opacity40White,
                  enabledOnPressed: _submitWithdrawal,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// 사라지는 정보 목록 박스
  Widget _buildDeletedInformationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final deletedInformation in MemberWithdrawalScreen.deletedInformationLabels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppColors.textColorWhite, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(child: Text(deletedInformation, style: CustomTextStyles.p2)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 동의 체크 행 (행 전체 탭, 화면낭독기 체크 상태)
  Widget _buildAgreementRow() {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isSubmitting ? null : () => setState(() => _isAgreed = !_isAgreed),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _isAgreed,
                  onChanged: _isSubmitting ? null : (value) => setState(() => _isAgreed = value ?? false),
                  activeColor: AppColors.primaryYellow,
                  checkColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                  side: const BorderSide(color: AppColors.primaryYellow),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(child: Text(MemberWithdrawalScreen.agreementLabel, style: CustomTextStyles.p2)),
            ],
          ),
        ),
      ),
    );
  }
}
