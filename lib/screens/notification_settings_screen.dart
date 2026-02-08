import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 알림 설정 화면
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // 각 설정 상태 (모든 초기값 ON - API 연동 시 서버 값으로 대체)
  bool _isMarketingEnabled = true; // ON
  bool _isActivityEnabled = true; // ON
  bool _isChatEnabled = true; // ON
  bool _isContentEnabled = true; // ON
  bool _isTransactionEnabled = true; // ON

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '설정', showBottomBorder: true, onBackPressed: () => Navigator.pop(context)),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 56.h, 24.w, 24.h),
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
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(12.r)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        itemCount: settingTypes.length,
        separatorBuilder: (_, __) => Divider(height: 24.h, color: AppColors.opacity30White),
        itemBuilder: (context, index) {
          return _buildSettingRow(settingTypes[index]);
        },
      ),
    );
  }

  /// 개별 설정 행 빌더
  Widget _buildSettingRow(NotificationSettingType type) {
    final bool value = _getSettingValue(type);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측: 타이틀 + 서브텍스트
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.title,
                style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                type.description,
                style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, letterSpacing: -0.5.sp),
              ),
            ],
          ),
        ),

        SizedBox(width: 16.w),

        // 우측: 토글 스위치
        CompletedToggleSwitch(value: value, onChanged: (newValue) => _onSettingChanged(type, newValue)),
      ],
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

  /// 설정 값 변경 핸들러
  void _onSettingChanged(NotificationSettingType type, bool newValue) {
    setState(() {
      switch (type) {
        case NotificationSettingType.marketing:
          _isMarketingEnabled = newValue;
          break;
        case NotificationSettingType.activity:
          _isActivityEnabled = newValue;
          break;
        case NotificationSettingType.chat:
          _isChatEnabled = newValue;
          break;
        case NotificationSettingType.content:
          _isContentEnabled = newValue;
          break;
        case NotificationSettingType.transaction:
          _isTransactionEnabled = newValue;
          break;
      }
    });

    // 상태만 변경 (저장 없음)
    debugPrint('알림 설정 변경: ${type.title} = $newValue');
    // TODO: API 연동 시 서버로 전송
  }
}
