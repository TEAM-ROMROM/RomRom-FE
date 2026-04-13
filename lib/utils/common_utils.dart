import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common/common_modal.dart';
import 'package:romrom_fe/utils/device_type.dart';

/// Navigator 메서드와 대상 screen을 인자로 받는 확장 함수
extension NavigationExtension on BuildContext {
  /// 네비게이션 메서드
  Future<T?> navigateTo<T extends Object?>({
    required Widget screen, // 이동할 page
    NavigationTypes type = NavigationTypes.push, // 이동 형식 (기본 Push)
    RouteSettings? routeSettings, // routing할 때 화면에 넘겨줄 값
    bool Function(Route<dynamic>)? predicate, // pushAndRemoveUntil, fadeTransition, clearStackImmediate 용
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

      case NavigationTypes.fadeTransition:
        return Navigator.pushAndRemoveUntil<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            settings: routeSettings,
          ),
          predicate ?? (route) => false,
        );

      case NavigationTypes.clearStackImmediate:
        return Navigator.pushAndRemoveUntil<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            // transitionsBuilder 미지정: 기본 동작(child 그대로 반환)으로 전환 없이 즉시 표시
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            settings: routeSettings,
          ),
          predicate ?? (route) => false,
        );

      case NavigationTypes.fadePush:
        return Navigator.push<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            settings: routeSettings,
          ),
        );
    }
  }
}

/// 화면 크기에 따라 폰트 크기를 조정하는 함수
double adjustedFontSize(BuildContext context, double spSize) {
  if (isTablet) {
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

// 마지막 활동 시간을 텍스트로 변환
String getLastActivityTime(DateTime? lastActiveAt) {
  if (lastActiveAt == null) return '오래 전 활동';
  final diff = DateTime.now().difference(lastActiveAt);
  if (diff.inMinutes < 1) return '방금 전 활동';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전 활동';
  if (diff.inHours < 24) return '${diff.inHours}시간 전 활동';
  return '${diff.inDays}일 전 활동';
}

// 색상을 어둡게 만드는 함수(버튼 highlight용)
Color darkenBlend(Color c) {
  return Color.alphaBlend(AppColors.opacity20Black, c);
}

/// 아이템 공유
/// itemId를 받아 공유 시트를 띄움
Future<void> shareItem({required String itemId, Rect? sharePositionOrigin}) async {
  final url = Uri.parse('${AppUrls.itemShareBaseUrl}/item').replace(queryParameters: {'itemId': itemId}).toString();
  final text = url;
  try {
    debugPrint('[Share]: sharing itemId=$itemId url=$url origin=$sharePositionOrigin');
    await Share.share(text, sharePositionOrigin: sharePositionOrigin);
    debugPrint('[Share]: share completed for itemId=$itemId');
  } catch (e, st) {
    debugPrint('[Share]: share failed for itemId=$itemId - $e\n$st');
    rethrow;
  }
}

/// 공백 단위로만 줄바꿈을 허용하는 String 확장
/// 단어 내부 문자 사이에 Word Joiner(\u2060)를 삽입하여 단어 중간 줄바꿈을 방지
extension StringWordWrapExtension on String {
  String get noBreak {
    return replaceAllMapped(RegExp(r'[^\s]+'), (match) => match.group(0)!.characters.join('\u2060'));
  }
}
