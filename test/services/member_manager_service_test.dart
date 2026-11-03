import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 회원 정보 > UserInfo 프로필 필드 동기화: 같은 회원만 반영, 회원 ID·온보딩 플래그 유지
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'memberId': 'me',
      'nickname': '이전 닉네임',
      'profileUrl': 'https://image/old.png',
      'isRequiredTermsAgreed': true,
      'isItemCategorySaved': true,
    });
    // 싱글톤 메모리 값을 테스트 저장소 값으로 다시 읽음
    await UserInfo().getUserInfo();
  });

  test('같은 회원 > 닉네임·프로필 사진·좌표 반영, 온보딩 플래그 유지', () async {
    await MemberManager.syncProfileFromServer(
      Member(memberId: 'me', nickname: '새 닉네임', profileUrl: 'https://image/new.png', latitude: 37.5),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('nickname'), '새 닉네임');
    expect(preferences.getString('profileUrl'), 'https://image/new.png');
    expect(preferences.getDouble('latitude'), 37.5);
    expect(UserInfo().nickname, '새 닉네임');
    expect(preferences.getBool('isRequiredTermsAgreed'), isTrue);
    expect(preferences.getBool('isItemCategorySaved'), isTrue);
    expect(UserInfo().needsOnboarding, isFalse);
  });

  test('다른 회원 응답 > 무시', () async {
    await MemberManager.syncProfileFromServer(Member(memberId: 'other', nickname: '남의 닉네임'));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('nickname'), '이전 닉네임');
    expect(preferences.getString('memberId'), 'me');
  });

  test('회원 ID 없는 응답 > 무시', () async {
    await MemberManager.syncProfileFromServer(Member(nickname: '이름만'));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('nickname'), '이전 닉네임');
  });

  group('로컬 회원 정보 없음 > 서버 조회 오류 처리 (스플래시 다시 시도 화면)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UserInfo().getUserInfo();
    });

    MemberManagerService serviceThrowing(Object error) =>
        MemberManagerService.forTesting(fetchMemberInfo: () async => throw error);

    test('연결 실패·시간 초과·5xx·408·429 > 호출부로 전파', () async {
      final retryableErrors = <Object>[
        const SocketException('offline'),
        ApiException(statusCode: 503, responseBody: ''),
        ApiException(statusCode: 408, responseBody: ''),
        ApiException(statusCode: 429, responseBody: ''),
      ];
      for (final error in retryableErrors) {
        await expectLater(serviceThrowing(error).getCurrentMember(), throwsA(same(error)), reason: '$error');
      }
    });

    test('401·404·로컬 오류 > 기존처럼 null 반환', () async {
      final nonRetryableErrors = <Object>[
        ApiException(statusCode: 401, responseBody: ''),
        ApiException(statusCode: 404, responseBody: ''),
        const FormatException('bad json'),
      ];
      for (final error in nonRetryableErrors) {
        expect(await serviceThrowing(error).getCurrentMember(), isNull, reason: '$error');
      }
    });

    test('재시도 가능 오류 후 다시 조회 > 새로 서버 조회해 성공', () async {
      var fetchCallCount = 0;
      final service = MemberManagerService.forTesting(
        fetchMemberInfo: () async {
          fetchCallCount++;
          if (fetchCallCount == 1) throw const SocketException('offline');
          return MemberResponse(
            member: Member(memberId: 'me', nickname: '닉네임'),
          );
        },
      );

      await expectLater(service.getCurrentMember(), throwsA(isA<SocketException>()));
      final member = await service.getCurrentMember();

      expect(fetchCallCount, 2);
      expect(member?.memberId, 'me');
      expect(UserInfo().memberId, 'me');
    });
  });
}
