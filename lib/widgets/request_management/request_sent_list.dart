// 보낸 요청 목록 (정렬 칩 + 목록/빈상태/실패/로딩) - 카드 탭·수정·취소 로직은 화면 콜백에 위임
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
// Item.imageUrlList 확장 게터 사용을 위해 필요
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/request_management/request_sort_chip.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';

class RequestSentList extends StatelessWidget {
  final List<TradeRequestHistory> sentRequests;
  final bool isLoading;
  // 마지막 조회에서 실패한 카드 존재 여부 (결과 없음 > 오류 뷰, 결과 있음 > 일부 실패 배너)
  final bool hasLoadFailed;
  final VoidCallback onRetry;
  final RequestSortType currentSort;
  final ValueChanged<RequestSortType> onSortChanged;
  final void Function(TradeRequestHistory request) onCardTap;
  final void Function(TradeRequestHistory request) onEditTap;
  final void Function(TradeRequestHistory request) onCancelTap;

  const RequestSentList({
    super.key,
    required this.sentRequests,
    required this.isLoading,
    required this.hasLoadFailed,
    required this.onRetry,
    required this.currentSort,
    required this.onSortChanged,
    required this.onCardTap,
    required this.onEditTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 정렬 칩 행 (항상 표시)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 8),
          child: RequestSortChip(currentSort: currentSort, onChanged: onSortChanged),
        ),
        // 기존 목록/빈상태/로딩
        _buildListBody(),
      ],
    );
  }

  /// 보낸 요청 목록 본체 (빈 목록 로딩 > 결과 없는 실패 > 빈 목록 > 목록(일부 실패 시 배너) 순)
  Widget _buildListBody() {
    if (sentRequests.isEmpty && isLoading) {
      return const SizedBox(height: 500, child: Center(child: CommonLoadingIndicator()));
    }

    // 보여줄 결과 없이 실패 > 없음 문구 대신 오류 뷰
    if (sentRequests.isEmpty && hasLoadFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyStateView.error(centerText: '보낸 요청을 불러오지 못했어요', onRetry: onRetry),
      );
    }

    // 보낸 요청은 필터링 없이 모든 요청 표시
    if (sentRequests.isEmpty) {
      return Container(
        height: 200,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text('보낸 요청이 없습니다', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // 일부 카드 실패 > 성공 결과는 보여주고 상단에 다시 시도 배너 (재시도 중 숨김)
          if (hasLoadFailed && !isLoading) _buildPartialFailureBanner(),
          ..._buildSentCards(),
        ],
      ),
    );
  }

  /// 일부 실패 배너: 안내 문구 · 다시 시도 (실패 카드만 재조회)
  Widget _buildPartialFailureBanner() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '일부를 불러오지 못했어요',
            style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White),
          ),
          SizedBox(width: 8.w),
          AppPressable(
            onTap: onRetry,
            enableRipple: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '다시 시도',
                style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryYellow),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 보낸 요청 카드 목록 (물품은 상대 물품, 시각·거래 방식은 요청 자체 값)
  List<Widget> _buildSentCards() {
    return List.generate(sentRequests.length, (index) {
      final request = sentRequests[index];
      final takeItem = request.takeItem;
      final giveItem = request.giveItem;
      final tradeStatus = TradeStatus.fromServerName(request.tradeStatus);

      return AppFadeSlideIn(
        delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: SentRequestItemCard(
            onTap: () => onCardTap(request),
            myItemImageUrl: giveItem.imageUrlList.isNotEmpty ? giveItem.imageUrlList.first : '',
            otherItemImageUrl: takeItem.imageUrlList.isNotEmpty ? takeItem.imageUrlList.first : '',
            otherUserProfileUrl: takeItem.member?.profileUrl ?? '',
            title: takeItem.itemName ?? ' ',
            location: takeItem.address ?? '주소 미등록',
            requestedDate: request.requestedDate,
            tradeOptions: request.requestedTradeOptions,
            tradeStatus: tradeStatus ?? TradeStatus.chatting,
            canEdit: tradeStatus == TradeStatus.pending,
            onEditTap: () => onEditTap(request),
            onCancelTap: () => onCancelTap(request),
          ),
        ),
      );
    });
  }
}
