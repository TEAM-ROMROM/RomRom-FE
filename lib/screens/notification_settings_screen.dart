import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/do_not_disturb_setting_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/states/do_not_disturb_setting_state.dart';
import 'package:romrom_fe/utils/marketing_consent_message.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/notification/do_not_disturb_settings_section.dart';
import 'package:romrom_fe/widgets/skeletons/notification_settings_skeleton.dart';

/// 알림 설정 화면: 서버 설정 불러오기(실패 시 다시 시도), 시스템 권한 꺼짐 배너, 항목별 토글, 방해금지 시간
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  // 서버 설정 불러오기 실패 (모두 꺼짐으로 오해하지 않게 스위치 대신 다시 시도 표시)
  bool _hasLoadError = false;
  // 휴대폰 알림 권한 허용 여부 (null: 확인 전)
  bool? _isSystemPermissionGranted;

  // 시스템 설정 복귀 후 처리할 대기 중인 알림 설정 타입
  NotificationSettingType? _pendingEnableType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationSettings();
    _refreshSystemPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // 시스템 설정에서 권한을 바꾸고 돌아온 경우 배너 갱신
    _refreshSystemPermissionState();
    if (_pendingEnableType != null) _handleReturnFromSystemSettings();
  }

  /// 시스템 설정에서 복귀 시 권한 상태 확인 후 처리
  Future<void> _handleReturnFromSystemSettings() async {
    final NotificationSettingType type = _pendingEnableType!;
    _pendingEnableType = null;

    final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
    if (permissionGranted) await _applySettingChange(type, true);
  }

  /// 휴대폰 알림 권한 상태 갱신
  Future<void> _refreshSystemPermissionState() async {
    final bool isGranted = await NotificationPermissionService().isPermissionGranted();
    if (mounted && isGranted != _isSystemPermissionGranted) {
      setState(() => _isSystemPermissionGranted = isGranted);
    }
  }

  /// 서버에서 현재 알림 설정 값 로딩 (실패 시 다시 시도 화면)
  Future<void> _loadNotificationSettings() async {
    try {
      final memberProfile = await ref.read(memberProfileProvider.notifier).fetchLatest();
      final Member? member = memberProfile.member;
      if (member == null) throw StateError('member is null');
      if (!mounted) return;
      ref.read(notificationSettingProvider.notifier).seed({
        NotificationSettingType.marketing: member.isMarketingInfoAgreed ?? false,
        NotificationSettingType.activity: member.isActivityNotificationAgreed ?? false,
        NotificationSettingType.chat: member.isChatNotificationAgreed ?? false,
        NotificationSettingType.content: member.isContentNotificationAgreed ?? false,
        NotificationSettingType.transaction: member.isTradeNotificationAgreed ?? false,
      }, force: true);
      ref.read(doNotDisturbSettingProvider.notifier).seed(DoNotDisturbSettingState.fromMember(member));
      setState(() {
        _isLoading = false;
        _hasLoadError = false;
      });
    } catch (e) {
      debugPrint('알림 설정 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadError = true;
        });
      }
    }
  }

  /// 다시 시도: 스켈레톤 표시 > 재조회
  void _retryLoadNotificationSettings() {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    _loadNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '설정', onBackPressed: () => Navigator.pop(context)),
      body: _buildBody(),
    );
  }

  /// 본문: 로딩 > 스켈레톤, 실패 > 다시 시도, 그 외 > 권한 배너 + 설정 그룹
  Widget _buildBody() {
    if (_isLoading) return const NotificationSettingsSkeleton();
    if (_hasLoadError) {
      return EmptyStateView.error(centerText: '알림 설정을 불러오지 못했어요', onRetry: _retryLoadNotificationSettings);
    }
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
        child: Column(
          children: [
            if (_isSystemPermissionGranted == false) ...[_buildSystemPermissionBanner(), SizedBox(height: 16.h)],
            // 상단 그룹 (마케팅, 활동, 채팅, 콘텐츠)
            _buildSettingsGroup([
              NotificationSettingType.marketing,
              NotificationSettingType.activity,
              NotificationSettingType.chat,
              NotificationSettingType.content,
            ]),

            SizedBox(height: 16.h), // 그룹 간 간격
            // 하단 그룹 (거래)
            _buildSettingsGroup([NotificationSettingType.transaction]),

            SizedBox(height: 16.h),
            // 방해금지 시간 (#1007)
            const DoNotDisturbSettingsSection(),
          ],
        ),
      ),
    );
  }

  /// 휴대폰 알림 꺼짐 배너: 안내 + 탭하면 시스템 설정
  Widget _buildSystemPermissionBanner() {
    return AppPressable(
      onTap: NotificationPermissionService().openSettings,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Row(
          children: [
            Icon(AppIcons.alertOff, size: 20.sp, color: AppColors.warningRed),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '휴대폰 알림이 꺼져 있어요',
                    style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '설정에서 롬롬 알림을 허용해야 알림을 받을 수 있어요',
                    style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '설정 열기',
              style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 그룹 박스 빌더
  Widget _buildSettingsGroup(List<NotificationSettingType> settingTypes) {
    return Container(
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        children: List.generate(settingTypes.length, (index) {
          return _buildSettingRow(settingTypes[index]);
        }),
      ),
    );
  }

  /// 개별 설정 행 빌더
  Widget _buildSettingRow(NotificationSettingType type) {
    final bool value = ref.watch(notificationSettingProvider.select((s) => s[type] ?? false));

    return SizedBox(
      height: 74.h,
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title, style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
                  SizedBox(height: 8.h),
                  Text(
                    type.description,
                    style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // 터치 영역 44px 이상 (스위치 20px + 위아래 12px, 오른쪽 여백은 행 패딩에서 이동)
            CompletedToggleSwitch(
              value: value,
              semanticLabel: type.title,
              touchAreaPadding: EdgeInsets.fromLTRB(8.w, 12, 12.w, 12),
              onChanged: (newValue) => _onSettingChanged(type, newValue),
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 값 변경 핸들러 (즉시 API 호출)
  /// ON 시도 시 시스템 권한 확인 → 거부 상태면 안내 모달 표시
  Future<void> _onSettingChanged(NotificationSettingType type, bool newValue) async {
    if (newValue) {
      final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
      if (!permissionGranted) {
        if (!mounted) return;
        await CommonModal.confirm(
          context: context,
          message: '시스템 알림 허용이 필요합니다.',
          cancelText: '취소',
          confirmText: '알림 켜기',
          onCancel: () => Navigator.pop(context),
          onConfirm: () {
            _pendingEnableType = type;
            Navigator.pop(context);
            NotificationPermissionService().openSettings();
          },
        );
        return;
      }
    }
    await _applySettingChange(type, newValue);
  }

  /// 설정 변경 요청 > 마케팅 수신 변경 성공 시 처리 일자 안내 (실패 안내는 provider 담당)
  Future<void> _applySettingChange(NotificationSettingType type, bool isEnabled) async {
    final isChanged = await ref.read(notificationSettingProvider.notifier).setEnabled(type, isEnabled);
    if (!isChanged || type != NotificationSettingType.marketing || !mounted) return;
    CommonSnackBar.show(
      context: context,
      message: buildMarketingConsentMessage(isAgreed: isEnabled, processedAt: DateTime.now()),
      type: SnackBarType.success,
    );
  }
}
