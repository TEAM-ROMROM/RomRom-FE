import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/location_verification_purpose.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/location_verification_record.dart';
import 'package:romrom_fe/providers/location_verification_provider.dart';
import 'package:romrom_fe/repositories/location_verification_repository.dart';
import 'package:romrom_fe/utils/location_verification_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_design_screen.dart';

/// 기기에 [memberId] 회원 인증 기록 저장 (null > 기록 없음)
void seedVerificationRecord(String? memberId) {
  if (memberId == null) {
    SharedPreferences.setMockInitialValues({});
    return;
  }
  final record = LocationVerificationRecord(
    memberId: memberId,
    verifiedAt: DateTime(2026, 11, 1),
    latitude: 37.5,
    longitude: 127.0,
  );
  SharedPreferences.setMockInitialValues({StorageKeys.locationVerificationRecord.key: jsonEncode(record.toJson())});
}

/// 인증 확인 실행 버튼 화면: 인증 화면 이동은 대역 ([verificationScreenResult] 반환, 이동 횟수 기록)
class GateHarness {
  int verificationScreenOpenCount = 0;
  bool? verificationScreenResult = true;
  // 탭 1번에 인증 확인 호출 횟수 (연속 호출 중복 차단 검증용)
  int gateCallCountPerTap = 1;
  final List<bool> gateResults = [];

  Future<void> pump(WidgetTester tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationVerificationRepositoryProvider.overrideWithValue(
            LocationVerificationRepository(readCurrentMemberId: () async => 'member-a'),
          ),
          locationVerificationGateProvider.overrideWith(
            (ref) => LocationVerificationGate(
              ref,
              openVerificationScreen: (context) async {
                verificationScreenOpenCount++;
                return verificationScreenResult;
              },
            ),
          ),
        ],
        child: buildDesignScreenApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: GestureDetector(
                  onTap: () {
                    for (var callIndex = 0; callIndex < gateCallCountPerTap; callIndex++) {
                      ref
                          .read(locationVerificationGateProvider)
                          .ensureVerified(context, purpose: LocationVerificationPurpose.itemRegistration)
                          .then(gateResults.add);
                    }
                  },
                  child: const Text('기능 실행'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  late GateHarness harness;

  setUp(() => harness = GateHarness());

  testWidgets('인증된 회원 > 안내·인증 화면 없이 통과', (tester) async {
    seedVerificationRecord('member-a');
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();

    expect(harness.gateResults, [true]);
    expect(find.text('위치 인증하기'), findsNothing);
    expect(harness.verificationScreenOpenCount, 0);
  });

  testWidgets('미인증 > 기능별 이유 안내 모달 (시스템 권한 창 전), 나중에 > 기능만 중단', (tester) async {
    seedVerificationRecord(null);
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();

    expect(find.textContaining('물품을 등록하려면'), findsOneWidget);
    expect(find.textContaining('이웃끼리만 거래할 수 있도록'), findsOneWidget);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(harness.gateResults, [false]);
    expect(harness.verificationScreenOpenCount, 0);
    // 앱 화면 유지 (차단·종료 없음)
    expect(find.text('기능 실행'), findsOneWidget);
  });

  testWidgets('미인증 > 위치 인증하기 > 인증 화면 성공 > 통과', (tester) async {
    seedVerificationRecord(null);
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('위치 인증하기'));
    await tester.pumpAndSettle();

    expect(harness.verificationScreenOpenCount, 1);
    expect(harness.gateResults, [true]);
  });

  testWidgets('미인증 > 인증 화면에서 거부·뒤로 > 중단, 자동 재안내 없음', (tester) async {
    seedVerificationRecord(null);
    harness.verificationScreenResult = false;
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('위치 인증하기'));
    await tester.pumpAndSettle();

    expect(harness.gateResults, [false]);
    expect(find.text('위치 인증하기'), findsNothing);
  });

  testWidgets('다른 회원 기록 > 미인증 처리 (안내 모달)', (tester) async {
    seedVerificationRecord('member-b');
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();

    expect(find.text('위치 인증하기'), findsOneWidget);
  });

  testWidgets('진행 중 재호출 > 즉시 false, 모달 1개만 (중복 진입 차단)', (tester) async {
    seedVerificationRecord(null);
    harness.gateCallCountPerTap = 2;
    await harness.pump(tester);

    await tester.tap(find.text('기능 실행'));
    await tester.pumpAndSettle();

    expect(find.text('위치 인증하기'), findsOneWidget);
    expect(harness.gateResults, [false]);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(harness.gateResults, [false, false]);
  });
}
