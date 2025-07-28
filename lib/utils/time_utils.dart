import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 시간 관련 유틸리티 함수들
class TimeUtils {
  /// 업로드 시간을 상대적 시간으로 포맷팅
  /// 예: "2시간 전", "3일 전", "방금 전"
  static String formatRelativeTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '시간 정보 없음';
    
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      debugPrint('날짜 파싱 실패: $dateString');
      return '시간 정보 없음';
    }
  }

  /// 날짜를 "2025년 7월 14일" 형식으로 포맷팅
  static String formatDate(String dateString) {
    try {
      return DateFormat('yyyy년 M월 d일').format(DateTime.parse(dateString));
    } catch (e) {
      debugPrint('날짜 파싱 실패: $dateString');
      return '날짜 정보 없음';
    }
  }

  /// 날짜와 시간을 "2025년 7월 14일 오후 3:30" 형식으로 포맷팅
  static String formatDateTime(String dateString) {
    try {
      return DateFormat('yyyy년 M월 d일 a h:mm').format(DateTime.parse(dateString));
    } catch (e) {
      debugPrint('날짜시간 파싱 실패: $dateString');
      return '시간 정보 없음';
    }
  }

  /// 시간만 "오후 3:30" 형식으로 포맷팅
  static String formatTime(String dateString) {
    try {
      return DateFormat('a h:mm').format(DateTime.parse(dateString));
    } catch (e) {
      debugPrint('시간 파싱 실패: $dateString');
      return '시간 정보 없음';
    }
  }

  /// 날짜만 "7월 14일" 형식으로 포맷팅 (간단 버전)
  static String formatShortDate(String dateString) {
    try {
      return DateFormat('M월 d일').format(DateTime.parse(dateString));
    } catch (e) {
      debugPrint('날짜 파싱 실패: $dateString');
      return '날짜 정보 없음';
    }
  }
} 