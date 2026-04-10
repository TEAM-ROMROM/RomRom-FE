import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 알림 설정 화면
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  final MemberApi _memberApi = MemberApi();

  // 각 설정 상태
  bool _isMarketingEnabled = false;
  bool _isActivityEnabled = false;
  bool _isChatEnabled = false;
  bool _isContentEnabled = false;
  bool _isTransactionEnabled = false;

  bool _isLoading = true;

  // 시스템 설정 복귀 후 처리할 대기 중인 알림 설정 타입
  NotificationSettingType? _pendingEnableType;

  // 진행 중인 API 요청 추적 (중복 요청 방지)
  final Set<NotificationSettingType> _pendingRequests = {};

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

    if (_pendingRequests.contains(type)) return;
    _pendingRequests.add(type);

    try {
      final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
      if (permissionGranted) {
        if (mounted) setState(() => _setSettingValue(type, true));
        await _updateNotificationSetting(type, true);
      }
      // 거부 시 UI 변경 없음 (토글이 원래 OFF 상태 유지)
    } finally {
      if (mounted) setState(() => _pendingRequests.remove(type));
    }
  }

  /// 설정 값 직접 변경 (setState 내부에서 사용)
  void _setSettingValue(NotificationSettingType type, bool value) {
    switch (type) {
      case NotificationSettingType.marketing:
        _isMarketingEnabled = value;
        break;
      case NotificationSettingType.activity:
        _isActivityEnabled = value;
        break;
      case NotificationSettingType.chat:
        _isChatEnabled = value;
        break;
      case NotificationSettingType.content:
        _isContentEnabled = value;
        break;
      case NotificationSettingType.transaction:
        _isTransactionEnabled = value;
        break;
    }
  }

  /// 서버에서 현재 알림 설정 값 로딩
  Future<void> _loadNotificationSettings() async {
    try {
      final response = await _memberApi.getMemberInfo();
      final Member? member = response.member;
      if (member != null && mounted) {
        setState(() {
          _isMarketingEnabled = member.isMarketingInfoAgreed ?? false;
          _isActivityEnabled = member.isActivityNotificationAgreed ?? false;
          _isChatEnabled = member.isChatNotificationAgreed ?? false;
          _isContentEnabled = member.isContentNotificationAgreed ?? false;
          _isTransactionEnabled = member.isTradeNotificationAgreed ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('알림 설정 로딩 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '설정', onBackPressed: () => Navigator.pop(context)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
    final bool value = _getSettingValue(type);

    return SizedBox(
      height: 74.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 좌측: 타이틀 + 서브텍스트
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

            // 우측: 토글 스위치
            CompletedToggleSwitch(value: value, onChanged: (newValue) => _onSettingChanged(type, newValue)),
          ],
        ),
      ),
    );
  }

  /// 설정 값 가져오기
  bool _getSettingValue(NotificationSettingType type) {
    switch (type) {
      case NotificationSettingType.marketing:
        return _isMarketingEnabled;
      case NotificationSettingType.activity:
        return _isActivityEnabled;
      case NotificationSettingType.chat:
        return _isChatEnabled;
      case NotificationSettingType.content:
        return _isContentEnabled;
      case NotificationSettingType.transaction:
        return _isTransactionEnabled;
    }
  }

  /// 설정 값 변경 핸들러 (즉시 API 호출)
  /// ON 시도 시 시스템 권한 확인 → 거부 상태면 안내 모달 표시
  Future<void> _onSettingChanged(NotificationSettingType type, bool newValue) async {
    if (_pendingRequests.contains(type)) return;
    _pendingRequests.add(type);

    try {
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
      if (mounted) setState(() => _setSettingValue(type, newValue));
      await _updateNotificationSetting(type, newValue);
    } finally {
      if (mounted) setState(() => _pendingRequests.remove(type));
    }
  }

  /// 서버에 알림 설정 업데이트
  Future<void> _updateNotificationSetting(NotificationSettingType type, bool value) async {
    try {
      await _memberApi.updateNotificationSetting(
        isMarketingInfoAgreed: type == NotificationSettingType.marketing ? value : null,
        isActivityNotificationAgreed: type == NotificationSettingType.activity ? value : null,
        isChatNotificationAgreed: type == NotificationSettingType.chat ? value : null,
        isContentNotificationAgreed: type == NotificationSettingType.content ? value : null,
        isTradeNotificationAgreed: type == NotificationSettingType.transaction ? value : null,
      );
    } catch (e) {
      debugPrint('알림 설정 업데이트 실패: $e');
      // 실패 시 토글 원복
      if (mounted) {
        setState(() {
          switch (type) {
            case NotificationSettingType.marketing:
              _isMarketingEnabled = !value;
              break;
            case NotificationSettingType.activity:
              _isActivityEnabled = !value;
              break;
            case NotificationSettingType.chat:
              _isChatEnabled = !value;
              break;
            case NotificationSettingType.content:
              _isContentEnabled = !value;
              break;
            case NotificationSettingType.transaction:
              _isTransactionEnabled = !value;
              break;
          }
        });
      }
    }
  }
}
