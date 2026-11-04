import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/item_search_query.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/states/item_search_state.dart';

/// 물품 검색 결과 단일 소유 provider (검색 화면 전용, 화면 닫으면 해제) (#1008)
final itemSearchProvider = AsyncNotifierProvider.autoDispose<ItemSearchNotifier, ItemSearchState>(
  ItemSearchNotifier.new,
);

/// 검색 결과 한 페이지 크기 (서버 최대 50)
const int itemSearchPageSize = 20;

/// 물품 검색: 새 조건 검색(첫 페이지), 다음 페이지, 같은 조건 다시 시도
/// 조건 교체 세대로 늦게 도착한 이전 조건 응답 폐기
class ItemSearchNotifier extends AutoDisposeAsyncNotifier<ItemSearchState> {
  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  // 검색 세대 (새 검색마다 증가 > 이전 검색의 늦은 응답 폐기)
  int _searchGeneration = 0;

  @override
  Future<ItemSearchState> build() async {
    _searchGeneration++;
    // 화면 닫힘(해제) 뒤 도착한 응답 폐기
    ref.onDispose(() => _searchGeneration++);
    return const ItemSearchState();
  }

  /// 새 조건 검색: 로딩 > 첫 페이지 (실패 > 에러 상태, 화면 다시 시도)
  Future<void> search(ItemSearchQuery searchQuery) async {
    final generation = ++_searchGeneration;
    state = const AsyncLoading<ItemSearchState>();
    final next = await AsyncValue.guard(() async {
      final firstPage = await _repository.searchItemsPage(searchQuery, pageNumber: 0, pageSize: itemSearchPageSize);
      return ItemSearchState(
        searchQuery: searchQuery,
        items: firstPage.items,
        nextPageNumber: 1,
        hasMore: firstPage.hasMore,
      );
    });
    if (generation != _searchGeneration) return;
    if (next.hasError) debugPrint('[item search] search failed : ${next.error}');
    state = next;
  }

  /// 다음 페이지: 남은 페이지·진행 중 확인 > 조회 > 뒤에 추가 (실패 > 목록 유지 + 실패 표시)
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final searchQuery = current?.searchQuery;
    if (current == null || searchQuery == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _searchGeneration;
    state = AsyncData(current.copyWith(isLoadingMore: true, hasNextPageError: false));
    try {
      final nextPage = await _repository.searchItemsPage(
        searchQuery,
        pageNumber: current.nextPageNumber,
        pageSize: itemSearchPageSize,
      );
      if (generation != _searchGeneration) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...nextPage.items],
          nextPageNumber: current.nextPageNumber + 1,
          hasMore: nextPage.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (generation != _searchGeneration) return;
      debugPrint('[item search] load more failed : $error');
      state = AsyncData(current.copyWith(isLoadingMore: false, hasNextPageError: true));
    }
  }
}
