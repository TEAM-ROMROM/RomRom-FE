// lib/states/member_profile_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_location.dart';

/// 본인 회원 프로필 상태.
/// member에는 알림 설정 필드(isMarketingInfoAgreed 등)도 포함되어 있어
/// Phase 3 알림 도메인에서 이 state를 그대로 재사용할 수 있다.
@immutable
class MemberProfileState {
  final Member? member;
  final MemberLocation? location;

  const MemberProfileState({this.member, this.location});

  MemberProfileState copyWith({Member? member, MemberLocation? location}) =>
      MemberProfileState(member: member ?? this.member, location: location ?? this.location);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberProfileState &&
          runtimeType == other.runtimeType &&
          member == other.member &&
          location == other.location;

  @override
  int get hashCode => Object.hash(member, location);

  @override
  String toString() => 'MemberProfileState(memberId: ${member?.memberId}, location: ${location?.siGunGu})';
}
