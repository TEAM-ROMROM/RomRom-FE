import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/models/gps_location_check_result.dart';
import 'package:romrom_fe/providers/location_verification_provider.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/services/gps_location_verifier.dart';

import '../helpers/pump_design_screen.dart';

/// GPS 확인 대역: 권한 상태·확인 결과 지정, 확인·설정 열기 호출 기록
class FakeGpsLocationVerifier extends GpsLocationVerifier {
  LocationPermission permission = LocationPermission.whileInUse;
  GpsLocationCheckResult checkResult = const GpsLocationCheckResult.failed(LocationVerificationFailure.mockedLocation);
  final List<bool> checkRequestPermissionFlags = [];
  final List<LocationVerificationFailure> openedSettingsFailures = [];

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<GpsLocationCheckResult> checkCurrentLocation({bool shouldRequestPermission = true}) async {
    checkRequestPermissionFlags.add(shouldRequestPermission);
    return checkResult;
  }

  @override
  Future<bool> openSettingsFor(LocationVerificationFailure failure) async {
    openedSettingsFailures.add(failure);
    return true;
  }
}

/// 시작 화면 > 인증 화면 push (pop 결과 기록)
Future<List<bool?>> pumpVerificationScreen(
  WidgetTester tester,
  FakeGpsLocationVerifier verifier, {
  bool isExplanationShown = false,
}) async {
  final popResults = <bool?>[];
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gpsLocationVerifierProvider.overrideWithValue(verifier)],
      child: buildDesignScreenApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () async {
                  final popResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => MyLocationVerificationScreen(isExplanationShown: isExplanationShown),
                    ),
                  );
                  popResults.add(popResult);
                },
                child: const Text('인증 화면 열기'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('인증 화면 열기'));
  await tester.pumpAndSettle();
  return popResults;
}

void main() {
  late FakeGpsLocationVerifier verifier;

  setUp(() => verifier = FakeGpsLocationVerifier());

  testWidgets('직접 진입 + 권한 미결정 > 시스템 권한 전 안내 모달, 나중에 > 위치 확인 없이 닫힘', (tester) async {
    verifier.permission = LocationPermission.denied;
    final popResults = await pumpVerificationScreen(tester, verifier);

    expect(find.textContaining('이웃끼리만 거래할 수 있도록'), findsOneWidget);
    expect(verifier.checkRequestPermissionFlags, isEmpty);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(verifier.checkRequestPermissionFlags, isEmpty);
    expect(popResults, [false]);
    expect(find.text('인증 화면 열기'), findsOneWidget);
  });

  testWidgets('공통 확인 경유(안내 완료) > 모달 없이 바로 위치 확인', (tester) async {
    verifier.permission = LocationPermission.denied;
    await pumpVerificationScreen(tester, verifier, isExplanationShown: true);

    expect(find.text('위치 인증하기'), findsNothing);
    expect(verifier.checkRequestPermissionFlags, [true]);
  });

  testWidgets('가상 위치 > 거부 안내 + 다시 시도만 (설정 열기 없음, 지도 선택 없음)', (tester) async {
    await pumpVerificationScreen(tester, verifier);

    expect(find.text(LocationVerificationFailure.mockedLocation.title), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('설정 열기'), findsNothing);
    expect(find.text('이 동네로 인증하기'), findsNothing);
  });

  testWidgets('낮은 정확도 > 창가 재시도 안내, 다시 시도 > 재확인', (tester) async {
    verifier.checkResult = const GpsLocationCheckResult.failed(LocationVerificationFailure.lowAccuracy);
    await pumpVerificationScreen(tester, verifier);

    expect(find.textContaining('창가'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(verifier.checkRequestPermissionFlags, [true, true]);
  });

  testWidgets('권한 영구 거부 > 위치 인증 필요 + 설정 열기, 설정 복귀 > 권한 요청 없이 1회 재확인', (tester) async {
    verifier.permission = LocationPermission.deniedForever;
    verifier.checkResult = const GpsLocationCheckResult.failed(LocationVerificationFailure.permissionDeniedForever);
    await pumpVerificationScreen(tester, verifier);

    expect(find.text('위치 인증이 필요해요'), findsOneWidget);
    // 영구 거부 > 안내 모달·시스템 요청 없이 바로 안내 화면
    expect(find.text('나중에'), findsNothing);

    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    expect(verifier.openedSettingsFailures, [LocationVerificationFailure.permissionDeniedForever]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(verifier.checkRequestPermissionFlags, [true, false]);
  });
}
