import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/my_page/my_register_item_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

class ProfileExchangeSection extends StatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;

  const ProfileExchangeSection({super.key, this.memberId, this.onLoaded});

  @override
  State<ProfileExchangeSection> createState() => _ProfileExchangeSectionState();
}

class _ProfileExchangeSectionState extends State<ProfileExchangeSection> {
  List<Item> _items = [];
  bool _isLoading = true;
  bool _calledOnLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  void _notifyLoaded() {
    if (_calledOnLoaded) return;
    _calledOnLoaded = true;
    widget.onLoaded?.call();
  }

  /// 내 교환 물건 로드
  Future<void> _loadMyItems() async {
    try {
      final List<Item> items;
      if (widget.memberId != null) {
        final res = await ItemApi().getMemberItems(ItemRequest(memberId: widget.memberId));
        items = res.itemPage?.content ?? [];
      } else {
        final (availableRes, exchangedRes) = await (
          ItemApi().getMyItems(ItemRequest(itemStatus: ItemStatus.available.serverName, pageNumber: 0, pageSize: 20)),
          ItemApi().getMyItems(ItemRequest(itemStatus: ItemStatus.exchanged.serverName, pageNumber: 0, pageSize: 20)),
        ).wait;
        items = <Item>[...availableRes.itemPage?.content ?? [], ...exchangedRes.itemPage?.content ?? []];
      }
      await Future.wait(items.map((item) => item.resolveAndCacheAddress()));
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('내 교환 물건 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _notifyLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: () {
        if (widget.memberId != null) return; // 타인 프로필에서는 등록 화면 진입 막기
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
                Text('교환 물건', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
                Padding(
                  padding: EdgeInsets.only(right: 16.0.w),
                  child: Icon(AppIcons.detailView, size: 16.w, color: AppColors.opacity30White),
                ),
              ],
            ),
            SizedBox(height: 19.h),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  /// 내 물품 목록 조회 API 호출 결과에 따른 콘텐츠 빌드
  Widget _buildContent() {
    if (_isLoading) {
      return SizedBox(
        height: 163.w,
        child: const Center(child: CommonLoadingIndicator()),
      );
    }

    if (_items.isEmpty) {
      return SizedBox(
        height: 163.w,
        child: Center(
          child: Text('등록된 교환 물건이 없습니다.', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
        ),
      );
    }

    return SizedBox(
      height: 163.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (_, index) => _buildItemCard(_items[index]),
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
