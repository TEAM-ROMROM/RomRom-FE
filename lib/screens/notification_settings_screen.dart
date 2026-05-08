import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/skeletons/notification_settings_skeleton.dart';

/// 알림 설정 화면
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  final MemberApi _memberApi = MemberApi();

  bool _isLoading = true;

  // 시스템 설정 복귀 후 처리할 대기 중인 알림 설정 타입
  NotificationSettingType? _pendingEnableType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingEnableType != null) {
      _handleReturnFromSystemSettings();
    }
  }

  /// 시스템 설정에서 복귀 시 권한 상태 확인 후 처리
  Future<void> _handleReturnFromSystemSettings() async {
    final NotificationSettingType type = _pendingEnableType!;
    _pendingEnableType = null;

    final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
    if (permissionGranted) {
      await ref.read(notificationSettingProvider.notifier).setEnabled(type, true);
    }
  }

  /// 서버에서 현재 알림 설정 값 로딩
  Future<void> _loadNotificationSettings() async {
    try {
      final response = await _memberApi.getMemberInfo();
      final Member? member = response.member;
      if (member != null && mounted) {
        ref.read(notificationSettingProvider.notifier).seed({
          NotificationSettingType.marketing: member.isMarketingInfoAgreed ?? false,
          NotificationSettingType.activity: member.isActivityNotificationAgreed ?? false,
          NotificationSettingType.chat: member.isChatNotificationAgreed ?? false,
          NotificationSettingType.content: member.isContentNotificationAgreed ?? false,
          NotificationSettingType.transaction: member.isTradeNotificationAgreed ?? false,
        }, force: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('알림 설정 로딩 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '설정', onBackPressed: () => Navigator.pop(context)),
      body: _isLoading
          ? const NotificationSettingsSkeleton()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                child: Column(
                  children: [
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
                  ],
                ),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            CompletedToggleSwitch(value: value, onChanged: (newValue) => _onSettingChanged(type, newValue)),
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
    await ref.read(notificationSettingProvider.notifier).setEnabled(type, newValue);
  }
}
