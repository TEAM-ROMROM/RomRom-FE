import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/keyword_alert_rejection_reason.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/states/keyword_alerts_state.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/keyword_alert/keyword_alert_actions.dart';
import 'package:romrom_fe/widgets/keyword_alert/keyword_alert_input_row.dart';
import 'package:romrom_fe/widgets/keyword_alert/keyword_alert_list.dart';

/// 키워드 알림 설정 화면: 설명, 입력 + 추가, 등록 개수 n/최대, 키워드 목록(삭제) (#1020)
/// 목록은 keywordAlertsProvider 구독 (진입 시 서버 재조회), 첫 로드 실패 > 다시 시도
class KeywordAlertSettingsScreen extends ConsumerStatefulWidget {
  static const String title = '키워드 알림';
  static const String descriptionText = '등록한 단어가 들어간 새 물품이 내 탐색 범위에 올라오면 알려드려요';

  const KeywordAlertSettingsScreen({super.key});

  @override
  ConsumerState<KeywordAlertSettingsScreen> createState() => _KeywordAlertSettingsScreenState();
}

class _KeywordAlertSettingsScreenState extends ConsumerState<KeywordAlertSettingsScreen> {
  final TextEditingController _keywordController = TextEditingController();
  // 등록 요청 진행 중 (추가 버튼 중복 탭 방지)
  bool _isSubmitting = false;
  // 첫 로드 실패 후 다시 시도 진행 중
  bool _isRetrying = false;
  // 삭제 요청 진행 중인 키워드 id
  final Set<String> _deletingKeywordAlertIds = {};

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_onKeywordChanged);
    // 다른 기기 변경분 반영 (첫 로드 중이면 provider가 무시)
    ref.read(keywordAlertsProvider.notifier).reload();
  }

  @override
  void dispose() {
    _keywordController.removeListener(_onKeywordChanged);
    _keywordController.dispose();
    super.dispose();
  }

  // 추가 버튼·안내 문구 갱신
  void _onKeywordChanged() => setState(() {});

  /// 입력 거부 사유 (빈 입력·2자 미만 입력 중 > 문구 없이 버튼만 비활성, 개수 초과는 입력 없이도 표시)
  KeywordAlertRejectionReason? _findInputRejectionReason(KeywordAlertsState keywordAlertsState) {
    final hasInput = _keywordController.text.trim().isNotEmpty;
    if (!hasInput) return keywordAlertsState.hasReachedLimit ? KeywordAlertRejectionReason.limitReached : null;
    return findKeywordAlertRejectionReason(
      keyword: _keywordController.text,
      registeredKeywords: keywordAlertsState.registeredKeywords,
      maximumKeywordAlertCount: keywordAlertsState.maximumKeywordAlertCount,
    );
  }

  /// 추가: 진행 중 무시 > 등록(성공 시 입력 비우기) > 진행 표시 해제
  Future<void> _onAddPressed() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await registerKeywordAlertWithFeedback(
        context: context,
        ref: ref,
        keyword: _keywordController.text,
        onRegistered: _keywordController.clear,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 삭제: 같은 키워드 진행 중 무시 > 삭제 > 진행 표시 해제
  Future<void> _onDeletePressed(KeywordAlert keywordAlert) async {
    final keywordAlertId = keywordAlert.keywordAlertId;
    if (keywordAlertId == null || _deletingKeywordAlertIds.contains(keywordAlertId)) return;
    setState(() => _deletingKeywordAlertIds.add(keywordAlertId));
    try {
      await deleteKeywordAlertWithFeedback(context: context, ref: ref, keywordAlert: keywordAlert);
    } finally {
      if (mounted) setState(() => _deletingKeywordAlertIds.remove(keywordAlertId));
    }
  }

  /// 첫 로드 실패 > 다시 시도
  Future<void> _retryLoad() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await ref.read(keywordAlertsProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: KeywordAlertSettingsScreen.title, onBackPressed: () => Navigator.pop(context)),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  /// 본문: 첫 로드 실패 > 다시 시도, 그 외 > 설명 + 입력 + 개수 + 목록(불러오는 중 > 스피너)
  Widget _buildBody() {
    final keywordAlertsAsync = ref.watch(keywordAlertsProvider);
    final keywordAlertsState = keywordAlertsAsync.valueOrNull;
    if (keywordAlertsState == null && keywordAlertsAsync.hasError) {
      return EmptyStateView.error(centerText: '키워드 알림을 불러오지 못했어요', onRetry: _retryLoad, isRetrying: _isRetrying);
    }

    final rejectionReason = keywordAlertsState == null ? null : _findInputRejectionReason(keywordAlertsState);
    final hasInput = _keywordController.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KeywordAlertSettingsScreen.descriptionText,
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16.h),
          KeywordAlertInputRow(
            keywordController: _keywordController,
            canAddKeyword: keywordAlertsState != null && hasInput && rejectionReason == null,
            isSubmitting: _isSubmitting,
            onAddPressed: _onAddPressed,
            rejectionMessage: rejectionReason == null || rejectionReason == KeywordAlertRejectionReason.tooShort
                ? null
                : rejectionReason.buildMessage(maximumKeywordAlertCount: keywordAlertsState!.maximumKeywordAlertCount),
          ),
          SizedBox(height: 24.h),
          _buildCountHeader(keywordAlertsState),
          SizedBox(height: 12.h),
          Expanded(
            child: keywordAlertsState == null
                ? const Center(child: CommonLoadingIndicator())
                : KeywordAlertList(
                    keywordAlerts: keywordAlertsState.keywordAlerts,
                    deletingKeywordAlertIds: _deletingKeywordAlertIds,
                    onDeletePressed: _onDeletePressed,
                  ),
          ),
        ],
      ),
    );
  }

  /// 목록 머리: 제목 + 등록 개수 n/최대 (불러오기 전 > 개수 숨김)
  Widget _buildCountHeader(KeywordAlertsState? keywordAlertsState) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '등록한 키워드',
            style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
          ),
        ),
        if (keywordAlertsState != null)
          Text(
            '${keywordAlertsState.registeredCount}/${keywordAlertsState.maximumKeywordAlertCount}',
            style: CustomTextStyles.p2.copyWith(
              color: keywordAlertsState.hasReachedLimit ? AppColors.primaryYellow : AppColors.opacity60White,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
