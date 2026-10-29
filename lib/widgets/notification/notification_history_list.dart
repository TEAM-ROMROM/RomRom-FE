// 알림함 목록 본문: 탭별 빈 상태 문구, 알림 행 순차 등장, 다음 페이지 조회 중 표시
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';

/// 알림함 목록: 표시용 알림 데이터 렌더, 꺼짐 판정·탭·끄기·삭제는 화면 콜백
class NotificationHistoryList extends StatelessWidget {
  // 현재 탭에 보일 알림 (탭 필터 적용 후)
  final List<NotificationItemData> notifications;
  // 롬롬 소식 탭이면 true (빈 상태 문구 분기)
  final bool isRomromNewsTab;
  final bool isLoadingMore;
  // 한 페이지 알림 수 (페이지마다 등장 지연 처음부터)
  final int pageSize;
  final bool Function(NotificationType type) isMutedFor;
  final ValueChanged<NotificationItemData> onNotificationTap;
  final ValueChanged<NotificationType> onMuteTap;
  final ValueChanged<String> onDeleteTap;

  const NotificationHistoryList({
    super.key,
    required this.notifications,
    required this.isRomromNewsTab,
    required this.isLoadingMore,
    required this.pageSize,
    required this.isMutedFor,
    required this.onNotificationTap,
    required this.onMuteTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return AppFadeSlideIn(
        child: Container(
          height: 300.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Text(
              isRomromNewsTab ? '롬롬 소식이 없습니다' : '알림이 없습니다',
              style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 4.h, 0.w, 0),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, index) => const SizedBox.shrink(),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return AppFadeSlideIn(
                  // 페이지마다 stagger 처음부터 (뒤에 붙은 페이지 등장 지연 방지)
                  delay: Duration(milliseconds: (index % pageSize) * AppMotion.staggerDelayMs),
                  child: NotificationItemWidget(
                    data: notification,
                    isMuted: isMutedFor(notification.type),
                    onTap: () => onNotificationTap(notification),
                    onMuteTap: () => onMuteTap(notification.type),
                    onDeleteTap: () => onDeleteTap(notification.id),
                  ),
                );
              },
            ),
            // 다음 페이지 조회 중
            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CommonLoadingIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
