import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/report_repository.dart';
import 'package:romrom_fe/services/apis/report_api.dart';

/// ReportRepository 주입용 Provider (물품·회원 신고 화면 공용, 테스트 override 지점)
final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository(ReportApi()));
