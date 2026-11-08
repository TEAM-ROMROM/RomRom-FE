import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

/// 방해금지 시간 설정 상태 (BE #861): 사용 여부, 시작·종료 시각 (KST, 시작 > 종료면 다음 날까지)
/// 서버 값 형식 "HH:mm" <-> TimeOfDay
@immutable
class DoNotDisturbSettingState {
  // 서버 기본값과 동일 (22:00 ~ 08:00, 꺼짐)
  static const TimeOfDay defaultStartTime = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay defaultEndTime = TimeOfDay(hour: 8, minute: 0);

  final bool isEnabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const DoNotDisturbSettingState({
    this.isEnabled = false,
    this.startTime = defaultStartTime,
    this.endTime = defaultEndTime,
  });

  /// 회원 정보 > 설정 (필드 없음·형식 오류 > 기본값, 옛 서버 대비)
  factory DoNotDisturbSettingState.fromMember(Member member) {
    return DoNotDisturbSettingState(
      isEnabled: member.isDoNotDisturbEnabled ?? false,
      startTime: parseServerTime(member.doNotDisturbStartTime) ?? defaultStartTime,
      endTime: parseServerTime(member.doNotDisturbEndTime) ?? defaultEndTime,
    );
  }

  /// "HH:mm" 또는 "HH:mm:ss" > TimeOfDay (형식 오류 > null)
  static TimeOfDay? parseServerTime(String? serverTimeText) {
    final timeParts = serverTimeText?.split(':');
    if (timeParts == null || timeParts.length < 2) return null;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// TimeOfDay > "HH:mm" (서버 전송·화면 표시 공통)
  static String formatServerTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get startTimeText => formatServerTime(startTime);
  String get endTimeText => formatServerTime(endTime);

  /// 시작 > 종료면 자정을 넘기는 구간 (표시 "다음 날")
  bool get isOvernight => startTime.hour * 60 + startTime.minute > endTime.hour * 60 + endTime.minute;

  /// 시작 = 종료 (구간 없음 > 저장 막음)
  bool get hasSameStartAndEnd => startTime == endTime;

  DoNotDisturbSettingState copyWith({bool? isEnabled, TimeOfDay? startTime, TimeOfDay? endTime}) {
    return DoNotDisturbSettingState(
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoNotDisturbSettingState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(isEnabled, startTime, endTime);

  @override
  String toString() => 'DoNotDisturbSettingState(isEnabled: $isEnabled, $startTimeText ~ $endTimeText)';
}
