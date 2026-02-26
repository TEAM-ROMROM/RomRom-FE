import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/app_colors.dart';
import '../widgets/common/common_modal.dart';

/// Navigator 메서드와 대상 screen을 인자로 받는 확장 함수
extension NavigationExtension on BuildContext {
  /// 네비게이션 메서드
  Future<T?> navigateTo<T extends Object?>({
    required Widget screen, // 이동할 page
    NavigationTypes type = NavigationTypes.push, // 이동 형식 (기본 Push)
    RouteSettings? routeSettings, // routing할 때 화면에 넘겨줄 값
    bool Function(Route<dynamic>)? predicate, // pushAndRemoveUntil 용
  }) {
    // iOS에서는 CupertinoPageRoute, 안드로이드에서는 MaterialPageRoute 사용
    PageRoute<T> createRoute(Widget screen, RouteSettings? settings) {
      if (Platform.isIOS) {
        return CupertinoPageRoute<T>(builder: (context) => screen, settings: settings);
      } else {
        return MaterialPageRoute<T>(builder: (context) => screen, settings: settings);
      }
    }

    switch (type) {
      case NavigationTypes.push:
        return Navigator.push<T>(this, createRoute(screen, routeSettings));

      case NavigationTypes.pushReplacement:
        // 이전 라우트로 결과를 줄 일이 없으면 <T, T?> 정도로 맞추면 됨
        return Navigator.pushReplacement<T, T?>(this, createRoute(screen, routeSettings));

      case NavigationTypes.pushAndRemoveUntil:
        return Navigator.pushAndRemoveUntil<T>(this, createRoute(screen, routeSettings), predicate ?? (route) => false);
    }
  }
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double adjustedFontSize(BuildContext context, double spSize) {
  final shortestSide = MediaQuery.of(context).size.shortestSide;
  if (shortestSide > 600) {
    // 태블릿 크기 기준
    return (spSize * 0.8).sp; // 태블릿에서는 80% 크기로 조정
  } else {
    return spSize.sp;
  }
}

/// Boxdecoration 색상, radius 설정
/// : color, radius를 인자로 받아 BoxDecoration을 반환
BoxDecoration buildBoxDecoration(Color color, BorderRadius radius) {
  return BoxDecoration(color: color, borderRadius: radius);
}

/// 가격을 "1,000" 형식으로 반환
String formatPrice(int price) {
  final formatter = NumberFormat('#,###');
  return formatter.format(price);
}

extension ContextExtension on BuildContext {
  Future<bool?> showDeleteDialog({
    required String title,
    required String description,
    String cancelText = '취소',
    String confirmText = '삭제',
  }) async {
    return CommonModal.confirm(
      context: this,
      message: description,
      cancelText: cancelText,
      confirmText: confirmText,
      onCancel: () => Navigator.of(this).pop(false),
      onConfirm: () => Navigator.of(this).pop(true),
    );
  }
}

/// 날짜 변환 함수
/// 2025-07-14T17:53:08.807506 -> 2025년 7월 14일
String formatDate(DateTime date) {
  return DateFormat('yyyy년 M월 d일').format(date);
}

/// 시간 경과 표시 함수
/// DateTime을 받아서 "방금", "N초 전", "N분 전", "N시간 전", "N일 전", "N주 전", "N달 전", "N년 전" 형식으로 반환
String getTimeAgo(DateTime createdDate) {
  final now = DateTime.now();
  final difference = now.difference(createdDate);

  if (difference.inSeconds < 1) {
    return '방금';
  } else if (difference.inSeconds < 60) {
    return '${difference.inSeconds}초 전';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks주 전';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months달 전';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years년 전';
  }
}

// 동일한 '분'인지 체크
bool isSameMinute(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  final la = a.isUtc ? a.toLocal() : a;
  final lb = b.isUtc ? b.toLocal() : b;
  return la.year == lb.year && la.month == lb.month && la.day == lb.day && la.hour == lb.hour && la.minute == lb.minute;
}

String formatMessageTime(DateTime? dt) {
  if (dt == null) return '';

  // UTC에서 넘어올 수 있으니 로컬화
  final local = dt.isUtc ? dt.toLocal() : dt;

  final hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');

  final period = hour < 12 ? '오전' : '오후';
  // 12시간제 변환: 0시→12, 13시→1, 12시→12
  final h12 = (hour % 12 == 0) ? 12 : (hour % 12);

  return '$period $h12:$minute'; // 예: "오전 9:05", "오후 12:30"
}

String getLastActivityTime(ChatRoom chatRoom, Member member) {
  final lastActivity = chatRoom.getLastActivityTime(member);
  final now = DateTime.now();
  final difference = now.difference(lastActivity);

  if (difference.inMinutes < 1) {
    return '방금 전 활동';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전 활동';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}시간 전 활동';
  } else {
    return '${difference.inDays}일 전 활동';
  }
}

// 색상을 어둡게 만드는 함수(버튼 highlight용)
Color darkenBlend(Color c) {
  return Color.alphaBlend(AppColors.opacity20Black, c);
}
