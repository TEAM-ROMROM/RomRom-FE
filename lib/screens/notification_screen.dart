import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/screens/notification_settings_screen.dart';
import 'package:romrom_fe/states/notification_list_state.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/notification_mute_rules.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/notification/notification_header_actions.dart';
import 'package:romrom_fe/widgets/notification/notification_history_list.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/skeletons/notification_skeleton.dart';

/// 알림 화면
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // 다음 페이지 선행 로드 기준: 끝에서 뷰포트 높이의 몇 배 전인지
  static const double _loadMorePrefetchViewportRatio = 1.5;

  final ScrollController _scrollController = ScrollController();

  // 알림 목록 notifier (dispose 시 전체 읽음 호출용 — 해제 후 ref 사용 불가라 initState에서 보관)
  late final NotificationListNotifier _notificationListNotifier;
  // 삭제 요청 진행 중인 알림 id (중복 탭 방지)
  final Set<String> _pendingDeleteIds = {};

  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 활동 및 채팅, true: 롬롬 소식)
  bool _isRightSelected = false;

  // 시스템 설정 복귀 후 처리할 대기 중인 알림 타입
  NotificationType? _pendingNotificationEnableType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);

    // 토글 애니메이션 컨트롤러 초기화
    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: AppMotion.standard));

    _notificationListNotifier = ref.read(notificationListProvider.notifier);
    // 진입 시 최신화 (빌드 중 provider 변경 금지 > 다음 틱, 첫 로드 진행 중이면 notifier가 무시)
    Future.microtask(_notificationListNotifier.reload);
    _loadNotificationSettings();
  }

  /// 알림 설정 상태 로드 — memberProfileProvider 회원 정보로 notificationSettingProvider에 seed(force: false).
  /// notification_settings_screen이 force:true로 최신화하므로, 여기선 미시드 상태일 때만 적용.
  Future<void> _loadNotificationSettings() async {
    try {
      // 공유 프로필 (조회 실패 상태로 남아 있으면 재조회)
      final memberProfile = await ref.read(memberProfileProvider.notifier).fetchCachedOrReload();
      final member = memberProfile.member;
      if (member != null && mounted) {
        ref.read(notificationSettingProvider.notifier).seed({
          NotificationSettingType.marketing: member.isMarketingInfoAgreed ?? false,
          NotificationSettingType.activity: member.isActivityNotificationAgreed ?? false,
          NotificationSettingType.chat: member.isChatNotificationAgreed ?? false,
          NotificationSettingType.content: member.isContentNotificationAgreed ?? false,
          NotificationSettingType.transaction: member.isTradeNotificationAgreed ?? false,
        }, force: false);
      }
    } catch (e) {
      debugPrint('알림 설정 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();

    // 화면이 사라질 때(팝 등) 모든 알림을 읽음 처리
    unawaited(_notificationListNotifier.markAllAsRead().catchError((e) => debugPrint('모든 알림 읽음 처리 실패(dispose): $e')));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingNotificationEnableType != null) {
      _handleReturnFromSystemSettings();
    }
  }

  /// 시스템 설정에서 복귀 시 권한 상태 확인 후 처리
  Future<void> _handleReturnFromSystemSettings() async {
    final NotificationType type = _pendingNotificationEnableType!;
    _pendingNotificationEnableType = null;

    final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
    if (!permissionGranted) return; // 거부 시 UI 변경 없음

    // 권한 허용됨 → provider 경유 업데이트
    final notifier = ref.read(notificationSettingProvider.notifier);
    switch (type) {
      case NotificationType.announcement:
        await notifier.setEnabled(NotificationSettingType.content, true);
        await notifier.setEnabled(NotificationSettingType.marketing, true);
        break;
      case NotificationType.chatMessageReceived:
        await notifier.setEnabled(NotificationSettingType.chat, true);
        break;
      case NotificationType.itemLiked:
        await notifier.setEnabled(NotificationSettingType.activity, true);
        break;
      case NotificationType.tradeRequestReceived:
        await notifier.setEnabled(NotificationSettingType.transaction, true);
        break;
      case NotificationType.itemDeletedByAdmin:
        // 관리자 제재 통보는 사용자가 끌 수 없는 강제 알림 → 설정 토글 대상 아님
        break;
    }
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
    _loadMoreIfNearListEnd();
  }

  /// 목록 끝에서 뷰포트 1.5배 전부터 다음 페이지 조회 (화면 자체 세로 스크롤 기준)
  /// 화면을 못 채운 경우(스크롤 불가)도 끝 근처로 판정 > 탭에 보일 알림이 찰 때까지 이어서 조회
  void _loadMoreIfNearListEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final prefetchThresholdPixels =
        position.maxScrollExtent - position.viewportDimension * _loadMorePrefetchViewportRatio;
    if (position.pixels >= prefetchThresholdPixels) _notificationListNotifier.loadMore();
  }

  /// 목록 갱신·탭 전환 후 레이아웃 반영된 다음 프레임에 끝 근처 여부 재확인
  void _scheduleLoadMoreCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreIfNearListEnd();
    });
  }

  /// 서버 알림 > 화면 표시 데이터 (탭 필터, 필수값 없는 알림 제외)
  /// 롬롬 소식 탭: announcement만, 활동 및 채팅 탭: 그 외 전부
  List<NotificationItemData> _toNotificationItems(
    List<NotificationHistory> notificationHistories, {
    required bool isRomromNewsTab,
  }) {
    final notificationItems = <NotificationItemData>[];
    for (final item in notificationHistories) {
      final id = item.notificationHistoryId;
      final title = item.title;
      final body = item.body;
      if (id == null || title == null || body == null) continue;

      final isRomromNews = item.notificationType == NotificationType.announcement.serverName;
      if (isRomromNews != isRomromNewsTab) continue;

      // 모르는 알림 타입 > 공지사항
      final type = NotificationType.fromServerName(item.notificationType) ?? NotificationType.announcement;

      notificationItems.add(
        NotificationItemData(
          id: id,
          type: type,
          title: title,
          description: body,
          time: item.publishedAt ?? DateTime.now(),
          imageUrl: item.payload?['imageUrl'], // payload에서 이미지 URL 추출
          isRead: item.isRead ?? false, // 읽음 상태 API에서 받아온 값 사용
          deepLink: item.payload?['deepLink'], // payload에서 딥링크 추출
        ),
      );
    }
    return notificationItems;
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
    _scheduleLoadMoreCheck();
  }

  /// 설정 화면으로 이동
  void _onSettingsTap() async {
    await context.navigateTo(screen: const NotificationSettingsScreen());
    // 설정 화면은 force:true로 시드하므로 복귀 후 provider가 최신 상태.
    // 별도 재로드 불필요.
  }

  /// 설정 화면으로 이동
  Future<void> _onDeleteAllNotificationTap() async {
    try {
      await _notificationListNotifier.deleteAll();
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '모든 알림이 삭제되었습니다.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    }
  }

  /// 알림 끄기/켜기 토글
  /// 지정된 알림 유형의 현재 상태를 반전시켜 업데이트합니다.
  Future<void> _onToggleMuteNotification(NotificationType notificationType) async {
    final settings = ref.read(notificationSettingProvider);
    final bool isMuted = isNotificationTypeMuted(settings, notificationType);

    // 음소거 해제(켜기) 시도 시 시스템 권한 확인
    if (isMuted) {
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
            _pendingNotificationEnableType = notificationType;
            Navigator.pop(context);
            NotificationPermissionService().openSettings();
          },
        );
        return;
      }
    }

    // provider.setEnabled 경유 (optimistic + API + dedup 내장)
    final bool newEnabled = isMuted; // muted → 켜기(true), unmuted → 끄기(false)
    final notifier = ref.read(notificationSettingProvider.notifier);
    final settingTypes = toNotificationSettingTypes(notificationType);
    for (final settingType in settingTypes) {
      await notifier.setEnabled(settingType, newEnabled);
    }

    if (mounted) {
      CommonSnackBar.show(context: context, message: isMuted ? '알림이 켜졌습니다.' : '알림이 꺼졌습니다.', type: SnackBarType.success);
    }
  }

  /// 알림 아이템 탭 처리 - 읽음 처리 후 딥링크 이동, 복귀 시 알림 목록 갱신
  Future<void> _onNotificationTap(NotificationItemData notification) async {
    try {
      await _notificationListNotifier.markAsRead(notification.id);
    } catch (e) {
      debugPrint('알림 읽음 처리 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
    if (!mounted) return;
    try {
      await RomRomDeepLinkRouter.open(context, notification.deepLink, notificationType: notification.type);
    } catch (e) {
      debugPrint('딥링크 이동 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        await _notificationListNotifier.reload();
      }
    }
  }

  /// 알림 삭제
  void _onDeleteNotification(String notificationId) async {
    // 삭제 진행 중인 알림 > 중복 요청 무시
    if (_pendingDeleteIds.contains(notificationId)) return;
    _pendingDeleteIds.add(notificationId);
    try {
      await _notificationListNotifier.delete(notificationId);
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '알림이 삭제되었습니다.', type: SnackBarType.success);
    } catch (e) {
      debugPrint('알림 삭제 실패: $e');
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    } finally {
      _pendingDeleteIds.remove(notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // provider 공유 — notification_settings_screen과 동일한 소스
    final settings = ref.watch(notificationSettingProvider);
    final notificationListAsync = ref.watch(notificationListProvider);

    ref.listen<AsyncValue<NotificationListState>>(notificationListProvider, (previous, next) {
      // 다시 불러오기·다음 페이지 실패 (기존 목록 유지 중) > 스낵바
      if (next.hasError && next.hasValue && !identical(previous?.error, next.error)) {
        CommonSnackBar.show(
          context: context,
          message: ErrorUtils.getErrorMessage(next.error!),
          type: SnackBarType.error,
        );
      }
      if (next.hasValue) _scheduleLoadMoreCheck();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryYellow,
            backgroundColor: AppColors.transparent,
            onRefresh: () async {
              await Future.wait([_notificationListNotifier.reload(), _loadNotificationSettings()]);
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
                    headerTitle: '알림함',
                    statusBarHeight: MediaQuery.of(context).padding.top,
                    toolbarHeight: 64.h,
                    toggleHeight: 62.h, // 실제 토글 높이 (bottom padding 제거)
                    expandedExtra: 0.h, // 토글-알림목록 간격 제거
                    enableBlur: _isScrolled,
                    centerTitle: true, // 타이틀 중앙 정렬
                    leadingWidget: AppPressable(
                      onTap: () => Navigator.pop(context),
                      scaleDown: AppPressable.scaleIcon,
                      enableRipple: false,
                      child: Icon(
                        AppIcons.navigateBefore,
                        size: 28.sp,
                        color: AppColors.textColorWhite,
                        semanticLabel: '뒤로 가기',
                      ),
                    ),
                    trailingWidget: NotificationHeaderActions(
                      onDeleteAllTap: _onDeleteAllNotificationTap,
                      onSettingsTap: _onSettingsTap,
                    ),
                  ),
                ),
                _buildNotificationSliver(settings, notificationListAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 알림 목록 영역: 첫 로드 중 스켈레톤, 첫 로드 실패 에러 뷰, 그 외 목록
  Widget _buildNotificationSliver(
    Map<NotificationSettingType, bool> settings,
    AsyncValue<NotificationListState> notificationListAsync,
  ) {
    final notificationList = notificationListAsync.valueOrNull;

    // 첫 로드·재시도 중 (데이터 없음)
    if (notificationList == null && notificationListAsync.isLoading) {
      return const SliverToBoxAdapter(child: NotificationListSkeleton());
    }

    // 첫 로드 실패 (데이터 없음) — 재시도 중엔 스켈레톤이라 중복 탭 불가
    if (notificationList == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView.error(centerText: '알림을 불러오지 못했어요', onRetry: _notificationListNotifier.reload),
      );
    }

    return SliverToBoxAdapter(child: _buildNotificationList(settings, notificationList));
  }

  Widget _buildNotificationList(Map<NotificationSettingType, bool> settings, NotificationListState notificationList) {
    return NotificationHistoryList(
      notifications: _toNotificationItems(notificationList.notifications, isRomromNewsTab: _isRightSelected),
      isRomromNewsTab: _isRightSelected,
      isLoadingMore: notificationList.isLoadingMore,
      pageSize: notificationPageSize,
      isMutedFor: (type) => isNotificationTypeMuted(settings, type),
      onNotificationTap: _onNotificationTap,
      onMuteTap: _onToggleMuteNotification,
      onDeleteTap: _onDeleteNotification,
    );
  }
}
