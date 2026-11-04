import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/recent_search_keywords_provider.dart';
import 'package:romrom_fe/repositories/recent_search_keyword_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 최근 검색어: 맨 앞 추가·중복 제거·최대 10개, 회원별 저장·빈 목록 삭제 (#1008)
void main() {
  group('addRecentSearchKeyword', () {
    test('새 검색어 맨 앞, 같은 검색어는 앞으로 이동 (앞뒤 공백 제거)', () {
      expect(addRecentSearchKeyword(['신발', '가방'], ' 가방 '), ['가방', '신발']);
      expect(addRecentSearchKeyword(['신발'], '책'), ['책', '신발']);
    });

    test('빈 검색어 > 그대로', () {
      expect(addRecentSearchKeyword(['신발'], '   '), ['신발']);
    });

    test('최대 10개 초과분은 오래된 것부터 삭제', () {
      final recentKeywords = [for (var index = 0; index < maximumRecentSearchKeywordCount; index++) '검색어$index'];
      final updatedKeywords = addRecentSearchKeyword(recentKeywords, '새 검색어');
      expect(updatedKeywords.length, maximumRecentSearchKeywordCount);
      expect(updatedKeywords.first, '새 검색어');
      expect(updatedKeywords.contains('검색어${maximumRecentSearchKeywordCount - 1}'), isFalse);
    });
  });

  group('RecentSearchKeywordRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('회원별 키 분리 저장·조회', () async {
      final firstMemberRepository = RecentSearchKeywordRepository(readCurrentMemberId: () async => 'member-a');
      final secondMemberRepository = RecentSearchKeywordRepository(readCurrentMemberId: () async => 'member-b');

      await firstMemberRepository.saveKeywords(['신발']);

      expect(await firstMemberRepository.loadKeywords(), ['신발']);
      expect(await secondMemberRepository.loadKeywords(), isEmpty);
    });

    test('빈 목록 저장 > 키 삭제, 회원 정보 없음 > 저장 안 함', () async {
      final repository = RecentSearchKeywordRepository(readCurrentMemberId: () async => 'member-a');
      await repository.saveKeywords(['신발']);
      await repository.saveKeywords(const []);
      expect(await repository.loadKeywords(), isEmpty);

      final signedOutRepository = RecentSearchKeywordRepository(readCurrentMemberId: () async => null);
      await signedOutRepository.saveKeywords(['책']);
      expect(await signedOutRepository.loadKeywords(), isEmpty);
    });
  });

  group('recentSearchKeywordsProvider', () {
    test('불러오기 전 추가 > 저장된 기록 유지 후 맨 앞 추가, 전체 삭제', () async {
      SharedPreferences.setMockInitialValues({
        'recentItemSearchKeywords_member-a': ['신발'],
      });
      final container = ProviderContainer(
        overrides: [
          recentSearchKeywordRepositoryProvider.overrideWithValue(
            RecentSearchKeywordRepository(readCurrentMemberId: () async => 'member-a'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(recentSearchKeywordsProvider.notifier).add('가방');
      expect(container.read(recentSearchKeywordsProvider).valueOrNull, ['가방', '신발']);

      await container.read(recentSearchKeywordsProvider.notifier).clear();
      expect(container.read(recentSearchKeywordsProvider).valueOrNull, isEmpty);
    });
  });
}
