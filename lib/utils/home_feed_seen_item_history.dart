import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// 본 물품 id 저장 함수 (오래된 순 목록, 저장할 회원 키)
typedef SaveSeenItemIds = Future<void> Function(List<String> seenItemIds, {required String memberId});

/// 홈 피드 본 물품 기록: 최근 [maximumSeenItemCount]개 LRU (오래된 순), 기기 저장은 묶음 1회
/// 첫 기록 후 [saveDelay] 뒤 저장, 앱 비활성·탭 이탈·세션 초기화 때는 [flush]로 즉시 저장
/// 저장 키 = 묶음 첫 기록 시점 회원 (세션 만료로 저장 시점 회원 정보가 비어도 유실 없음), 처음 저장한 회원 외 키에는 쓰지 않음
class HomeFeedSeenItemHistory {
  HomeFeedSeenItemHistory({
    required SaveSeenItemIds saveSeenItemIds,
    required Future<String?> Function() readCurrentMemberId,
    Iterable<String> restoredSeenItemIds = const [],
    this.saveDelay = defaultSaveDelay,
  }) : _saveSeenItemIds = saveSeenItemIds,
       _readCurrentMemberId = readCurrentMemberId {
    _seenItemIds.addAll(restoredSeenItemIds);
    _removeOverflow();
  }

  // 최근 본 물품 최대 보관 수 (서버 요청 recentlySeenItemIds 상한과 동일)
  static const int maximumSeenItemCount = 100;
  // 첫 기록 후 저장까지 묶는 시간
  static const Duration defaultSaveDelay = Duration(seconds: 2);

  final Duration saveDelay;
  final SaveSeenItemIds _saveSeenItemIds;
  final Future<String?> Function() _readCurrentMemberId;
  final LinkedHashSet<String> _seenItemIds = LinkedHashSet<String>();
  Timer? _scheduledSaveTimer;
  bool _hasUnsavedChanges = false;
  // 이번 묶음 첫 기록 시점에 읽은 회원 ID (저장 키)
  Future<String?>? _batchMemberIdFuture;
  // 처음 저장한 회원 ID (이후 다른 회원 키 덮어쓰기 방지)
  String? _ownerMemberId;

  /// 본 물품 id (오래된 순, 읽기 전용)
  Set<String> get seenItemIds => UnmodifiableSetView(_seenItemIds);

  /// 최근 본 순 스냅샷 (서버 요청용)
  List<String> toRecentFirstList() => List.unmodifiable(_seenItemIds.toList().reversed);

  /// 본 물품 기록: 이미 있으면 최근으로 이동 > 최대치 초과분 제거 > 묶음 첫 기록이면 회원 ID 읽기 > 저장 예약 (예약 중이면 그대로)
  void markSeen(String itemId) {
    _seenItemIds
      ..remove(itemId)
      ..add(itemId);
    _removeOverflow();
    _hasUnsavedChanges = true;
    _batchMemberIdFuture ??= _readMemberIdOrNull();
    _scheduledSaveTimer ??= Timer(saveDelay, () {
      _scheduledSaveTimer = null;
      unawaited(_saveIfChanged());
    });
  }

  /// 예약 취소 > 저장할 변경 있으면 즉시 저장
  Future<void> flush() {
    _scheduledSaveTimer?.cancel();
    _scheduledSaveTimer = null;
    return _saveIfChanged();
  }

  /// 묶음 저장: 스냅샷·회원 ID 확정 > 회원 없음·다른 회원이면 건너뜀 > 저장
  Future<void> _saveIfChanged() async {
    final batchMemberIdFuture = _batchMemberIdFuture;
    if (!_hasUnsavedChanges || batchMemberIdFuture == null) return;
    _hasUnsavedChanges = false;
    _batchMemberIdFuture = null;
    final seenItemIdsSnapshot = _seenItemIds.toList();

    final memberId = await batchMemberIdFuture;
    if (memberId == null || memberId.isEmpty) {
      debugPrint('[home feed] recently seen save skipped : no member');
      return;
    }
    final ownerMemberId = _ownerMemberId ??= memberId;
    if (memberId != ownerMemberId) {
      debugPrint('[home feed] recently seen save skipped : member changed');
      return;
    }
    await _saveSeenItemIds(seenItemIdsSnapshot, memberId: memberId);
  }

  /// 회원 ID 읽기 (실패 > null, 저장 건너뜀)
  Future<String?> _readMemberIdOrNull() async {
    try {
      return await _readCurrentMemberId();
    } catch (error) {
      debugPrint('[home feed] recently seen member read failed : $error');
      return null;
    }
  }

  void _removeOverflow() {
    while (_seenItemIds.length > maximumSeenItemCount) {
      _seenItemIds.remove(_seenItemIds.first);
    }
  }
}
