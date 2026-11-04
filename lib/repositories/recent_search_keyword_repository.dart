import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 최근 검색어 최대 보관 수
const int maximumRecentSearchKeywordCount = 10;

/// 최근 검색어 목록에 추가: 같은 검색어 제거 후 맨 앞 > 최대 개수 초과분 삭제 (최신 순)
List<String> addRecentSearchKeyword(List<String> recentKeywords, String keyword) {
  final trimmedKeyword = keyword.trim();
  if (trimmedKeyword.isEmpty) return recentKeywords;
  return [
    trimmedKeyword,
    ...recentKeywords.where((recentKeyword) => recentKeyword != trimmedKeyword),
  ].take(maximumRecentSearchKeywordCount).toList();
}

/// 최근 검색어 기기 저장소: 회원별 키 '{key}_{memberId}' (다른 계정 기록 분리), 읽기·쓰기 실패는 무시 (#1008)
class RecentSearchKeywordRepository {
  final Future<String?> Function() _readCurrentMemberId;

  RecentSearchKeywordRepository({Future<String?> Function()? readCurrentMemberId})
    : _readCurrentMemberId = readCurrentMemberId ?? UserInfo().getCurrentMemberId;

  /// 저장된 최근 검색어 (최신 순, 회원 정보 없음·읽기 실패 > 빈 목록)
  Future<List<String>> loadKeywords() async {
    try {
      final storageKey = await _buildStorageKey();
      if (storageKey == null) return const [];
      final preferences = await SharedPreferences.getInstance();
      return preferences.getStringList(storageKey) ?? const [];
    } catch (error) {
      debugPrint('[recent search] load failed : $error');
      return const [];
    }
  }

  /// 최근 검색어 전체 교체 저장 (빈 목록 > 키 삭제)
  Future<void> saveKeywords(List<String> recentKeywords) async {
    try {
      final storageKey = await _buildStorageKey();
      if (storageKey == null) return;
      final preferences = await SharedPreferences.getInstance();
      if (recentKeywords.isEmpty) {
        await preferences.remove(storageKey);
      } else {
        await preferences.setStringList(storageKey, recentKeywords);
      }
    } catch (error) {
      debugPrint('[recent search] save failed : $error');
    }
  }

  Future<String?> _buildStorageKey() async {
    final memberId = await _readCurrentMemberId();
    if (memberId == null || memberId.isEmpty) return null;
    return '${StorageKeys.recentItemSearchKeywords.key}_$memberId';
  }
}
