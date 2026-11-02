import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common/common_modal.dart';
import 'package:romrom_fe/utils/device_type.dart';

// 날짜·시각 표시 함수 원본은 date_time_display_utils.dart (기존 common_utils import 호출부 유지용 재노출)
export 'package:romrom_fe/utils/date_time_display_utils.dart';

/// 앱 전역 navigatorKey (ApiClient, FirebaseService 등에서 글로벌 네비게이션에 사용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigator 메서드와 대상 screen을 인자로 받는 확장 함수
extension NavigationExtension on BuildContext {
  /// 네비게이션 메서드
  Future<T?> navigateTo<T extends Object?>({
    required Widget screen, // 이동할 page
    NavigationTypes type = NavigationTypes.push, // 이동 형식 (기본 Push)
    RouteSettings? routeSettings, // routing할 때 화면에 넘겨줄 값
    bool Function(Route<dynamic>)? predicate, // pushAndRemoveUntil, fadeTransition, clearStackImmediate 용
  }) {
    // 두 플랫폼 모두 가로 슬라이드(이전 화면 시차) — Android 기본 Material 전환의 위로 튀는 느낌 제거
    PageRoute<T> createRoute(Widget screen, RouteSettings? settings) {
      return CupertinoPageRoute<T>(builder: (context) => screen, settings: settings);
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
        // 800ms → 400ms 단축 (AppMotion.slow)
        return Navigator.pushAndRemoveUntil<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
                child: child,
              );
            },
            transitionDuration: AppMotion.slow,
            reverseTransitionDuration: AppMotion.normal,
            settings: routeSettings,
          ),
          predicate ?? (route) => false,
        );

      case NavigationTypes.clearStackImmediate:
        // 즉시 전환 → 400ms fade 전환으로 개선 (딱딱함 제거)
        return Navigator.pushAndRemoveUntil<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: AppMotion.entry),
                child: child,
              );
            },
            transitionDuration: AppMotion.slow,
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
                opacity: CurvedAnimation(parent: animation, curve: AppMotion.decelerate),
                child: child,
              );
            },
            transitionDuration: AppMotion.normal,
            reverseTransitionDuration: AppMotion.fast,
            settings: routeSettings,
          ),
        );

      case NavigationTypes.slideUp:
        // 아래에서 위로 슬라이드 — 모달/바텀시트 느낌
        return Navigator.push<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: AppMotion.decelerate));
              return SlideTransition(position: slide, child: child);
            },
            transitionDuration: AppMotion.normal,
            reverseTransitionDuration: AppMotion.fast,
            settings: routeSettings,
          ),
        );

      case NavigationTypes.sharedAxisHorizontal:
        // 수평 SharedAxis — 리스트→상세 전환
        return Navigator.push<T>(
          this,
          PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                child: child,
              );
            },
            transitionDuration: AppMotion.slow,
            reverseTransitionDuration: AppMotion.normal,
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
