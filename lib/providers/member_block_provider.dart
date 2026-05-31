// 회원 차단(Block) Provider (CLAUDE.md 규칙2 — optimistic 토글)
//
// 종류: 동기 Notifier (optimistic + _inFlight dedup) — 즉시 반영 후 서버 응답으로 확정, 실패 시 prev 롤백.
// 4-레이어 표준: lib/repositories/member_block_repository.dart + memberBlockRepositoryProvider(이 파일)
//               + lib/states/member_block_state.dart + 이 파일.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/states/member_block_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final memberBlockRepositoryProvider = Provider<MemberBlockRepository>((ref) => MemberBlockRepository(MemberApi()));

final memberBlockProvider = NotifierProvider<MemberBlockNotifier, MemberBlockState>(MemberBlockNotifier.new);

class MemberBlockNotifier extends Notifier<MemberBlockState> {
  final Set<String> _inFlight = <String>{};

  @override
  MemberBlockState build() => const MemberBlockState();

  /// 차단 목록 시드. force=false일 땐 비어있을 때만 시드.
  void seed(Set<String> ids, {bool force = false}) {
    if (!force && state.blockedIds.isNotEmpty) return;
    state = MemberBlockState(blockedIds: {...ids});
  }

  /// Optimistic 차단/차단해제 토글.
  Future<void> setBlocked(String memberId, bool block) async {
    if (_inFlight.contains(memberId)) return;
    _inFlight.add(memberId);

    final prev = state;
    final newIds = {...state.blockedIds};
    if (block) {
      newIds.add(memberId);
    } else {
      newIds.remove(memberId);
    }
    state = MemberBlockState(blockedIds: newIds);

    try {
      final repo = ref.read(memberBlockRepositoryProvider);
      final ok = block ? await repo.block(memberId) : await repo.unblock(memberId);
      if (!ok) throw Exception('서버 응답이 false');
    } catch (e) {
      debugPrint('memberBlockProvider.setBlocked 실패: $e');
      state = prev;
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: block ? '차단에 실패했어요' : '차단 해제에 실패했어요', type: SnackBarType.error);
      }
    } finally {
      _inFlight.remove(memberId);
    }
  }
}
