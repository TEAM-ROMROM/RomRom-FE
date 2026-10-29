import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 회원 차단 저장소: 차단, 차단 해제, 차단 회원 목록 조회 (MemberApi 래핑)
class MemberBlockRepository {
  final MemberApi _api;

  MemberBlockRepository(this._api);

  Future<bool> block(String memberId) => _api.blockMember(memberId);
  Future<bool> unblock(String memberId) => _api.unblockMember(memberId);

  /// 차단한 회원 목록 (응답 없으면 빈 목록)
  Future<List<Member>> getBlockedMembers() async => (await _api.getBlockedMembers()).members ?? <Member>[];
}
