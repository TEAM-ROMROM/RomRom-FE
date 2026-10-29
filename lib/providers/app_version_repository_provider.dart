import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/app_version_repository.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';

/// AppVersionRepository 주입용 Provider (스플래시 버전 확인, 테스트 override 지점)
final appVersionRepositoryProvider = Provider<AppVersionRepository>((ref) => AppVersionRepository(AppVersionApi()));
