import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/home_popup_repository.dart';
import 'package:romrom_fe/services/apis/home_popup_api.dart';

/// HomePopupRepository 주입용 Provider (홈 팝업 조회·다시 보지 않기 저장, 테스트 override 지점)
final homePopupRepositoryProvider = Provider<HomePopupRepository>((ref) => HomePopupRepository(HomePopupApi()));
