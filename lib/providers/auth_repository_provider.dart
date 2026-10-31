import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/auth_repository.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';

/// AuthRepository 주입용 Provider (스플래시·로그인·온보딩 공용, 테스트 override 지점)
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(RomAuthApi()));
