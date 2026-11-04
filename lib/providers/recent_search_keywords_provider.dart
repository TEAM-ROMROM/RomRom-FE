import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/recent_search_keyword_repository.dart';

/// 최근 검색어 저장소 주입 (테스트 override)
final recentSearchKeywordRepositoryProvider = Provider<RecentSearchKeywordRepository>(
  (ref) => RecentSearchKeywordRepository(),
);

/// 물품 검색 최근 검색어 (최신 순, 최대 10개, 기기·회원별 저장) (#1008)
final recentSearchKeywordsProvider = AsyncNotifierProvider<RecentSearchKeywordsNotifier, List<String>>(
  RecentSearchKeywordsNotifier.new,
);

/// 최근 검색어: 불러오기, 추가(맨 앞·중복 제거), 하나 삭제, 전체 삭제 (변경 즉시 반영 후 저장)
class RecentSearchKeywordsNotifier extends AsyncNotifier<List<String>> {
  RecentSearchKeywordRepository get _repository => ref.read(recentSearchKeywordRepositoryProvider);

  @override
  Future<List<String>> build() => _repository.loadKeywords();

  Future<void> add(String keyword) async => _replaceKeywords(addRecentSearchKeyword(await _loadedKeywords(), keyword));

  Future<void> remove(String keyword) async =>
      _replaceKeywords((await _loadedKeywords()).where((recentKeyword) => recentKeyword != keyword).toList());

  Future<void> clear() => _replaceKeywords(const []);

  /// 저장소 불러오기 완료 후 현재 목록 (불러오기 전 추가로 기존 기록을 덮어쓰지 않게)
  Future<List<String>> _loadedKeywords() async {
    try {
      return await future;
    } catch (_) {
      return state.valueOrNull ?? const [];
    }
  }

  Future<void> _replaceKeywords(List<String> recentKeywords) async {
    state = AsyncData(recentKeywords);
    await _repository.saveKeywords(recentKeywords);
  }
}
