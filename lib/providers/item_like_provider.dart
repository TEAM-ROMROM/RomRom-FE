/// 좋아요(Like) Provider (CLAUDE.md 규칙2 — optimistic 토글)
///
/// 종류: 동기 Notifier (optimistic + _inFlight dedup) — 즉시 반영 후 서버 응답으로 확정, 실패 시 prev 롤백.
/// 4-레이어 표준: lib/repositories/item_repository.dart + lib/providers/item_repository_provider.dart
///               + lib/states/item_like_state.dart + 이 파일.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/states/item_like_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final itemLikeProvider = NotifierProvider<ItemLikeNotifier, Map<String, ItemLikeState>>(ItemLikeNotifier.new);

class ItemLikeNotifier extends Notifier<Map<String, ItemLikeState>> {
  final Set<String> _inFlight = <String>{};

  /// itemId별 "마지막 클릭 의도(isLiked)". 요청 진행 중 들어온 연타를 버리지 않고
  /// 여기에 최종 의도만 덮어쓴 뒤, 요청 완료 시점에 서버 결과와 비교해 1회만 보정한다.
  final Map<String, bool> _pendingIntent = <String, bool>{};

  @override
  Map<String, ItemLikeState> build() => const {};

  /// 캐시 시드. 이미 키가 있으면 [force]가 true가 아닐 때 덮어쓰지 않는다.
  void seed({required String itemId, required bool isLiked, required int likeCount, bool force = false}) {
    if (!force && state.containsKey(itemId)) return;
    state = {...state, itemId: ItemLikeState(isLiked: isLiked, likeCount: likeCount)};
  }

  /// Optimistic 토글. 시드 안 된 경우 silently return.
  ///
  /// [authorMemberId]가 주어지면 본인 게시글 여부를 캐시된 내 ID로 **동기** 판단해
  /// (await 없이) 본인글이면 차단한다 — UI 반응 지연 방지. null이면 체크를 건너뛴다.
  Future<void> toggle(String itemId, {String? authorMemberId}) async {
    // 본인 게시글 차단: cachedMemberId는 메모리 값이라 await 없이 즉시 비교 가능
    final myId = MemberManager.cachedMemberId;
    if (myId != null && authorMemberId != null && myId == authorMemberId) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: '본인 게시글에는 좋아요를 누를 수 없습니다.', type: SnackBarType.error);
      }
      return;
    }

    final prev = state[itemId];
    if (prev == null) return;

    // 요청 진행 중이면 버리지 않고 마지막 의도만 큐잉 + UI 즉시 반영
    if (_inFlight.contains(itemId)) {
      final intent = !prev.isLiked;
      _pendingIntent[itemId] = intent;
      state = {
        ...state,
        itemId: prev.copyWith(
          isLiked: intent,
          likeCount: prev.isLiked ? max(prev.likeCount - 1, 0) : prev.likeCount + 1,
        ),
      };
      return;
    }

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
      // 롤백했으므로 큐잉된 의도도 폐기 (서버와 동기화 못 한 상태에서 보정하면 어긋남)
      _pendingIntent.remove(itemId);
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: '좋아요 처리에 실패했어요', type: SnackBarType.error);
      }
    } finally {
      _inFlight.remove(itemId);
    }

    // 요청 중 연타가 있었다면, 서버 확정값과 마지막 의도가 다를 때만 1회 보정
    if (_pendingIntent.containsKey(itemId)) {
      final intent = _pendingIntent.remove(itemId);
      final confirmed = state[itemId]?.isLiked;
      if (confirmed != null && intent != null && intent != confirmed) {
        // 본인글 체크는 첫 호출에서 통과했으므로 재귀 보정엔 authorMemberId 생략
        await toggle(itemId);
      }
    }
  }
}
