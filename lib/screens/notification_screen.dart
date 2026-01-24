import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_category.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';

/// 알림 화면
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
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
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toggleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

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

    // TODO: 실제 API 연동 필요
    // 임시 더미 데이터
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _activityNotifications.clear();
      _activityNotifications.addAll([
        NotificationItemData(
          id: '1',
          category: NotificationCategory.exchangeRequest,
          title: '님이 회원님의 물건에 교환을 원해요!',
          description: '[한정판 가전] 다이슨 에어랩 올인원 풀박스 정품, [한정판 가전] 다이슨 에어랩 올인원 풀박스 정품',
          time: DateTime.now().subtract(const Duration(minutes: 3)),
          imageUrl: 'https://picsum.photos/100/100',
        ),
        NotificationItemData(
          id: '2',
          category: NotificationCategory.like,
          title: '님이 회원님의 물건을 좋아해요!',
          description: '[한정판 가전] 다이슨 에어랩 올인원 풀박스 정품',
          time: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        NotificationItemData(
          id: '3',
          category: NotificationCategory.chat,
          title: '님이 채팅을 보냈어요',
          description: '안녕하세요! 혹시 직거래 가능할까요?',
          time: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]);

      _romromNotifications.clear();
      _romromNotifications.addAll([
        NotificationItemData(
          id: '4',
          category: NotificationCategory.announcement,
          title: '롬롬 공지사항',
          description: '새로운 기능이 추가되었습니다! 확인해보세요.',
          time: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

      _isLoading = false;
    });
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
    CommonSnackBar.show(
      context: context,
      message: '설정 기능 준비 중입니다.',
      type: SnackBarType.info,
    );
  }

  /// 알림 끄기
  void _onMuteNotification(String notificationId) {
    CommonSnackBar.show(
      context: context,
      message: '알림 끄기 기능 준비 중입니다.',
      type: SnackBarType.info,
    );
  }

  /// 알림 삭제
  void _onDeleteNotification(String notificationId) {
    setState(() {
      _activityNotifications.removeWhere((n) => n.id == notificationId);
      _romromNotifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
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
                    toolbarHeight: 58.h,
                    toggleHeight: 70.h,
                    expandedExtra: 32.h,
                    enableBlur: _isScrolled,
                    leadingWidget: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        AppIcons.navigateBefore,
                        size: 28.sp,
                        color: AppColors.textColorWhite,
                      ),
                    ),
                    trailingWidget: GestureDetector(
                      onTap: _onSettingsTap,
                      child: Icon(
                        AppIcons.setting,
                        size: 24.sp,
                        color: AppColors.textColorWhite,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildNotificationList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications =
        _isRightSelected ? _romromNotifications : _activityNotifications;

    if (_isLoading) {
      return SizedBox(
        height: 300.h,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryYellow,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Container(
        height: 300.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            _isRightSelected ? '롬롬 소식이 없습니다' : '알림이 없습니다',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: List.generate(notifications.length, (index) {
          final notification = notifications[index];
          return Column(
            children: [
              NotificationItemWidget(
                data: notification,
                onMuteTap: () => _onMuteNotification(notification.id),
                onDeleteTap: () => _onDeleteNotification(notification.id),
              ),
              if (index < notifications.length - 1)
                Divider(
                  thickness: 1,
                  color: AppColors.opacity10White,
                  height: 1.h,
                ),
            ],
          );
        }),
      ),
    );
  }
}
