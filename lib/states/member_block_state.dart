import 'package:flutter/foundation.dart';

@immutable
class MemberBlockState {
  final Set<String> blockedIds;

  const MemberBlockState({this.blockedIds = const {}});

  bool isBlocked(String memberId) => blockedIds.contains(memberId);

  MemberBlockState copyWith({Set<String>? blockedIds}) => MemberBlockState(blockedIds: blockedIds ?? this.blockedIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberBlockState && runtimeType == other.runtimeType && setEquals(blockedIds, other.blockedIds);

  @override
  int get hashCode => Object.hashAll(blockedIds);
}
