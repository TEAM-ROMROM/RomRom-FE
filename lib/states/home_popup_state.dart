import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/home_popup.dart';

/// 홈 팝업 세션 상태: 이번 앱 실행에서 조회 여부, 노출한 팝업
@immutable
class HomePopupState {
  // 이번 앱 실행에서 노출 판정 완료 (세션당 1회만 조회·노출)
  final bool hasCheckedThisSession;
  // 이번 세션에 노출한 팝업 (노출 대상 없으면 null)
  final HomePopup? displayedPopup;

  const HomePopupState({this.hasCheckedThisSession = false, this.displayedPopup});

  HomePopupState copyWith({bool? hasCheckedThisSession, HomePopup? displayedPopup}) => HomePopupState(
    hasCheckedThisSession: hasCheckedThisSession ?? this.hasCheckedThisSession,
    displayedPopup: displayedPopup ?? this.displayedPopup,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePopupState &&
          runtimeType == other.runtimeType &&
          hasCheckedThisSession == other.hasCheckedThisSession &&
          displayedPopup?.homePopupId == other.displayedPopup?.homePopupId;

  @override
  int get hashCode => Object.hash(hasCheckedThisSession, displayedPopup?.homePopupId);

  @override
  String toString() =>
      'HomePopupState(hasCheckedThisSession: $hasCheckedThisSession, displayedPopupId: ${displayedPopup?.homePopupId})';
}
