import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/location_verification_record.dart';

/// 동네 인증 상태: 기기에 저장된 마지막 GPS 인증 기록 (없음 > 미인증)
@immutable
class LocationVerificationState {
  final LocationVerificationRecord? record;

  const LocationVerificationState({this.record});

  /// [memberId] 회원이 GPS로 인증했는지 (다른 회원 기록 > false)
  bool isVerifiedFor(String? memberId) => memberId != null && memberId.isNotEmpty && record?.memberId == memberId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocationVerificationState && other.record == record;

  @override
  int get hashCode => record.hashCode;

  @override
  String toString() => 'LocationVerificationState(record: $record)';
}
