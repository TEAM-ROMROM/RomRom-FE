/// 좋아요(Like) Provider (CLAUDE.md 규칙2 — optimistic 토글)
///
/// 종류: 동기 Notifier (optimistic + _inFlight dedup) — 즉시 반영 후 서버 응답으로 확정, 실패 시 prev 롤백.
/// 4-레이어 표준: lib/repositories/item_repository.dart + lib/providers/item_repository_provider.dart
///               + lib/states/item_like_state.dart + 이 파일.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/states/item_like_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final itemLikeProvider = NotifierProvider<ItemLikeNotifier, Map<String, ItemLikeState>>(ItemLikeNotifier.new);

class ItemLikeNotifier extends Notifier<Map<String, ItemLikeState>> {
  final Set<String> _inFlight = <String>{};

  @override
  Map<String, ItemLikeState> build() => const {};

  /// 캐시 시드. 이미 키가 있으면 [force]가 true가 아닐 때 덮어쓰지 않는다.
  void seed({required String itemId, required bool isLiked, required int likeCount, bool force = false}) {
    if (!force && state.containsKey(itemId)) return;
    state = {...state, itemId: ItemLikeState(isLiked: isLiked, likeCount: likeCount)};
  }

  /// Optimistic 토글. 시드 안 된 경우 silently return.
  Future<void> toggle(String itemId) async {
    if (_inFlight.contains(itemId)) return;
    final prev = state[itemId];
    if (prev == null) return;

    _inFlight.add(itemId);

    final optimistic = prev.copyWith(
      isLiked: !prev.isLiked,
      likeCount: prev.isLiked ? max(prev.likeCount - 1, 0) : prev.likeCount + 1,
    );
    state = {...state, itemId: optimistic};

    try {
      final repo = ref.read(itemRepositoryProvider);
      final res = await repo.postLike(itemId);
      state = {
        ...state,
        itemId: ItemLikeState(isLiked: res.isLiked == true, likeCount: res.item?.likeCount ?? optimistic.likeCount),
      };
    } catch (e) {
      debugPrint('itemLikeProvider.toggle 실패: $e');
      state = {...state, itemId: prev};
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: '좋아요 처리에 실패했어요', type: SnackBarType.error);
      }
    } finally {
      _inFlight.remove(itemId);
    }
  }
}
