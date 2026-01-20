import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import 'package:romrom_fe/widgets/trade_request_target_preview.dart';

/// 요청하기 화면 (2단계)
/// 1단계: 내 물품 카드 선택
/// 2단계: 거래방식 선택 및 요청 전송
class TradeRequestScreen extends StatefulWidget {
  /// 교환 대상 물품 (상대방 물품)
  final Item targetItem;

  /// 교환 대상 물품 이미지 URL
  final String? targetImageUrl;

  /// 홈탭에서 스와이프한 카드 ID (선택사항)
  /// 이 값이 있으면 해당 카드를 자동 선택하고 2단계로 시작
  final String? preSelectedCardId;

  const TradeRequestScreen({
    super.key,
    required this.targetItem,
    this.targetImageUrl,
    this.preSelectedCardId,
  });

  @override
  State<TradeRequestScreen> createState() => _TradeRequestScreenState();
}

class _TradeRequestScreenState extends State<TradeRequestScreen> {
  /// 현재 단계 (1: 카드 선택, 2: 거래방식 선택)
  int _currentStep = 1;

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
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.6,
    );
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
        ItemRequest(
          pageNumber: 0,
          pageSize: 20,
          itemStatus: ItemStatus.available.serverName,
        ),
      );

      if (!mounted) return;

      final items = response.itemPage?.content ?? [];
      final cards = _convertToItemCards(items);

      setState(() {
        _myItems = items;
        _myItemCards = cards;
        _isLoading = false;
      });

      // preSelectedCardId가 있으면 해당 카드 찾아서 선택 후 2단계로 이동
      if (widget.preSelectedCardId != null && items.isNotEmpty) {
        final preSelectedIndex = items.indexWhere(
          (item) => item.itemId == widget.preSelectedCardId,
        );
        if (preSelectedIndex >= 0) {
          setState(() {
            _selectedCardIndex = preSelectedIndex;
            _currentStep = 2;
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

      CommonSnackBar.show(
        context: context,
        message: '물품 목록을 불러오는데 실패했습니다.',
        type: SnackBarType.error,
      );
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
      CommonSnackBar.show(
        context: context,
        message: '거래방식을 선택해주세요.',
        type: SnackBarType.info,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await TradeApi().requestTrade(
        TradeRequest(
          takeItemId: widget.targetItem.itemId,
          giveItemId: _myItems[_selectedCardIndex].itemId,
          itemTradeOptions:
              _selectedTradeOptions.map((o) => o.serverName).toList(),
        ),
      );

      if (!mounted) return;

      CommonSnackBar.show(
        context: context,
        message: '거래 요청이 전송되었습니다.',
        type: SnackBarType.success,
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('거래 요청 실패: $e');
      if (!mounted) return;

      final errorMessage = ErrorUtils.getErrorMessage(e);

      await CommonModal.error(
        context: context,
        message: errorMessage,
        onConfirm: () => Navigator.of(context).pop(),
      );
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
        final condition =
            ItemCondition.fromServerName(widget.targetItem.itemCondition!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textColorWhite),
          onPressed: () {
            if (_currentStep == 2 && widget.preSelectedCardId == null) {
              // 2단계에서 뒤로가기 시 1단계로 이동 (preSelectedCard가 없는 경우에만)
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          '요청하기',
          style: CustomTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryYellow),
            )
          : _myItemCards.isEmpty
              ? _buildEmptyState()
              : _currentStep == 1
                  ? _buildStep1()
                  : _buildStep2(),
    );
  }

  /// 빈 상태 UI (내 물품이 없을 때)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64.sp,
              color: AppColors.opacity50White,
            ),
            SizedBox(height: 16.h),
            Text(
              '등록된 물품이 없습니다',
              style: CustomTextStyles.h3.copyWith(
                color: AppColors.opacity80White,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '교환 요청을 하려면 먼저\n물품을 등록해주세요.',
              style: CustomTextStyles.p2.copyWith(
                color: AppColors.opacity50White,
              ),
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
    );
  }

  /// 1단계: 내 카드 선택
  Widget _buildStep1() {
    return Column(
      children: [
        // 교환 대상 물품 미리보기
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: TradeRequestTargetPreview(
            imageUrl: widget.targetImageUrl,
            itemName: widget.targetItem.itemName ?? '물품',
            tags: _getTargetItemTags(),
          ),
        ),

        // 내 물품 카드 PageView
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _myItemCards.length,
                  onPageChanged: (index) {
                    setState(() => _selectedCardIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return RequestManagementItemCardWidget(
                      card: _myItemCards[index],
                      isActive: index == _selectedCardIndex,
                    );
                  },
                ),
              ),

              // 페이지 인디케이터
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: _buildPageIndicator(),
              ),
            ],
          ),
        ),

        // 하단 "다음" 버튼
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 49.h),
          child: CustomFloatingButton(
            isEnabled: true,
            enabledOnPressed: () {
              setState(() => _currentStep = 2);
            },
            buttonText: '다음',
            buttonWidth: 346,
            buttonHeight: 56,
          ),
        ),
      ],
    );
  }

  /// 2단계: 거래방식 선택 및 요청
  Widget _buildStep2() {
    return Column(
      children: [
        // 교환 대상 물품 미리보기
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: TradeRequestTargetPreview(
            imageUrl: widget.targetImageUrl,
            itemName: widget.targetItem.itemName ?? '물품',
            tags: _getTargetItemTags(),
          ),
        ),

        // 선택한 내 물품 카드 (1개만)
        Expanded(
          child: Center(
            child: RequestManagementItemCardWidget(
              card: _myItemCards[_selectedCardIndex],
              isActive: true,
            ),
          ),
        ),

        // 거래방식 선택 섹션
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.secondaryBlack1,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '거래방식 선택',
                style: CustomTextStyles.p2.copyWith(
                  color: AppColors.opacity80White,
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: ItemTradeOption.values.map((option) {
                  final isSelected = _selectedTradeOptions.contains(option);
                  return _buildTradeOptionChip(option, isSelected);
                }).toList(),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // 하단 버튼 (취소, 요청하기)
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 49.h),
          child: Row(
            children: [
              // 취소 버튼
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56.h,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          AppColors.transactionRequestDialogCancelButton,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: CustomTextStyles.p1.copyWith(
                        color: AppColors.textColorBlack,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // 요청하기 버튼
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56.h,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _submitTradeRequest,
                    style: TextButton.styleFrom(
                      backgroundColor: _isSubmitting
                          ? AppColors.primaryYellow.withValues(alpha: 0.5)
                          : AppColors.primaryYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              color: AppColors.textColorBlack,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '요청하기',
                            style: CustomTextStyles.p1.copyWith(
                              color: AppColors.textColorBlack,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: index == _selectedCardIndex
                ? AppColors.primaryYellow
                : AppColors.opacity30White,
          ),
        ),
      ),
    );
  }

  /// 거래방식 칩 빌드
  Widget _buildTradeOptionChip(ItemTradeOption option, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTradeOptions.remove(option);
          } else {
            _selectedTradeOptions.add(option);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : AppColors.secondaryBlack2,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Text(
          option.label,
          style: CustomTextStyles.p3.copyWith(
            color: isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
