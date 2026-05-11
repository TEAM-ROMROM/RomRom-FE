import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class ProfileReviewSection extends StatefulWidget {
  final String? memberId;

  const ProfileReviewSection({super.key, this.memberId});

  @override
  State<ProfileReviewSection> createState() => _ProfileReviewSectionState();
}

class _ProfileReviewSectionState extends State<ProfileReviewSection> {
  List<TradeReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final memberId = widget.memberId ?? await UserInfo().getCurrentMemberId();
      final response = await TradeApi().getTradeReview(
        TradeRequest(member: Member(memberId: memberId), pageNumber: 0, pageSize: 10),
      );
      if (mounted) {
        setState(() => _reviews = response.tradeReviewPage?.content ?? []);
      }
    } catch (e) {
      debugPrint('거래 후기 로드 실패: $e');
      if (mounted) setState(() => _reviews = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
      return const Center(child: CommonLoadingIndicator());
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
              Text(review.reviewerMember?.nickname ?? '(알 수 없음)', style: CustomTextStyles.p2.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              Text(
                review.reviewerMember?.locationAddress ?? '(알 수 없음)',
                style: CustomTextStyles.p2.copyWith(fontSize: 11.sp, color: AppColors.opacity60White),
              ),
              if (review.reviewComment != null && review.reviewComment!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _ExpandableComment(text: review.reviewComment!, style: CustomTextStyles.p2.copyWith(height: 1.2)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandableComment extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ExpandableComment({required this.text, required this.style});

  @override
  State<_ExpandableComment> createState() => _ExpandableCommentState();
}

class _ExpandableCommentState extends State<_ExpandableComment> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = tp.didExceedMaxLines;

        return GestureDetector(
          onTap: isOverflowing ? () => setState(() => _isExpanded = !_isExpanded) : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
                  child: Text(
                    widget.text,
                    style: widget.style,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (isOverflowing)
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: AnimatedRotation(
                    turns: _isExpanded ? -0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.opacity60White),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
