import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 홈 피드 조회 전용 repository.
/// 정렬 폴백·페이지네이션·seen 재정렬 같은 도메인 로직은 notifier가 담당한다.
/// 최근 본 물품 id는 회원별로 기기에 저장 (앱 재시작 후에도 유지, #966)
class HomeFeedRepository {
  final ItemApi _api;
  final Future<String?> Function() _readCurrentMemberId;

  HomeFeedRepository(this._api, {Future<String?> Function()? readCurrentMemberId})
    : _readCurrentMemberId = readCurrentMemberId ?? UserInfo().getCurrentMemberId;

  /// 단일 페이지를 단일 정렬 필드로 조회한다.
  /// [recentlySeenItemIds]·[feedSeed]는 한 세션(첫 페이지 ~ 마지막 페이지) 동안 같은 값 (바꾸면 페이지 경계 중복·누락)
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    final res = await _api.getItems(
      ItemRequest(
        pageNumber: pageNumber,
        pageSize: pageSize,
        sortField: sortField.serverName,
        recentlySeenItemIds: recentlySeenItemIds,
        feedSeed: feedSeed,
      ),
    );
    return res.itemPage?.content ?? const <Item>[];
  }

  /// 저장된 최근 본 물품 id (오래된 순, 회원 정보 없음·읽기 실패 시 빈 목록)
  Future<List<String>> loadRecentlySeenItemIds() async {
    try {
      final storageKey = await _buildRecentlySeenStorageKey();
      if (storageKey == null) return const [];
      final preferences = await SharedPreferences.getInstance();
      return preferences.getStringList(storageKey) ?? const [];
    } catch (error) {
      debugPrint('[home feed] recently seen load failed : $error');
      return const [];
    }
  }

  /// 최근 본 물품 id 전체 교체 저장 (오래된 순, [memberId] 키: 기록 시점 회원 > 저장 시점에 로그아웃돼도 같은 회원 키, 실패는 무시)
  Future<void> saveRecentlySeenItemIds(List<String> recentlySeenItemIds, {required String memberId}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_toRecentlySeenStorageKey(memberId), recentlySeenItemIds);
    } catch (error) {
      debugPrint('[home feed] recently seen save failed : $error');
    }
  }

  /// 현재 로그인 회원 ID (없으면 null, 본 물품 기록 시점 저장 키 확정용)
  Future<String?> readCurrentMemberId() => _readCurrentMemberId();

  /// 현재 회원 저장 키 (회원 정보 없음 > null)
  Future<String?> _buildRecentlySeenStorageKey() async {
    final memberId = await _readCurrentMemberId();
    if (memberId == null || memberId.isEmpty) return null;
    return _toRecentlySeenStorageKey(memberId);
  }

  /// 회원별 저장 키: '{key}_{memberId}' (다른 계정으로 로그인 시 기록 분리)
  String _toRecentlySeenStorageKey(String memberId) => '${StorageKeys.homeFeedRecentlySeenItemIds.key}_$memberId';
}
