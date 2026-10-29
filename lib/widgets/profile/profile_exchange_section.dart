import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/screens/my_page/my_register_item_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

class ProfileExchangeSection extends ConsumerStatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;

  const ProfileExchangeSection({super.key, this.memberId, this.onLoaded});

  @override
  ConsumerState<ProfileExchangeSection> createState() => _ProfileExchangeSectionState();
}

class _ProfileExchangeSectionState extends ConsumerState<ProfileExchangeSection> {
  // 타인 프로필 전용 로컬 목록 (본인 프로필은 myItemsProvider 구독)
  List<Item> _memberItems = [];
  bool _isMemberItemsLoading = true;
  bool _calledOnLoaded = false;

  bool get _isMyProfile => widget.memberId == null;

  @override
  void initState() {
    super.initState();
    if (_isMyProfile) {
      // 본인: myItemsProvider 첫 로드 완료 시 onLoaded 알림 (성공·실패 공통)
      ref
          .read(myItemsProvider.future)
          .then((_) {}, onError: (Object error) => debugPrint('내 교환 물건 로드 실패: $error'))
          .whenComplete(_notifyLoaded);
    } else {
      _loadMemberItems();
    }
  }

  void _notifyLoaded() {
    if (_calledOnLoaded) return;
    _calledOnLoaded = true;
    widget.onLoaded?.call();
  }

  /// 타인 교환 물건 로드
  Future<void> _loadMemberItems() async {
    try {
      final res = await ItemApi().getMemberItems(ItemRequest(memberId: widget.memberId));
      final List<Item> items = res.itemPage?.content ?? [];
      await Future.wait(items.map((item) => item.resolveAndCacheAddress()));
      if (mounted) {
        setState(() {
          _memberItems = items;
          _isMemberItemsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('타인 교환 물건 로드 실패: $e');
      if (mounted) setState(() => _isMemberItemsLoading = false);
    } finally {
      _notifyLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 표시 목록: 본인 > myItemsProvider(판매중 + 거래완료), 타인 > 로컬 조회 결과
    final List<Item> items;
    final bool isLoading;
    final bool hasLoadErrorWithoutItems;
    if (_isMyProfile) {
      final myItemsAsync = ref.watch(myItemsProvider);
      final myItems = myItemsAsync.valueOrNull;
      isLoading = myItems == null && myItemsAsync.isLoading;
      // 첫 로드 실패 + 이전 값 없음 > 실패 문구 (재시도는 섹션 탭 > 등록 물품 화면)
      hasLoadErrorWithoutItems = myItems == null && myItemsAsync.hasError;
      items = myItems == null ? const <Item>[] : [...myItems.available, ...myItems.exchanged];
    } else {
      items = _memberItems;
      isLoading = _isMemberItemsLoading;
      hasLoadErrorWithoutItems = false;
    }

    return AppPressable(
      onTap: () {
        if (!_isMyProfile) return; // 타인 프로필에서는 등록 화면 진입 막기
        context.navigateTo(screen: const MyRegisterItemScreen());
      },
      child: Container(
        padding: EdgeInsets.only(left: 16.w, top: 16.h, bottom: 20.h),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('교환 물품', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
                Padding(
                  padding: EdgeInsets.only(right: 16.0.w),
                  child: Icon(AppIcons.detailView, size: 16.w, color: AppColors.opacity30White),
                ),
              ],
            ),
            SizedBox(height: 19.h),
            _buildContent(items: items, isLoading: isLoading, hasLoadErrorWithoutItems: hasLoadErrorWithoutItems),
          ],
        ),
      ),
    );
  }

  /// 교환 물건 목록 > 로딩·실패·빈 상태·가로 목록
  Widget _buildContent({required List<Item> items, required bool isLoading, required bool hasLoadErrorWithoutItems}) {
    if (isLoading) {
      return SizedBox(
        height: 163.w,
        child: const Center(child: CommonLoadingIndicator()),
      );
    }

    if (hasLoadErrorWithoutItems) {
      return _buildCenterMessage('교환 물품을 불러오지 못했어요.');
    }

    if (items.isEmpty) {
      return _buildCenterMessage('등록된 교환 물품이 없습니다.');
    }

    return SizedBox(
      height: 163.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (_, index) => _buildItemCard(items[index]),
      ),
    );
  }

  /// 목록 자리 중앙 안내 문구 (빈 상태·실패 공통)
  Widget _buildCenterMessage(String message) {
    return SizedBox(
      height: 163.w,
      child: Center(
        child: Text(message, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final imageUrl = item.primaryImageUrl ?? '';
    final name = item.itemName ?? '';
    final price = item.price;
    final location = item.displayLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: SizedBox(
            width: 100.w,
            height: 100.w,
            child: imageUrl.isEmpty
                ? Container(color: AppColors.opacity10White)
                : Stack(
                    children: [
                      CachedImage(imageUrl: imageUrl, fit: BoxFit.cover, width: 100.w, height: 100.w),

                      // 거래완료인 물품만 표시
                      if (item.itemStatus == ItemStatus.exchanged.serverName)
                        Positioned(
                          bottom: 4.h,
                          right: 4.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 4.5.h),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBlack1,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text('거래완료', style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500)),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: 100.w,
          child: Text(
            name,
            style: CustomTextStyles.p1.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 8.h),
        Text(price != null ? '${formatPrice(price)}원' : '가격 미정', style: CustomTextStyles.p2),
        SizedBox(height: 6.h),
        SizedBox(
          width: 100.w,
          child: Text(
            location,
            style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
