import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/received_reviews_refresh_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/services/reviewer_address_resolver.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/expandable_text.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class ProfileReviewSection extends ConsumerStatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;

  const ProfileReviewSection({super.key, this.memberId, this.onLoaded});

  @override
  ConsumerState<ProfileReviewSection> createState() => _ProfileReviewSectionState();
}

class _ProfileReviewSectionState extends ConsumerState<ProfileReviewSection> {
  List<TradeReview> _reviews = [];
  bool _isLoading = true;
  // 후기 조회 실패 (후기 0건과 구분 > 다시 시도 표시)
  bool _hasLoadError = false;
  final Map<String, String> _fetchedAddresses = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    // 첫 await 전 캡처 (내 회원 id 조회 중 화면 종료 대비)
    final tradeRepository = ref.read(tradeRepositoryProvider);
    try {
      final memberId = widget.memberId ?? await UserInfo().getCurrentMemberId();
      final reviews = await tradeRepository.getTradeReviews(memberId: memberId, pageNumber: 0, pageSize: 10);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _hasLoadError = false;
        });
      }
      await _fetchMissingAddresses();
    } catch (e) {
      debugPrint('거래 후기 로드 실패: $e');
      if (mounted) {
        setState(() {
          _reviews = [];
          _hasLoadError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      widget.onLoaded?.call();
    }
  }

  /// 후기 도착 푸시 > 내 후기 목록이면 조용히 재조회 (타인 프로필은 무시, #1007)
  Future<void> _reloadIfMyReviews() async {
    final isMyReviews = widget.memberId == null || await UserInfo().isSameMember(widget.memberId);
    if (isMyReviews && mounted) await _loadReviews();
  }

  /// 다시 시도: 로딩 표시 > 재조회
  void _retryLoadReviews() {
    setState(() => _isLoading = true);
    _loadReviews();
  }

  /// 주소 없는 후기 작성자 주소 병렬 변환 > 결과 1회 반영
  Future<void> _fetchMissingAddresses() async {
    final fetchedAddressByMemberId = await ReviewerAddressResolver().resolveMissingAddresses(_reviews);
    if (fetchedAddressByMemberId.isEmpty || !mounted) return;
    setState(() => _fetchedAddresses.addAll(fetchedAddressByMemberId));
  }

  Map<TradeReviewRating, int> get _ratingCounts {
    final counts = <TradeReviewRating, int>{for (final r in TradeReviewRating.values) r: 0};
    for (final review in _reviews) {
      for (final r in TradeReviewRating.values) {
        if (r.serverName == review.tradeReviewRating) {
          counts[r] = counts[r]! + 1;
          break;
        }
      }
    }
    return counts;
  }

  List<MapEntry<TradeReviewTag, int>> get _sortedTagCounts {
    final counts = <TradeReviewTag, int>{};
    for (final review in _reviews) {
      for (final tagStr in review.tradeReviewTags ?? []) {
        for (final tag in TradeReviewTag.values) {
          if (tag.serverName == tagStr) {
            counts[tag] = (counts[tag] ?? 0) + 1;
            break;
          }
        }
      }
    }
    // 전체 태그 포함, 카운트 내림차순 정렬
    final result = <MapEntry<TradeReviewTag, int>>[];
    for (final tag in TradeReviewTag.values) {
      result.add(MapEntry(tag, counts[tag] ?? 0));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(receivedReviewsRefreshTriggerProvider, (_, _) => _reloadIfMyReviews());

    if (_isLoading) {
      return const Center(child: CommonLoadingIndicator());
    }

    if (_hasLoadError) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24.h),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        child: EmptyStateView.error(centerText: '후기를 불러오지 못했어요', onRetry: _retryLoadReviews),
      );
    }

    final topRadius = BorderRadius.only(topLeft: Radius.circular(10.r), topRight: Radius.circular(10.r));
    final bottomRadius = BorderRadius.only(bottomLeft: Radius.circular(10.r), bottomRight: Radius.circular(10.r));
    final ratingCounts = _ratingCounts;
    final sortedTags = _sortedTagCounts;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24.h),
      child: Column(
        children: [
          /// 교환 후기 섹션
          ClipRRect(
            borderRadius: topRadius,
            child: Stack(
              children: [
                /// 기본 배경
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: topRadius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('교환 후기', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(height: 16.h),
                      Column(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 92.w,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int index = 0; index < TradeReviewRating.values.length; index++) ...[
                                    _buildRatingCountColumn(
                                      TradeReviewRating.values[index],
                                      ratingCounts[TradeReviewRating.values[index]] ?? 0,
                                    ),

                                    if (index != TradeReviewRating.values.length - 1)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 38.0.w),
                                        child: Container(
                                          width: 1.5.w,
                                          height: double.infinity,
                                          decoration: const BoxDecoration(color: AppColors.opacity10White),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 블러 그라데이션 오버레이
                Positioned(
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 80),
                      child: Container(
                        width: double.infinity,
                        height: 70.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            colors: [
                              AppColors.reviewRatingBad,
                              AppColors.reviewRatingGood,
                              AppColors.reviewRatingGreat,
                            ].map((c) => c.withValues(alpha: 0.15)).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 교환 후기 리스트
          Container(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: bottomRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [for (final entry in sortedTags) _buildRatingReviewTag(entry.key, entry.value)],
                ),
                if (_reviews.isNotEmpty) ...[
                  SizedBox(height: 24.h),
                  Column(
                    children: [
                      for (int i = 0; i < _reviews.length; i++) ...[
                        _buildReviewComment(_reviews[i]),
                        if (i >= 0 && i < _reviews.length - 1)
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16.h),
                            height: 1.5.h,
                            decoration: const BoxDecoration(color: AppColors.opacity10White),
                          ),
                        // if (i < _reviews.length - 1) SizedBox(height: 16.h),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveLocationAddress(Member? member) {
    if (member == null) return '(알 수 없음)';
    if (member.locationAddress != null && member.locationAddress!.isNotEmpty) {
      return member.locationAddress!;
    }
    final id = member.memberId;
    if (id != null && _fetchedAddresses.containsKey(id)) return _fetchedAddresses[id]!;
    return '(알 수 없음)';
  }

  Widget _buildRatingCountColumn(TradeReviewRating rating, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SvgPicture.asset(rating.selectedImgAsset, width: 40.w),
        SizedBox(height: 12.h),
        Text(
          rating.label,
          style: CustomTextStyles.p3.copyWith(color: rating.selectedColor, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4.h),
        Text(
          count.toString(),
          style: CustomTextStyles.h2.copyWith(color: rating.selectedColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRatingReviewTag(TradeReviewTag tag, int count) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.label, style: CustomTextStyles.p2),
          SizedBox(width: 16.w),
          Text(count.toString(), style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildReviewComment(TradeReview review) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        UserProfileCircularAvatar(
          avatarSize: Size(32.w, 32.w),
          profileUrl: review.reviewerMember?.profileUrl,
          isDeleteAccount: false,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.reviewerMember?.nickname == null
                    ? '(알 수 없음)'
                    : review.reviewerMember?.accountStatus == AccountStatus.deleteAccount.serverName
                    ? '(탈퇴) ${review.reviewerMember!.nickname!}'
                    : review.reviewerMember!.nickname!,
                style: CustomTextStyles.p2.copyWith(fontSize: 13.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                _resolveLocationAddress(review.reviewerMember),
                style: CustomTextStyles.p2.copyWith(fontSize: 11.sp, color: AppColors.opacity60White),
              ),
              if (review.reviewComment != null && review.reviewComment!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                ExpandableText(text: review.reviewComment!, style: CustomTextStyles.p2.copyWith(height: 1.2)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
