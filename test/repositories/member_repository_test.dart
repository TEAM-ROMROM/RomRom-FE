import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 회원 API 대역: 내 정보 조회만 응답
class _FakeMemberApi implements MemberApi {
  _FakeMemberApi(this.response);

  final MemberResponse response;

  @override
  Future<MemberResponse> getMemberInfo() async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

/// 내 정보 조회 후 로컬 저장 함수 호출: 성공 > 회원 전달, 저장 실패 > 조회 결과 그대로
void main() {
  final fetchedMember = Member(memberId: 'me', nickname: '닉네임');

  test('조회 성공 > 저장 함수에 받은 회원 전달', () async {
    final savedMembers = <Member>[];
    final repository = MemberRepository(
      _FakeMemberApi(MemberResponse(member: fetchedMember)),
      saveFetchedMyMember: (member) async => savedMembers.add(member),
    );

    final response = await repository.getMemberInfo();

    expect(response.member, same(fetchedMember));
    expect(savedMembers.single, same(fetchedMember));
  });

  test('저장 실패 > 조회 결과 그대로 반환', () async {
    final repository = MemberRepository(
      _FakeMemberApi(MemberResponse(member: fetchedMember)),
      saveFetchedMyMember: (_) async => throw StateError('save failed'),
    );

    final response = await repository.getMemberInfo();

    expect(response.member, same(fetchedMember));
  });

  test('응답에 회원 없음 > 저장 안 함', () async {
    var saveCallCount = 0;
    final repository = MemberRepository(
      _FakeMemberApi(MemberResponse()),
      saveFetchedMyMember: (_) async => saveCallCount++,
    );

    await repository.getMemberInfo();

    expect(saveCallCount, 0);
  });
}
