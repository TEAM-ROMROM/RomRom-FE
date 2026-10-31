import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';

/// 앱 버전 저장소: 업데이트 필요 여부 판정 (AppVersionApi 래핑, UI 모름)
class AppVersionRepository {
  final AppVersionApi _api;

  AppVersionRepository(this._api);

  /// 현재 버전 <-> 서버 최소 버전 비교 > 업데이트 타입 (조회 실패 시 none)
  Future<UpdateType> checkUpdateType() => _api.checkUpdateType();
}
