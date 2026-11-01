// lib/utils/date_time_display_utils.dart
// 날짜·시각 표시 규칙 단일 원본: 경과 시간, 메시지 시각, 날짜 구분선, 같은 분·같은 날짜 판정 (기기 로컬 시간 기준)
import 'dart:math' as math;

import 'package:intl/intl.dart';

// 요일 이름 (DateTime.weekday: 1 월요일 ~ 7 일요일, intl 로케일 초기화 없이 쓰기 위해 직접 보유)
const List<String> koreanWeekdayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

// 경과 시간 단위 경계 (일)
const int daysPerWeek = 7;
const int daysPerMonth = 30;
const int daysPerYear = 365;
const int monthsPerYear = 12;

/// 날짜 > "2025년 7월 14일"
String formatDate(DateTime date) {
  return DateFormat('yyyy년 M월 d일').format(date);
}

/// 시각 > 경과 시간 문구 (방금 / N초·분·시간·일·주·달·년 전, 시각 없으면 빈 문자열)
/// 미래 시각(기기 시계 차이)은 방금, 12달 이상은 최소 1년 전
String getTimeAgo(DateTime? createdDate, {DateTime? now}) {
  if (createdDate == null) return '';
  final elapsed = (now ?? DateTime.now()).difference(createdDate);

  if (elapsed.inSeconds < 1) return '방금';
  if (elapsed.inSeconds < 60) return '${elapsed.inSeconds}초 전';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}분 전';
  if (elapsed.inHours < 24) return '${elapsed.inHours}시간 전';
  if (elapsed.inDays < daysPerWeek) return '${elapsed.inDays}일 전';
  if (elapsed.inDays < daysPerMonth) return '${elapsed.inDays ~/ daysPerWeek}주 전';

  final months = elapsed.inDays ~/ daysPerMonth;
  if (months < monthsPerYear) return '$months달 전';

  // 360~364일은 12달이 아니라 1년 전
  final years = math.max(1, elapsed.inDays ~/ daysPerYear);
  return '$years년 전';
}

/// 상대 마지막 활동 시각 > "N분 전 활동" (1분 미만 방금 전, 시각 없으면 오래 전)
String getLastActivityTime(DateTime? lastActiveAt, {DateTime? now}) {
  if (lastActiveAt == null) return '오래 전 활동';
  final currentTime = now ?? DateTime.now();
  if (currentTime.difference(lastActiveAt).inMinutes < 1) return '방금 전 활동';
  return '${getTimeAgo(lastActiveAt, now: currentTime)} 활동';
}

/// 두 시각이 같은 분인지 (로컬 기준, 하나라도 없으면 false)
bool isSameMinute(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day && la.hour == lb.hour && la.minute == lb.minute;
}

/// 두 시각이 같은 날짜인지 (로컬 기준, UTC 시각은 로컬로 바꿔 자정 경계 판정)
bool isSameLocalDate(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
}

/// 메시지 시각 > "오전 9:05" (12시간제, 시각 없으면 빈 문자열)
String formatMessageTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();

  final hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');

  final period = hour < 12 ? '오전' : '오후';
  // 12시간제 변환: 0시→12, 13시→1, 12시→12
  final h12 = (hour % 12 == 0) ? 12 : (hour % 12);

  return '$period $h12:$minute';
}

/// 시각 > 목록 시각 문구 (채팅 목록·알림 목록 공통, 로컬 날짜 기준, 시각 없으면 빈 문자열)
/// 오늘 "오후 3:05" / 어제 "어제" / 올해 "10월 28일" / 이전 연도 "2025. 10. 28."
String formatListTimestamp(DateTime? dateTime, {DateTime? now}) {
  if (dateTime == null) return '';
  final local = dateTime.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  // 월·연 경계는 DateTime 생성자가 자동 보정 (1일의 전날 > 전월 말일)
  final yesterday = DateTime(today.year, today.month, today.day - 1);

  if (isSameLocalDate(local, today)) return formatMessageTime(local);
  if (isSameLocalDate(local, yesterday)) return '어제';
  if (local.year == today.year) return '${local.month}월 ${local.day}일';
  return '${local.year}. ${local.month}. ${local.day}.';
}

/// 시각 > 채팅 날짜 구분선 문구 "2026년 11월 1일 일요일" (로컬 기준, 올해도 연도 항상 표시)
String formatChatDateDividerLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}년 ${local.month}월 ${local.day}일 ${koreanWeekdayNames[local.weekday - 1]}';
}
