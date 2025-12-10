import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/enums/item_condition.dart' as item_condtion_enum;
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';

class MyLikeListScreen extends StatefulWidget {
  const MyLikeListScreen({super.key});

  @override
  State<MyLikeListScreen> createState() => _MyLikeListScreenState();
}

class _MyLikeListScreenState extends State<MyLikeListScreen> {
  // TODO : 샘플 데이터: 실제 데이터로 교체하세요
  final List<_LikedItem> _items = [];

  int _currentPage = 0; // next page to request (0-based)
  final int _pageSize = 10;

  bool _isLoading = false;
  bool _hasMoreItems = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadLikeItems(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    const threshold = 200.0;

    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      if (!_isLoading && _hasMoreItems) {
        _loadLikeItems(reset: false);
      }
    }
  }

  /// Like 목록 로드 (reset: true -> 처음부터 다시 로드)
  Future<void> _loadLikeItems({required bool reset}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final pageToRequest = reset ? 0 : _currentPage;
      final itemApi = ItemApi();
      final itemResponse = await itemApi.getLikeList(
        ItemRequest(pageNumber: pageToRequest, pageSize: _pageSize),
      );

      final serverItems = itemResponse.itemPage?.content ?? [];
      final likeItems = await _convertToLikeItems(serverItems);

      if (!mounted) return;

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(likeItems);
        } else {
          _items.addAll(likeItems);
        }

        // 다음에 요청할 페이지
        _currentPage = pageToRequest + 1;

        // 서버가 pageSize보다 적게 보내면 → 더 없음
        _hasMoreItems = serverItems.length == _pageSize;
      });
    } catch (e) {
      debugPrint('사용자 좋아요 목록 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ItemDetail 리스트를 HomeFeedItem 리스트로 변환
  Future<List<_LikedItem>> _convertToLikeItems(List<Item> details) async {
    List<_LikedItem> likeItems = <_LikedItem>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      // 카테고리/상태/옵션 매핑
      ItemCondition cond = ItemCondition.newItem;
      try {
        cond = item_condtion_enum.ItemCondition.values.firstWhere(
          (e) => e.serverName == d.itemCondition,
        );
      } catch (_) {}

      final opts = <ItemTradeOption>[];
      if (d.itemTradeOptions != null) {
        for (final s in d.itemTradeOptions!) {
          try {
            opts.add(
              ItemTradeOption.values.firstWhere((e) => e.serverName == s),
            );
          } catch (_) {}
        }
      }

      // 위치 정보 변환
      String locationText = '미지정';
      if (d.latitude != null && d.longitude != null) {
        final address = await LocationService().getAddressFromCoordinates(
          NLatLng(d.latitude!, d.longitude!),
        );
        if (address != null) {
          locationText =
              '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
        }
      }

      final likeItem = _LikedItem(
        itemId: d.itemId ?? 'unknown_$index',
        heroTag: 'my_like_item_${d.itemId}',
        title: d.itemName ?? '제목 없음',
        location: locationText,
        imageUrl: (d.imageUrlList.isNotEmpty) ? d.imageUrlList.first : '',
        tags: [cond.label, ...opts.map((e) => e.label)],
        isLiked: true,
      );

      likeItems.add(likeItem);
    }

    return likeItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '좋아요 목록',

        showBottomBorder: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: _items.isEmpty && _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length + (_hasMoreItems ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.opacity10White,
                  thickness: 1.5,
                ),
                itemBuilder: (context, index) {
                  // 마지막 인덱스 = 로딩 인디케이터 셀
                  if (_hasMoreItems && index == _items.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ),
                    );
                  }
                  final item = _items[index];

                  return GestureDetector(
                    onTap: () {
                      // TODO: 상세화면 이동
                      context.navigateTo(
                        screen: ItemDetailDescriptionScreen(
                          itemId: item.itemId,
                          imageSize: Size(
                            MediaQuery.of(context).size.width,
                            400.h,
                          ),
                          currentImageIndex: 0,
                          heroTag: 'my_like_item_${item.itemId}',
                          isMyItem: false,
                          isRequestManagement: false,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: const BoxDecoration(
                        color: AppColors.transparent,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 썸네일 (Hero 적용)
                          Hero(
                            tag: item.heroTag,
                            transitionOnUserGestures: true,
                            createRectTween: (begin, end) =>
                                MaterialRectArcTween(begin: begin, end: end),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                width: 70.w,
                                height: 70.w,
                                color: AppColors.opacity10White,
                                child: item.imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.photo_size_select_actual_rounded,
                                        color: AppColors.opacity40White,
                                      )
                                    : Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryYellow,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: CustomTextStyles.p1.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  item.location,
                                  style: CustomTextStyles.p3.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.opacity60White,
                                  ),
                                ),
                                SizedBox(height: 11.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      spacing: 8.w,
                                      runSpacing: 6.h,
                                      children: [
                                        // tags 배열을 (condition, options...) 구조로 가정
                                        if (item.tags.isNotEmpty)
                                          // 첫 번째는 condition
                                          ItemDetailConditionTag(
                                            condition: item.tags.first,
                                          ),
                                        // 나머지는 trade option들
                                        ...item.tags
                                            .skip(1)
                                            .map(
                                              (opt) => ItemDetailTradeOptionTag(
                                                option: opt,
                                              ),
                                            ),
                                      ],
                                    ),
                                    // 좋아요 버튼 (아이콘+원)
                                    GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => item.isLiked = !item.isLiked,
                                        );
                                      },
                                      child: Container(
                                        width: 24.w,
                                        height: 24.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlack,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: item.isLiked
                                                ? Colors.transparent
                                                : AppColors.opacity10White,
                                            width: 1.w,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            item.isLiked
                                                ? AppIcons.itemRegisterHeart
                                                : AppIcons.profilelikecount,
                                            color: AppColors.textColorWhite,
                                            size: 24.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _LikedItem {
  final String itemId;
  final String heroTag;
  final String title;
  final String location;
  final List<String> tags;
  final String imageUrl;
  bool isLiked;

  _LikedItem({
    required this.itemId,
    required this.heroTag,
    required this.title,
    required this.location,
    required this.tags,
    required this.imageUrl,
    required this.isLiked,
  });
}
