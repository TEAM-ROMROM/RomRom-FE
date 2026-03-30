import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet_chatting_preview.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet_request_preview.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 알림 안내 공용 바텀시트
///
/// [title]       : 타이틀 위젯 (Text 또는 RichText/Text.rich)
/// [description] : 설명 위젯 (Text 또는 RichText/Text.rich)
/// [body]        : 본문 영역 위젯 (미리보기 카드 등 자유롭게 구성)
/// [buttonText1] : 좌측 버튼 텍스트 (보조 액션)
/// [buttonText2] : 우측 버튼 텍스트 (주요 액션, 노란색)
/// [onButton1]   : 좌측 버튼 콜백
/// [onButton2]   : 우측 버튼 콜백
class NotificationBottomSheet {
  const NotificationBottomSheet._();

  static TextStyle get titleStyle => CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w600, height: 1.2);
  static TextStyle get descriptionStyle =>
      CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White, height: 1.4);
  static TextStyle get buttonTextStyle => CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600);

  static Future<void> show({
    required BuildContext context,
    required Widget title,
    required Widget description,
    required Widget body,
    required String buttonText1,
    required String buttonText2,
    required VoidCallback onButton1,
    required VoidCallback onButton2,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ChatNotificationSheet(
        title: title,
        description: description,
        body: body,
        buttonText1: buttonText1,
        buttonText2: buttonText2,
        onButton1: onButton1,
        onButton2: onButton2,
      ),
    );
  }

  /// 회원가입 후 첫 알림 유도 바텀시트 (회원가입 후 한 번만)
  /// - "나중에 하기" / "알림 설정하기"
  static Future<void> showNotificationBottomSheetAfterSiginIn(BuildContext context) {
    return show(
      context: context,
      title: Text('교환 소식을 놓치지 마세요!', style: titleStyle),
      description: RichText(
        text: TextSpan(
          style: descriptionStyle,
          children: [
            const TextSpan(text: '내 물건에 대한 실시간 '),
            const TextSpan(
              text: '교환 제안',
              style: TextStyle(color: AppColors.primaryYellow),
            ),
            const TextSpan(text: '과\n'),
            const TextSpan(
              text: '채팅 알림',
              style: TextStyle(color: AppColors.primaryYellow),
            ),
            const TextSpan(text: '을 보내드려요.'),
          ],
        ),
      ),
      body: const NotificationBotomSheetRequestPreview(),
      buttonText1: '나중에 하기',
      buttonText2: '알림 설정하기',
      onButton1: () {},
      onButton2: () {
        context.navigateTo(screen: const NotificationSettingsScreen());
      },
    );
  }

  /// 7일 주기 알림 허용 유도 바텀 시트
  /// - "7일 동안 보지 않기" / "알림 설정하기"
  static Future<void> showdNotificationBottomSheetCycle(BuildContext context) {
    return show(
      context: context,
      title: RichText(
        text: TextSpan(
          style: titleStyle,
          children: [
            const TextSpan(text: '아직 '),
            const TextSpan(
              text: '알림',
              style: TextStyle(color: AppColors.primaryYellow),
            ),
            const TextSpan(text: '이 꺼져 있어요!'),
          ],
        ),
      ),
      description: Text('알림을 켜지 않으면 상대방의 교환 요청 제안을\n바로 확인하기 어려워요.', style: descriptionStyle),
      body: const NotificationBotomSheetRequestPreview(),
      buttonText1: '7일 동안 보지 않기',
      buttonText2: '알림 설정하기',
      onButton1: () {
        NotificationPermissionService().recordDismissed();
      },
      onButton2: () {
        NotificationPermissionService().recordDismissed();
        context.navigateTo(screen: const NotificationSettingsScreen());
      },
    );
  }

  /// 채팅방 알림 꺼짐 안내 기본 프리셋
  /// - "닫기" / "알림 설정하기"
  static Future<void> showChatNotificationBottomSheet(BuildContext context) {
    return show(
      context: context,
      title: RichText(
        text: TextSpan(
          style: titleStyle,
          children: [
            const TextSpan(
              text: '채팅 알림',
              style: TextStyle(color: AppColors.primaryYellow),
            ),
            const TextSpan(text: '이 꺼져 있어요!'),
          ],
        ),
      ),
      description: Text('현재 알림이 꺼져 있어 답장을 놓칠 수 있어요.', style: descriptionStyle),
      body: const NotificationBotomSheetChattingPreview(),
      buttonText1: '닫기',
      buttonText2: '알림 설정하기',
      onButton1: () {},
      onButton2: () {
        context.navigateTo(screen: const NotificationSettingsScreen());
      },
    );
  }
}

class _ChatNotificationSheet extends StatelessWidget {
  const _ChatNotificationSheet({
    required this.title,
    required this.description,
    required this.body,
    required this.buttonText1,
    required this.buttonText2,
    required this.onButton1,
    required this.onButton2,
  });

  final Widget title;
  final Widget description;
  final Widget body;
  final String buttonText1;
  final String buttonText2;
  final VoidCallback onButton1;
  final VoidCallback onButton2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: 14.h, bottom: 11.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlack2,
                    borderRadius: BorderRadius.circular(2.r),
                    border: Border.all(
                      width: 2.w,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: AppColors.secondaryBlack2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 타이틀
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: title,
              ),
              SizedBox(height: 12.h),

              // 설명
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: description,
              ),
              SizedBox(height: 24.h),

              // 본문 영역 (좌우 패딩 없음)
              body,

              // 버튼 행
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    // 좌측 버튼 (보조)
                    Expanded(
                      child: SizedBox(
                        height: 56.h,
                        child: Material(
                          color: AppColors.secondaryBlack1,
                          borderRadius: BorderRadius.circular(10.r),
                          child: InkWell(
                            onTap: () {
                              onButton1();
                              Navigator.pop(context);
                            },
                            highlightColor: AppColors.buttonHighlightColorGray,
                            splashColor: AppColors.opacity30PrimaryBlack.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Center(
                              child: Text(
                                buttonText1,
                                style: NotificationBottomSheet.buttonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 7.w),

                    // 우측 버튼 (주요, 노란색)
                    Expanded(
                      child: SizedBox(
                        height: 56.h,
                        child: Material(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(10.r),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              onButton2();
                            },
                            highlightColor: darkenBlend(AppColors.primaryYellow),
                            splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Center(
                              child: Text(
                                buttonText2,
                                style: NotificationBottomSheet.buttonTextStyle.copyWith(
                                  color: AppColors.textColorBlack,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
