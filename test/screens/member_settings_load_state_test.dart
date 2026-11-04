import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_location.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/screens/my_page/my_category_settings_screen.dart';
import 'package:romrom_fe/screens/search_range_setting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_design_screen.dart';

/// 회원 정보 조회 대역: 실패 모드면 throw, 아니면 선호 카테고리 없는 응답 (위치 지정 가능)
class _MemberInfoRepository implements MemberRepository {
  bool isFailing = false;
  MemberLocation? memberLocation;
  int getMemberInfoCallCount = 0;
  int savePreferredCategoriesCallCount = 0;

  @override
  Future<MemberResponse> getMemberInfo() async {
    getMemberInfoCallCount++;
    if (isFailing) throw Exception('network down');
    return MemberResponse(
      member: Member(memberId: 'me'),
      memberLocation: memberLocation,
    );
  }

  @override
  Future<bool> savePreferredCategories(List<int> preferredCategories) async {
    savePreferredCategoriesCallCount++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpMemberSettingsScreen(
  WidgetTester tester, {
  required Widget screen,
  required MemberRepository memberRepository,
}) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [memberRepositoryProvider.overrideWithValue(memberRepository)],
      child: buildDesignScreenApp(home: screen),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // 동네 인증 기록 저장소 (기록 없음 = GPS 미인증)
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('선호 카테고리 설정', () {
    testWidgets('선호 카테고리 응답 없음 > 로딩 끝나고 저장 버튼 표시', (tester) async {
      await pumpMemberSettingsScreen(
        tester,
        screen: const MyCategorySettingsScreen(),
        memberRepository: _MemberInfoRepository(),
      );

      expect(find.text('저장하기'), findsOneWidget);
    });

    testWidgets('불러오기 실패 > 에러 뷰, 저장 버튼 없음 > 다시 시도 성공 시 저장 버튼', (tester) async {
      final memberRepository = _MemberInfoRepository()..isFailing = true;
      await pumpMemberSettingsScreen(
        tester,
        screen: const MyCategorySettingsScreen(),
        memberRepository: memberRepository,
      );

      expect(find.text('선호 카테고리를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('저장하기'), findsNothing);

      memberRepository.isFailing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('저장하기'), findsOneWidget);
      expect(memberRepository.savePreferredCategoriesCallCount, 0);
    });
  });

  group('탐색 범위 설정', () {
    testWidgets('조회 실패 > 위치 설정 안내 대신 에러 뷰 + 다시 시도', (tester) async {
      final memberRepository = _MemberInfoRepository()..isFailing = true;
      await pumpMemberSettingsScreen(
        tester,
        screen: const SearchRangeSettingScreen(),
        memberRepository: memberRepository,
      );

      expect(find.text('탐색 범위를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('위치 인증이 필요해요'), findsNothing);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(memberRepository.getMemberInfoCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('위치 없음 > 동네 인증 안내', (tester) async {
      await pumpMemberSettingsScreen(
        tester,
        screen: const SearchRangeSettingScreen(),
        memberRepository: _MemberInfoRepository(),
      );

      expect(find.text('위치 인증이 필요해요'), findsOneWidget);
      expect(find.text('동네 인증하기'), findsOneWidget);
    });

    testWidgets('기존 핀 방식 위치만 있음(GPS 미인증) > 범위 변경 대신 동네 인증 안내', (tester) async {
      await pumpMemberSettingsScreen(
        tester,
        screen: const SearchRangeSettingScreen(),
        memberRepository: _MemberInfoRepository()..memberLocation = MemberLocation(latitude: 37.5, longitude: 127.0),
      );

      expect(find.text('위치 인증이 필요해요'), findsOneWidget);
    });
  });
}
