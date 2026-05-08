import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final memberBlockRepositoryProvider = Provider<MemberBlockRepository>((ref) => MemberBlockRepository(MemberApi()));

final memberBlockProvider = NotifierProvider<MemberBlockNotifier, Set<String>>(MemberBlockNotifier.new);

class MemberBlockNotifier extends Notifier<Set<String>> {
  final Set<String> _inFlight = <String>{};

  @override
  Set<String> build() => <String>{};

  /// 차단 목록 시드. force=false일 땐 비어있을 때만 시드.
  void seed(Set<String> ids, {bool force = false}) {
    if (!force && state.isNotEmpty) return;
    state = {...ids};
  }

  /// Optimistic 차단/차단해제 토글.
  Future<void> setBlocked(String memberId, bool block) async {
    if (_inFlight.contains(memberId)) return;
    _inFlight.add(memberId);

    final wasBlocked = state.contains(memberId);
    state = block ? {...state, memberId} : (state.toSet()..remove(memberId));

    try {
      final repo = ref.read(memberBlockRepositoryProvider);
      final ok = block ? await repo.block(memberId) : await repo.unblock(memberId);
      if (!ok) throw Exception('서버 응답이 false');
    } catch (e) {
      debugPrint('memberBlockProvider.setBlocked 실패: $e');
      state = wasBlocked ? {...state, memberId} : (state.toSet()..remove(memberId));
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: block ? '차단에 실패했어요' : '차단 해제에 실패했어요', type: SnackBarType.error);
      }
    } finally {
      _inFlight.remove(memberId);
    }
  }
}
