import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/announcement.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/utils/date_time_display_utils.dart';
import 'package:romrom_fe/utils/home_popup_link_opener.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 공지 상세 화면: 공지 1건 조회 (로딩·실패 다시 시도) > 제목·작성일·이미지·본문·링크 버튼 (#1007)
/// 진입: 공지 푸시·알림 딥링크 romrom://notice/detail?announcementId=
class NoticeDetailScreen extends ConsumerStatefulWidget {
  final String announcementId;

  const NoticeDetailScreen({super.key, required this.announcementId});

  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  Announcement? _announcement;
  bool _isLoading = true;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncement();
  }

  /// 공지 조회 (없는 공지·네트워크 오류 > 다시 시도 화면)
  Future<void> _loadAnnouncement() async {
    // 첫 await 전 캡처 (조회 중 화면 종료 대비)
    final notificationRepository = ref.read(notificationRepositoryProvider);
    try {
      final announcement = await notificationRepository.getAnnouncementDetail(widget.announcementId);
      if (!mounted) return;
      setState(() {
        _announcement = announcement;
        _hasLoadError = false;
      });
    } catch (error) {
      debugPrint('[notice detail] load failed : $error');
      if (mounted) setState(() => _hasLoadError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 다시 시도: 로딩 표시 > 재조회
  void _retryLoadAnnouncement() {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    _loadAnnouncement();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '공지사항', onBackPressed: () => Navigator.pop(context)),
      body: _buildBody(),
    );
  }

  /// 본문: 로딩 > 인디케이터, 실패 > 다시 시도, 그 외 > 공지 내용
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CommonLoadingIndicator());
    final announcement = _announcement;
    if (_hasLoadError || announcement == null) {
      return EmptyStateView.error(centerText: '공지사항을 불러오지 못했어요', onRetry: _retryLoadAnnouncement);
    }
    final imageUrl = announcement.imageUrl;
    final linkUrl = announcement.linkUrl;
    final createdDate = announcement.createdDate;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 작성일
          Text(
            announcement.title ?? '',
            style: CustomTextStyles.h3.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
          ),
          if (createdDate != null) ...[
            const SizedBox(height: 8),
            Text(formatDate(createdDate), style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
          ],
          const SizedBox(height: 20),
          // 이미지 (선택, 너비 기준 비율)
          if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 1,
              child: CachedImage(imageUrl: imageUrl, borderRadius: BorderRadius.circular(10.r)),
            ),
            const SizedBox(height: 20),
          ],
          // 본문
          Text(
            announcement.content ?? '',
            style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite, height: 1.5),
          ),
          // 링크 버튼 (선택, romrom:// 앱 내 이동 · https:// 외부 브라우저)
          if (isOpenableHomePopupLink(linkUrl)) ...[
            const SizedBox(height: 24),
            CompletionButton(
              isEnabled: true,
              buttonText: '자세히 보기',
              enabledOnPressed: () => openHomePopupLink(context, linkUrl!),
            ),
          ],
        ],
      ),
    );
  }
}
