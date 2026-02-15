import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';

import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/widgets/trade_request_target_preview.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';

/// 요청하기 화면
/// 내 물품 카드 선택 후 거래방식을 선택하여 요청을 전송하는 화면
class TradeRequestScreen extends StatefulWidget {
  /// 교환 대상 물품 (상대방 물품)
  final Item targetItem;

  /// 교환 대상 물품 이미지 URL
  final String? targetImageUrl;

  /// 홈탭에서 스와이프한 카드 ID (선택사항)
  /// 이 값이 있으면 해당 카드를 자동 선택하고 2단계로 시작
  final String? preSelectedCardId;

  const TradeRequestScreen({super.key, required this.targetItem, this.targetImageUrl, this.preSelectedCardId});

  @override
  State<TradeRequestScreen> createState() => _TradeRequestScreenState();
}

class _TradeRequestScreenState extends State<TradeRequestScreen> {
  /// 선택된 카드가 있는지 여부에 따라 초기값 설정
  bool _hasSelectedCard = false;

  /// 내 물품 목록
  List<Item> _myItems = [];

  /// 화면에 표시할 카드 데이터
  List<RequestManagementItemCard> _myItemCards = [];

  /// 로딩 상태
  bool _isLoading = true;

  /// PageView 컨트롤러
  late PageController _pageController;

  /// 현재 선택된 카드 인덱스
  int _selectedCardIndex = 0;

  /// 선택된 거래 옵션들
  final Set<ItemTradeOption> _selectedTradeOptions = {};

  /// API 요청 진행 중 여부
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 227.w / 345.w);
    _loadMyItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 내 물품 목록 로드
  Future<void> _loadMyItems() async {
    setState(() => _isLoading = true);

    try {
      final itemApi = ItemApi();
      final response = await itemApi.getMyItems(
        ItemRequest(pageNumber: 0, pageSize: 20, itemStatus: ItemStatus.available.serverName),
      );

      if (!mounted) return;

      final items = response.itemPage?.content ?? [];
      final cards = _convertToItemCards(items);

      setState(() {
        _myItems = items;
        _myItemCards = cards;
        _isLoading = false;
      });

      // preSelectedCardId가 있으면 해당 카드 찾아서 선택 후 _hasSelectedCard를 true로 설정
      if (widget.preSelectedCardId != null && items.isNotEmpty) {
        final preSelectedIndex = items.indexWhere((item) => item.itemId == widget.preSelectedCardId);
        if (preSelectedIndex >= 0) {
          setState(() {
            _selectedCardIndex = preSelectedIndex;
            _hasSelectedCard = true;
          });
          // PageController 위치도 업데이트
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(preSelectedIndex);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('내 물품 목록 로드 실패: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);

      CommonSnackBar.show(context: context, message: '물품 목록을 불러오는데 실패했습니다.', type: SnackBarType.error);
    }
  }

  /// Item 목록을 RequestManagementItemCard 목록으로 변환
  List<RequestManagementItemCard> _convertToItemCards(List<Item> items) {
    return items.map((item) {
      String category;
      try {
        category = ItemCategories.fromServerName(item.itemCategory ?? '').label;
      } catch (_) {
        category = '기타';
      }

      return RequestManagementItemCard(
        itemId: item.itemId ?? '',
        imageUrl: item.primaryImageUrl ?? '',
        category: category,
        title: item.itemName ?? '',
        price: item.price ?? 0,
        likeCount: item.likeCount ?? 0,
        aiPrice: item.isAiPredictedPrice ?? false,
      );
    }).toList();
  }

  /// 거래 요청 API 호출
  Future<void> _submitTradeRequest() async {
    if (_selectedTradeOptions.isEmpty) {
      CommonSnackBar.show(context: context, message: '거래방식을 선택해주세요.', type: SnackBarType.info);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await TradeApi().requestTrade(
        TradeRequest(
          takeItemId: widget.targetItem.itemId,
          giveItemId: _myItems[_selectedCardIndex].itemId,
          itemTradeOptions: _selectedTradeOptions.map((o) => o.serverName).toList(),
        ),
      );

      if (!mounted) return;

      CommonSnackBar.show(context: context, message: '거래 요청이 전송되었습니다.', type: SnackBarType.success);

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('거래 요청 실패: $e');
      if (!mounted) return;

      final errorMessage = ErrorUtils.getErrorMessage(e);

      await CommonModal.error(context: context, message: errorMessage, onConfirm: () => Navigator.of(context).pop());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 교환 대상 물품의 태그 목록 생성
  List<String> _getTargetItemTags() {
    final tags = <String>[];

    // 물품 상태 태그
    if (widget.targetItem.itemCondition != null) {
      try {
        final condition = ItemCondition.fromServerName(widget.targetItem.itemCondition!);
        tags.add(condition.label);
      } catch (_) {}
    }

    // 거래방식 태그
    if (widget.targetItem.itemTradeOptions != null) {
      for (final option in widget.targetItem.itemTradeOptions!) {
        try {
          final tradeOption = ItemTradeOption.fromServerName(option);
          tags.add(tradeOption.label);
        } catch (_) {}
      }
    }

    return tags;
  }

  /// AppBar 높이만큼 상단 여백 추가
  Widget _buildAppBarSpacing() {
    return Container(
      height: MediaQuery.of(context).padding.top + kToolbarHeight,
      constraints: BoxConstraints(minHeight: 115.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const CommonAppBar(title: '요청하기'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, -1),
                  end: Alignment(0, 1),
                  stops: [0.0, 0.5, 1.0],
                  colors: AppColors.tradeRequestBackgroundGradient,
                ),
              ),
            ),
          ),
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: [
                _buildAppBarSpacing(),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                      : _myItemCards.isEmpty
                      ? _buildEmptyState()
                      : _buildTradeRequestStep(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 UI (내 물품이 없을 때)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64.sp, color: AppColors.opacity50White),
                SizedBox(height: 16.h),
                Text('등록된 물품이 없습니다', style: CustomTextStyles.h2.copyWith(color: AppColors.opacity80White)),
                SizedBox(height: 8.h),
                Text(
                  '교환 요청을 하려면 먼저\n물품을 등록해주세요.',
                  style: CustomTextStyles.p1.copyWith(color: AppColors.opacity50White, height: 1.2),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomFloatingButton(
                  isEnabled: true,
                  enabledOnPressed: () => Navigator.pop(context),
                  buttonText: '돌아가기',
                  buttonWidth: 120,
                  buttonHeight: 44,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 거래방식 선택 및 요청
  Widget _buildTradeRequestStep() {
    // 요청하기 버튼 색
    Color requestButtonColor = _isSubmitting ? AppColors.primaryYellow.withValues(alpha: 0.5) : AppColors.primaryYellow;
    // 요청하기 버튼 highlightColor
    Color requestButtonHighlightColor = darkenBlend(requestButtonColor);
    Color requestButtonSplashColor = requestButtonHighlightColor.withValues(alpha: 0.3);

    // 취소 버튼 색
    Color cancelButtonColor = AppColors.secondaryBlack1;
    // 취소 버튼 highlightColor
    Color cancelButtonHighlightColor = darkenBlend(AppColors.buttonHighlightColorGray);
    Color cancelButtonSplashColor = darkenBlend(AppColors.buttonHighlightColorGray).withValues(alpha: 0.3);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        children: [
          // 교환 대상 물품 미리보기
          TradeRequestTargetPreview(
            imageUrl: widget.targetImageUrl,
            itemName: widget.targetItem.itemName ?? '물품',
            tags: _getTargetItemTags(),
          ),

          // 내 물품 카드 영역
          Padding(
            padding: EdgeInsets.only(top: 32.h),
            child: !_hasSelectedCard
                ?
                  // 카드 선택 상태: 내 물품 카드 PageView로 선택 가능
                  Column(
                    children: [
                      SizedBox(
                        height: 334.h,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _myItemCards.length,
                          onPageChanged: (index) {
                            setState(() => _selectedCardIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0.h, horizontal: 4.w),
                              child: RequestManagementItemCardWidget(
                                card: _myItemCards[index],
                                isActive: index == _selectedCardIndex,
                              ),
                            );
                          },
                        ),
                      ),

                      // 페이지 인디케이터
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: _buildPageIndicator(),
                      ),
                    ],
                  )
                :
                  // 카드 선택 완료: 선택한 내 물품 카드만 표시
                  Center(
                    child: RequestManagementItemCardWidget(card: _myItemCards[_selectedCardIndex], isActive: true),
                  ),
          ),

          SizedBox(height: _hasSelectedCard ? 31.h : 23.h),

          // 거래방식 선택 섹션
          TradeRequestTradeOptionSelector(
            selectedOptions: _selectedTradeOptions,
            onChanged: (next) {
              setState(() {
                _selectedTradeOptions
                  ..clear()
                  ..addAll(next);
              });
            },
          ),

          SizedBox(height: _hasSelectedCard ? 24.h : 16.h),

          // 하단 버튼 (취소, 요청하기)
          Row(
            children: [
              // 취소 버튼
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56.h,
                  child: Material(
                    color: cancelButtonColor,
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      highlightColor: cancelButtonHighlightColor,
                      splashColor: cancelButtonSplashColor,
                      child: Center(child: Text('취소', style: CustomTextStyles.p1)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              // 요청하기 버튼
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56.h,
                  child: Material(
                    color: requestButtonColor,
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      onTap: _isSubmitting ? null : _submitTradeRequest,
                      highlightColor: requestButtonHighlightColor,
                      splashColor: requestButtonSplashColor,
                      child: Center(
                        child: _isSubmitting
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: const CircularProgressIndicator(color: AppColors.textColorBlack, strokeWidth: 2),
                              )
                            : Text('요청하기', style: CustomTextStyles.p1.copyWith(color: AppColors.textColorBlack)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 페이지 인디케이터 빌드
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _myItemCards.length,
        (index) => Container(
          width: 8.w,
          height: 8.w,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _selectedCardIndex ? AppColors.primaryYellow : AppColors.opacity30White,
          ),
        ),
      ),
    );
  }
}
