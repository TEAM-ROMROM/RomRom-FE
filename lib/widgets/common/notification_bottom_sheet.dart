import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
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
      title: Text('교환 소식을 놓치지 마세요!', style: CustomTextStyles.h1),
      description: Text(
        '내 물건에 대한 실시간 교환 제안과 채팅 알림을 보내드려요.',
        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, height: 1.5),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/notificationExchangeYellowCircle.svg', width: 40, height: 40),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 물건에 교환 요청', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('받은 요청을 지금 확인해볼까요?', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
              ],
            ),
          ],
        ),
      ),
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
      title: Text('아직 알림이 꺼져 있어요!', style: CustomTextStyles.h1),
      description: Text(
        '알림을 켜지 않으면 상대방의 교환 요청 제안을\n바로 확인하기 어려워요.',
        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, height: 1.5),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/notificationExchangeYellowCircle.svg', width: 40, height: 40),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 물건에 교환 요청', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('받은 요청을 지금 확인해볼까요?', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
              ],
            ),
          ],
        ),
      ),
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
      title: Text('아직 알림이 꺼져 있어요!', style: CustomTextStyles.h1),
      description: Text(
        '알림을 켜지 않으면 상대방의 교환 요청 제안을\n바로 확인하기 어려워요.',
        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, height: 1.5),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/notificationExchangeYellowCircle.svg', width: 40, height: 40),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 물건에 교환 요청', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('받은 요청을 지금 확인해볼까요?', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
              ],
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),

              // 타이틀
              title,
              const SizedBox(height: 10),

              // 설명
              description,
              const SizedBox(height: 20),

              // 본문 영역
              body,
              const SizedBox(height: 24),

              // 버튼 행
              Row(
                children: [
                  // 좌측 버튼 (보조)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Material(
                        color: AppColors.opacity30PrimaryBlack,
                        borderRadius: BorderRadius.circular(10.r),
                        child: InkWell(
                          onTap: () {
                            onButton1();
                            Navigator.pop(context);
                          },
                          highlightColor: AppColors.opacity30PrimaryBlack,
                          splashColor: AppColors.opacity30PrimaryBlack.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Center(
                            child: Text(buttonText1, style: CustomTextStyles.p2, textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 우측 버튼 (주요, 노란색)
                  Expanded(
                    child: SizedBox(
                      height: 48,
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
                              style: CustomTextStyles.p2.copyWith(
                                color: AppColors.textColorBlack,
                                fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }
}
