// lib/providers/member_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/states/member_profile_state.dart';

final memberProfileProvider = AsyncNotifierProvider<MemberProfileNotifier, MemberProfileState>(
  MemberProfileNotifier.new,
);

class MemberProfileNotifier extends AsyncNotifier<MemberProfileState> {
  MemberRepository get _repo => ref.read(memberRepositoryProvider);

  @override
  Future<MemberProfileState> build() => _fetch();

  Future<MemberProfileState> _fetch() async {
    final res = await _repo.getMemberInfo();
    return MemberProfileState(member: res.member, location: res.memberLocation);
  }

  /// 서버 재조회. 실패 시 이전 상태를 유지해 화면 blank 방지.
  Future<void> reload() async {
    final next = await AsyncValue.guard(_fetch);
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 프로필 수정 후 자동 갱신.
  /// [nickname], [profileUrl] 모두 필수 (서버 API 요구사항).
  Future<void> updateProfile({required String nickname, required String profileUrl}) async {
    await _repo.updateProfile(nickname: nickname, profileUrl: profileUrl);
    await reload();
  }
}
