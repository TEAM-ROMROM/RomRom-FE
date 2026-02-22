import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/requests/notification_history_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';

/// 알림 화면
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // 로딩 상태
  bool _isLoading = false;

  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 활동 및 채팅, true: 롬롬 소식)
  bool _isRightSelected = false;

  // 알림 데이터 (임시)
  final List<NotificationItemData> _activityNotifications = [];
  final List<NotificationItemData> _romromNotifications = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 토글 애니메이션 컨트롤러 초기화
    _toggleAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: Curves.easeInOut));

    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  /// 알림 데이터 로드
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    NotificationApi notificationApi = NotificationApi();
    try {
      // 실제 API 호출 예시 (주석 처리)
      final notificationResponse = await notificationApi.getUserNotifications(
        NotificationHistoryRequest(pageNumber: 0, pageSize: 10),
      );
      debugPrint(
        '알림 데이터 로드 성공: ${notificationResponse.notificationHistoryPage?.content?.length ?? 0}개',
      ); // API에서 알림 데이터 로그 출력

      if (mounted) {
        setState(() {
          _activityNotifications.clear();
          _romromNotifications.clear();

          // API에서 받은 데이터를 기반으로 알림 리스트 업데이트
          if (notificationResponse.notificationHistoryPage?.content != null) {
            for (var item in notificationResponse.notificationHistoryPage!.content!) {
              final notificationData = NotificationItemData(
                id: item.notificationHistoryId!,
                type: NotificationType.fromServerName(item.notificationType ?? ''),
                title: item.title!,
                description: item.body!,
                time: item.publishedAt ?? DateTime.now(),
                imageUrl: item.payload?['imageUrl'], // payload에서 이미지 URL 추출 (예시) - 실제 API에 따라 조정 필요
              );

              if (item.notificationType == NotificationType.systemNotice.serverName) {
                _romromNotifications.add(notificationData);
              } else {
                _activityNotifications.add(notificationData);
              }
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('알림 데이터 로드 실패: $e');
      CommonSnackBar.show(context: context, message: '알림 데이터를 불러오는 데 실패했습니다.', type: SnackBarType.error);
    }
  }

  /// 토글 변경 처리
  void _onToggleChanged(bool isRightSelected) {
    setState(() {
      _isRightSelected = isRightSelected;
      if (isRightSelected) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    });
  }

  /// 설정 화면으로 이동
  void _onSettingsTap() {
    context.navigateTo(screen: const NotificationSettingsScreen());
  }

  /// 알림 끄기
  /// TODO: 실제 API 연동 후 알림 끄기 기능 구현
  void _onMuteNotification(String notificationId) {
    CommonSnackBar.show(context: context, message: '알림 끄기 기능 준비 중입니다.', type: SnackBarType.info);
  }

  /// 알림 삭제
  /// TODO: 실제 API 연동 후 삭제 기능 구현
  void _onDeleteNotification(String notificationId) {
    setState(() {
      _activityNotifications.removeWhere((n) => n.id == notificationId);
      _romromNotifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.primaryYellow,
            backgroundColor: AppColors.transparent,
            onRefresh: _loadNotifications,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: GlassHeaderDelegate(
                    toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                      animation: _toggleAnimation,
                      isRightSelected: _isRightSelected,
                      onLeftTap: () => _onToggleChanged(false),
                      onRightTap: () => _onToggleChanged(true),
                      leftText: '활동 및 채팅',
                      rightText: '롬롬 소식',
                    ),
                    headerTitle: '알림',
                    statusBarHeight: MediaQuery.of(context).padding.top,
                    toolbarHeight: 64.h,
                    toggleHeight: 62.h, // 실제 토글 높이 (bottom padding 제거)
                    expandedExtra: 0.h, // 토글-알림목록 간격 제거
                    enableBlur: _isScrolled,
                    centerTitle: true, // 타이틀 중앙 정렬
                    leadingWidget: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(AppIcons.navigateBefore, size: 28.sp, color: AppColors.textColorWhite),
                    ),
                    trailingWidget: Padding(
                      padding: EdgeInsets.only(right: 8.w), // 기본 16 + 8 = 24px 우측 패딩
                      child: GestureDetector(
                        onTap: _onSettingsTap,
                        child: Icon(AppIcons.setting, size: 30.sp, color: AppColors.textColorWhite),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildNotificationList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _isRightSelected ? _romromNotifications : _activityNotifications;

    if (_isLoading) {
      return SizedBox(
        height: 300.h,
        child: const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
      );
    }

    if (notifications.isEmpty) {
      return Container(
        height: 300.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            _isRightSelected ? '롬롬 소식이 없습니다' : '알림이 없습니다',
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 4.h, 0.w, 0),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => SizedBox(height: 0.h),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationItemWidget(
              data: notification,
              onMuteTap: () => _onMuteNotification(notification.id),
              onDeleteTap: () => _onDeleteNotification(notification.id),
            );
          },
        ),
      ),
    );
  }
}
