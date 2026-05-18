import 'package:romrom_fe/services/apis/member_api.dart';

class MemberBlockRepository {
  final MemberApi _api;

  MemberBlockRepository(this._api);

  Future<bool> block(String memberId) => _api.blockMember(memberId);
  Future<bool> unblock(String memberId) => _api.unblockMember(memberId);
}
