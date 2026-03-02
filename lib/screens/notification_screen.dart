import 'dart:async';

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
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
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

  // 알림 타입별 음소거 상태 (true = 알림 꺼짐)
  final Map<NotificationType, bool> _mutedNotificationTypes = {};

  // API 요청 진행 중인 알림 타입 추적 (중복 클릭 방지)
  final Set<NotificationType> _pendingMuteRequests = {};

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
    _loadNotificationSettings();
  }

  /// 알림 설정 상태 로드 (음소거 여부)
  Future<void> _loadNotificationSettings() async {
    try {
      final response = await MemberApi().getMemberInfo();
      final member = response.member;
      if (member != null && mounted) {
        setState(() {
          // false면 음소거(muted) 상태
          _mutedNotificationTypes[NotificationType.tradeRequestReceived] = !(member.isTradeNotificationAgreed ?? true);
          _mutedNotificationTypes[NotificationType.chatMessageReceived] = !(member.isChatNotificationAgreed ?? true);
          _mutedNotificationTypes[NotificationType.itemLiked] = !(member.isActivityNotificationAgreed ?? true);
          _mutedNotificationTypes[NotificationType.systemNotice] = !(member.isContentNotificationAgreed ?? true);
        });
      }
    } catch (e) {
      debugPrint('알림 설정 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();

    // 화면이 사라질 때(팝 등) 모든 알림을 읽음 처리
    unawaited(
      NotificationApi().updateAllNotificationsAsRead().catchError((e) => debugPrint('모든 알림 읽음 처리 실패(dispose): $e')),
    );
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
              final id = item.notificationHistoryId;
              final title = item.title;
              final body = item.body;
              if (id == null || title == null || body == null) continue;

              final type = NotificationType.values.firstWhere(
                (e) => e.serverName == item.notificationType,
                orElse: () => NotificationType.systemNotice,
              );

              final notificationData = NotificationItemData(
                id: id,
                type: type,
                title: title,
                description: body,
                time: item.publishedAt ?? DateTime.now(),
                imageUrl: item.payload?['imageUrl'], // payload에서 이미지 URL 추출
                isRead: item.isRead ?? false, // 읽음 상태 API에서 받아온 값 사용
                deepLink: item.payload?['deepLink'], // payload에서 딥링크 추출
              );

              if (item.notificationType == NotificationType.systemNotice.serverName) {
                _romromNotifications.add(notificationData);
              } else {
                _activityNotifications.add(notificationData);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('알림 데이터 로드 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: '알림 데이터를 불러오는 데 실패했습니다.', type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
  void _onSettingsTap() async {
    await context.navigateTo(screen: const NotificationSettingsScreen());
    _loadNotificationSettings(); // 복귀 후 설정 재로드
  }

  /// 설정 화면으로 이동
  Future<void> _onDeleteAllNotificationTap() async {
    try {
      await NotificationApi().deleteAllNotifications();
      if (!mounted) return;
      setState(() {
        _activityNotifications.clear();
        _romromNotifications.clear();
      });
      CommonSnackBar.show(context: context, message: '모든 알림이 삭제되었습니다.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '알림 삭제에 실패했습니다.', type: SnackBarType.error);
    }
  }

  /// 알림 끄기/켜기 토글
  /// 지정된 알림 유형의 현재 상태를 반전시켜 업데이트합니다.
  Future<void> _onToggleMuteNotification(NotificationType notificationType) async {
    // 이미 해당 타입의 요청이 진행 중이면 중복 클릭 무시
    if (_pendingMuteRequests.contains(notificationType)) return;

    final MemberApi api = MemberApi();
    final bool isMuted = _mutedNotificationTypes[notificationType] ?? false;
    final bool newValue = isMuted; // muted=true이면 켜야 하므로 true 전송, muted=false이면 꺼야 하므로 false 전송

    setState(() {
      _pendingMuteRequests.add(notificationType);
    });

    try {
      switch (notificationType) {
        case NotificationType.systemNotice:
          await api.updateNotificationSetting(isMarketingInfoAgreed: newValue, isContentNotificationAgreed: newValue);
          break;
        case NotificationType.chatMessageReceived:
          await api.updateNotificationSetting(isChatNotificationAgreed: newValue);
          break;
        case NotificationType.itemLiked:
          await api.updateNotificationSetting(isActivityNotificationAgreed: newValue);
          break;
        case NotificationType.tradeRequestReceived:
          await api.updateNotificationSetting(isTradeNotificationAgreed: newValue);
          break;
      }

      if (!mounted) return;
      setState(() {
        _mutedNotificationTypes[notificationType] = !isMuted;
      });
      CommonSnackBar.show(context: context, message: isMuted ? '알림이 켜졌습니다.' : '알림이 꺼졌습니다.', type: SnackBarType.success);
    } catch (e) {
      debugPrint('알림 설정 변경 실패: $e');
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '알림 설정 변경에 실패했습니다.', type: SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() {
          _pendingMuteRequests.remove(notificationType);
        });
      }
    }
  }

  /// 알림 삭제
  void _onDeleteNotification(String notificationId) async {
    try {
      await NotificationApi().deleteNotification(NotificationHistoryRequest(notificationHistoryId: notificationId));

      if (mounted) {
        setState(() {
          _activityNotifications.removeWhere((n) => n.id == notificationId);
          _romromNotifications.removeWhere((n) => n.id == notificationId);
        });
      }
      CommonSnackBar.show(context: context, message: '알림이 삭제되었습니다.', type: SnackBarType.success);
    } catch (e) {
      debugPrint('알림 삭제 실패: $e');
      CommonSnackBar.show(context: context, message: '알림 삭제에 실패했습니다.', type: SnackBarType.error);
    }
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
            onRefresh: () async {
              await Future.wait([_loadNotifications(), _loadNotificationSettings()]);
            },
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
                    trailingWidget: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8.w), // 기본 16 + 8 = 24px 우측 패딩
                          child: GestureDetector(
                            onTap: _onDeleteAllNotificationTap,
                            child: Icon(AppIcons.trash, size: 30.sp, color: AppColors.textColorWhite),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.w), // 기본 16 + 8 = 24px 우측 패딩
                          child: GestureDetector(
                            onTap: _onSettingsTap,
                            child: Icon(AppIcons.setting, size: 30.sp, color: AppColors.textColorWhite),
                          ),
                        ),
                      ],
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
              isMuted: _mutedNotificationTypes[notification.type] ?? false,
              onTap: () =>
                  RomRomDeepLinkRouter.open(context, notification.deepLink, notificationType: notification.type),
              onMuteTap: () => _onToggleMuteNotification(notification.type),
              onDeleteTap: () => _onDeleteNotification(notification.id),
            );
          },
        ),
      ),
    );
  }
}
