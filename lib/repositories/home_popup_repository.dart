import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/apis/objects/home_popup.dart';
import 'package:romrom_fe/models/apis/responses/home_popup_response.dart';
import 'package:romrom_fe/services/apis/home_popup_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 홈 팝업 저장소: 활성 팝업 조회(HomePopupApi 래핑), "다시 보지 않기" id 로컬 저장 (UI 모름)
/// 조회 실패·응답 이상은 전부 팝업 없음 (서버 미배포 #749 포함)
class HomePopupRepository {
  final HomePopupApi _api;

  HomePopupRepository(this._api);

  /// 활성 팝업 조회 > 노출 가능한 팝업 1개 (없음·404·네트워크 오류·파싱 실패 시 null)
  Future<HomePopup?> fetchActivePopup() async {
    try {
      final responseBody = await _api.fetchActiveHomePopupBody();
      final popup = HomePopupResponse.fromJsonBody(responseBody).homePopup;
      return popup != null && isDisplayablePopup(popup) ? popup : null;
    } catch (error) {
      debugPrint('[home popup] fetch failed : $error');
      return null;
    }
  }

  /// 노출 조건 3개: id 있음, 비활성 아님(누락은 서버 판정 신뢰), 이미지·제목 중 하나 이상
  @visibleForTesting
  static bool isDisplayablePopup(HomePopup popup) {
    final hasPopupId = popup.homePopupId != null;
    final isDeactivated = popup.isActive == false;
    final hasVisibleContent = popup.imageUrl != null || popup.title != null;
    return hasPopupId && !isDeactivated && hasVisibleContent;
  }

  /// "다시 보지 않기" 누른 팝업 id 목록 (읽기 실패 시 빈 목록)
  Future<Set<String>> loadDismissedPopupIds() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return (preferences.getStringList(StorageKeys.dismissedHomePopupIds.key) ?? const <String>[]).toSet();
    } catch (error) {
      debugPrint('[home popup] dismissed ids load failed : $error');
      return <String>{};
    }
  }

  /// "다시 보지 않기" 팝업 id 추가 저장 (기존 목록 유지)
  Future<void> saveDismissedPopupId(String popupId) async {
    final preferences = await SharedPreferences.getInstance();
    final dismissedPopupIds = await loadDismissedPopupIds();
    if (!dismissedPopupIds.add(popupId)) return;
    await preferences.setStringList(StorageKeys.dismissedHomePopupIds.key, dismissedPopupIds.toList());
  }
}
