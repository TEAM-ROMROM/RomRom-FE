// 알림함 목록 본문 (sliver, 보이는 행만 생성): 탭별 빈 상태 문구, 첫 화면 행 순차 등장, 다음 페이지 조회 중 표시
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';

/// 알림함 목록 sliver: 표시용 알림 데이터 렌더, 꺼짐 판정·탭·끄기·삭제는 화면 콜백
/// 부모 CustomScrollView에 직접 넣음 > 스크롤로 보이는 행만 생성
class NotificationHistoryList extends StatefulWidget {
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
  State<NotificationHistoryList> createState() => _NotificationHistoryListState();
}

class _NotificationHistoryListState extends State<NotificationHistoryList> {
  // 목록 첫 프레임 종료 여부: 이후 생성 행(스크롤로 처음·다시 보이는 행)은 등장 애니메이션 없이 바로 표시
  bool _hasFirstRowsFrameEnded = false;
  bool _isFirstRowsFrameEndScheduled = false;

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications;
    if (notifications.isEmpty) {
      // 빈 목록 > 다음에 채워지면 첫 화면 행 다시 순차 등장 (탭 전환 시 기존 동작)
      _hasFirstRowsFrameEnded = false;
      _isFirstRowsFrameEndScheduled = false;
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    _scheduleFirstRowsFrameEnd();
    return SliverPadding(
      padding: EdgeInsets.only(top: 4.h),
      sliver: SliverList.builder(
        // 마지막 행: 다음 페이지 조회 중 표시
        itemCount: notifications.length + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) => index == notifications.length ? _buildLoadingMoreRow() : _buildRow(index),
      ),
    );
  }

  /// 첫 프레임(행 생성·레이아웃 포함) 끝난 뒤 표시 (같은 프레임 중복 예약 없음)
  void _scheduleFirstRowsFrameEnd() {
    if (_hasFirstRowsFrameEnded || _isFirstRowsFrameEndScheduled) return;
    _isFirstRowsFrameEndScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFirstRowsFrameEndScheduled = false;
      if (widget.notifications.isNotEmpty) _hasFirstRowsFrameEnded = true;
    });
  }

  Widget _buildEmptyState() {
    return AppFadeSlideIn(
      child: Container(
        height: 300.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            widget.isRomromNewsTab ? '롬롬 소식이 없습니다' : '알림이 없습니다',
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
          ),
        ),
      ),
    );
  }

  /// 알림 행: 첫 프레임 행만 순차 등장 (페이지마다 지연 처음부터)
  Widget _buildRow(int index) {
    final notification = widget.notifications[index];
    final row = NotificationItemWidget(
      data: notification,
      isMuted: widget.isMutedFor(notification.type),
      onTap: () => widget.onNotificationTap(notification),
      onMuteTap: () => widget.onMuteTap(notification.type),
      onDeleteTap: () => widget.onDeleteTap(notification.id),
    );
    if (_hasFirstRowsFrameEnded) return row;
    return AppFadeSlideIn(
      delay: Duration(milliseconds: (index % widget.pageSize) * AppMotion.staggerDelayMs),
      child: row,
    );
  }

  Widget _buildLoadingMoreRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CommonLoadingIndicator()),
    );
  }
}
