// 홈 탭 코치마크: 첫 물품 등록 후 1회 표시 판정, 오버레이 표시·제거, 확인 시 표시 기록 저장
part of '../home_tab_screen.dart';

mixin _HomeTabCoachMark on _HomeTabScreenStateFields {
  /// 코치마크 표시 (외부 호출용 — 첫 물건 등록 후 홈 탭에서 직접 표시).
  void showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndShowCoachMark();
      }
    });
  }

  Future<void> _checkAndShowCoachMark() async {
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo();
      final bool shouldShowCoachMark = (userInfo.isFirstItemPosted == true) && (userInfo.isCoachMarkShown != true);
      if (shouldShowCoachMark) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCoachMarkOverlay();
        });
      }
    } catch (e) {
      debugPrint('⚠️ 코치마크 체크 실패: $e');
    }
  }

  Future<void> _closeCoachMark() async {
    _removeCoachMarkOverlay();
    final userInfo = UserInfo();
    await userInfo.getUserInfo();
    await userInfo.saveLoginStatus(
      isFirstLogin: userInfo.isFirstLogin ?? false,
      isFirstItemPosted: userInfo.isFirstItemPosted ?? false,
      isItemCategorySaved: userInfo.isItemCategorySaved ?? false,
      isMemberLocationSaved: userInfo.isMemberLocationSaved ?? false,
      isMarketingInfoAgreed: userInfo.isMarketingInfoAgreed ?? false,
      isRequiredTermsAgreed: userInfo.isRequiredTermsAgreed ?? false,
      isCoachMarkShown: true,
    );
  }

  void _showCoachMarkOverlay() {
    _removeCoachMarkOverlay();
    _overlayEntry = OverlayEntry(builder: (context) => CoachMarkOverlay(onClose: _closeCoachMark));
    if (mounted && _overlayEntry != null) {
      try {
        Overlay.of(context).insert(_overlayEntry!);
      } on FlutterError catch (e) {
        debugPrint('오버레이 삽입 오류: $e');
        _overlayEntry = null;
      } catch (e) {
        debugPrint('오버레이 삽입 알 수 없는 오류: $e');
        _overlayEntry = null;
      }
    }
  }

  void _removeCoachMarkOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        debugPrint('오류: 오버레이 제거 실패 - $e');
      }
      _overlayEntry = null;
    }
  }
}
