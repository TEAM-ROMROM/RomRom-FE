import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/services/resume_version_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 복귀 버전 확인: 주기 판정, 성공 응답만 확인 시각 저장, 진행 중 중복 차단
void main() {
  var now = DateTime(2026, 11, 4, 12);
  var fetchCallCount = 0;
  UpdateType? serverUpdateType;

  ResumeVersionCheckService createService({Future<UpdateType?> Function()? fetchServerUpdateType}) {
    return ResumeVersionCheckService(
      fetchServerUpdateType:
          fetchServerUpdateType ??
          () async {
            fetchCallCount++;
            return serverUpdateType;
          },
      now: () => now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 4, 12);
    fetchCallCount = 0;
    serverUpdateType = UpdateType.none;
  });

  test('첫 복귀 > 서버 확인 결과 반환, 주기 안 재복귀 > 확인 생략', () async {
    final service = createService();
    serverUpdateType = UpdateType.force;

    expect(await service.checkIfDue(), UpdateType.force);
    expect(fetchCallCount, 1);

    now = now.add(ResumeVersionCheckService.checkInterval - const Duration(minutes: 1));
    expect(await service.checkIfDue(), UpdateType.none);
    expect(fetchCallCount, 1);

    now = now.add(const Duration(minutes: 1));
    expect(await service.checkIfDue(), UpdateType.force);
    expect(fetchCallCount, 2);
  });

  test('조회 실패·시간 초과(null) > 확인 시각 저장 안 함 > 다음 복귀 때 재확인', () async {
    final service = createService();
    serverUpdateType = null;

    expect(await service.checkIfDue(), UpdateType.none);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('last_version_check_timestamp'), isNull);

    now = now.add(const Duration(minutes: 5));
    serverUpdateType = UpdateType.force;
    expect(await service.checkIfDue(), UpdateType.force);
    expect(fetchCallCount, 2);
    expect(preferences.getInt('last_version_check_timestamp'), now.millisecondsSinceEpoch);
  });

  test('확인 진행 중 재복귀 > 중복 요청 없이 none', () async {
    final pendingResponse = Completer<UpdateType?>();
    var pendingFetchCallCount = 0;
    final service = createService(
      fetchServerUpdateType: () {
        pendingFetchCallCount++;
        return pendingResponse.future;
      },
    );

    final firstCheck = service.checkIfDue();
    await Future<void>.delayed(Duration.zero);
    expect(await service.checkIfDue(), UpdateType.none);

    pendingResponse.complete(UpdateType.force);
    expect(await firstCheck, UpdateType.force);
    expect(pendingFetchCallCount, 1);
  });
}
