// lib/providers/member_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/states/member_profile_state.dart';

final memberProfileProvider = AsyncNotifierProvider<MemberProfileNotifier, MemberProfileState>(
  MemberProfileNotifier.new,
);

/// 본인 회원 정보 단일 소유: 조회, 프로필·카테고리·위치·탐색 범위·약관 변경
/// 변경 메서드: repository 호출 > 성공 시 서버 재조회(reload)
class MemberProfileNotifier extends AsyncNotifier<MemberProfileState> {
  MemberRepository get _repo => ref.read(memberRepositoryProvider);

  @override
  Future<MemberProfileState> build() => _fetch();

  Future<MemberProfileState> _fetch() async {
    final res = await _repo.getMemberInfo();
    return MemberProfileState(
      member: res.member,
      location: res.memberLocation,
      itemCategories: res.memberItemCategories,
    );
  }

  /// 서버 재조회. 실패 시 이전 상태를 유지해 화면 blank 방지.
  Future<void> reload() async {
    final next = await AsyncValue.guard(_fetch);
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 서버 최신값 조회 후 반환 (설정 화면 진입용, 실패 시 이전 상태 유지 + 예외 전달)
  Future<MemberProfileState> fetchLatest() async {
    await reload();
    final latestState = state;
    if (latestState.hasError) Error.throwWithStackTrace(latestState.error!, latestState.stackTrace!);
    return latestState.requireValue;
  }

  /// 캐시된 프로필 반환 (조회 실패 상태면 재조회, 재조회도 실패 시 예외)
  Future<MemberProfileState> fetchCachedOrReload() async {
    if (state.hasError) return fetchLatest();
    return future;
  }

  /// 프로필 수정 후 자동 갱신.
  /// [nickname], [profileUrl] 모두 필수 (서버 API 요구사항).
  Future<void> updateProfile({required String nickname, required String profileUrl}) async {
    await _repo.updateProfile(nickname: nickname, profileUrl: profileUrl);
    await reload();
  }

  /// 선호 카테고리 저장 > 성공 시 재조회 (서버 저장 성공 여부 반환)
  Future<bool> savePreferredCategories(List<int> preferredCategories) async {
    final isSaved = await _repo.savePreferredCategories(preferredCategories);
    if (isSaved) await reload();
    return isSaved;
  }

  /// 회원 위치 저장 > 재조회 (실패 시 예외 전달)
  Future<void> saveLocation({
    required double longitude,
    required double latitude,
    required String siDo,
    required String siGunGu,
    required String eupMyoenDong,
    String? ri,
  }) async {
    await _repo.saveLocation(
      longitude: longitude,
      latitude: latitude,
      siDo: siDo,
      siGunGu: siGunGu,
      eupMyoenDong: eupMyoenDong,
      ri: ri,
    );
    await reload();
  }

  /// 탐색 범위 저장 (미터) > 성공 시 재조회 (서버 저장 성공 여부 반환)
  Future<bool> saveSearchRadius(double searchRadiusInMeters) async {
    final isSaved = await _repo.saveSearchRadius(searchRadiusInMeters);
    if (isSaved) await reload();
    return isSaved;
  }

  /// 약관 동의 저장 > 성공 시 재조회 (서버 저장 성공 여부 반환)
  Future<bool> saveTermsAgreement({required bool isMarketingInfoAgreed}) async {
    final isSaved = await _repo.saveTermsAgreement(isMarketingInfoAgreed: isMarketingInfoAgreed);
    if (isSaved) await reload();
    return isSaved;
  }
}
