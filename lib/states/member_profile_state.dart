// lib/states/member_profile_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_item_category.dart';
import 'package:romrom_fe/models/apis/objects/member_location.dart';

/// 본인 회원 프로필 상태.
/// member에는 알림 설정 필드(isMarketingInfoAgreed 등)도 포함되어 있어
/// Phase 3 알림 도메인에서 이 state를 그대로 재사용할 수 있다.
@immutable
class MemberProfileState {
  final Member? member;
  final MemberLocation? location;

  /// 선호 카테고리 목록 (선호 카테고리 설정 화면 초기값)
  final List<MemberItemCategory>? itemCategories;

  const MemberProfileState({this.member, this.location, this.itemCategories});

  MemberProfileState copyWith({Member? member, MemberLocation? location, List<MemberItemCategory>? itemCategories}) =>
      MemberProfileState(
        member: member ?? this.member,
        location: location ?? this.location,
        itemCategories: itemCategories ?? this.itemCategories,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberProfileState &&
          runtimeType == other.runtimeType &&
          member == other.member &&
          location == other.location &&
          listEquals(itemCategories, other.itemCategories);

  @override
  int get hashCode => Object.hash(member, location, itemCategories == null ? null : Object.hashAll(itemCategories!));

  @override
  String toString() =>
      'MemberProfileState(memberId: ${member?.memberId}, location: ${location?.siGunGu}, '
      'itemCategoryCount: ${itemCategories?.length})';
}
