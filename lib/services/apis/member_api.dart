// lib/services/apis/member_api.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class MemberApi {
  // 싱글톤 구현
  static final MemberApi _instance = MemberApi._internal();

  factory MemberApi() => _instance;

  MemberApi._internal();

  /// 하트비트 API (온라인 상태 갱신)
  /// `POST /api/members/heartbeat`
  Future<bool> heartbeat() async {
    const String url = '${AppUrls.baseUrl}/api/members/heartbeat';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('하트비트 전송 성공');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 이용약관 동의 API
  /// `POST /api/members/terms`
  Future<bool> saveTermsAgreement({required bool isMarketingInfoAgreed}) async {
    const String url = '${AppUrls.baseUrl}/api/members/terms';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'isMarketingInfoAgreed': isMarketingInfoAgreed.toString()},
      isAuthRequired: true,
      onSuccess: (responseData) {
        debugPrint('이용약관 동의 저장 성공');
        debugPrint('Response: $responseData');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 회원 선호 카테고리 저장 API
  /// `POST /api/members/post/category/preferences`
  Future<bool> savePreferredCategories(List<int> preferredCategories) async {
    const String url = '${AppUrls.baseUrl}/api/members/post/category/preferences';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {"preferredCategories": preferredCategories.map((e) => e.toString()).join(',')},
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('선호 카테고리 저장 성공');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 회원 위치정보 저장 API
  /// `POST /api/members/post/location`
  Future<void> saveMemberLocation({
    required double longitude,
    required double latitude,
    required String siDo,
    required String siGunGu,
    required String eupMyoenDong,
    String? ri,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/members/post/location';

    final Map<String, dynamic> fields = {
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'siDo': siDo,
      'siGunGu': siGunGu,
      'eupMyoenDong': eupMyoenDong,
      if (ri != null) 'ri': ri,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 위치정보 저장 성공');
      },
    );
  }

  /// 회원 정보 조회 API
  /// `POST /api/members/get`
  Future<MemberResponse> getMemberInfo() async {
    const String url = '${AppUrls.baseUrl}/api/members/get';
    late MemberResponse memberResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (responseData) {
        memberResponse = MemberResponse.fromJson(responseData);
        debugPrint('회원 정보 조회 성공: ${memberResponse.member?.nickname}');
      },
    );

    return memberResponse;
  }

  /// 회원 탈퇴 API
  /// `POST /api/members/delete`
  Future<bool> deleteMember() async {
    const String url = '${AppUrls.baseUrl}/api/members/delete';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 탈퇴 성공');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 탐색 범위 설정 API
  /// `POST /api/members/post/search-radius`
  Future<bool> saveSearchRadius(double searchRadiusInMeters) async {
    const String url = '${AppUrls.baseUrl}/api/members/post/search-radius';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'searchRadiusInMeters': searchRadiusInMeters.toString()},
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('탐색 범위 저장 성공: ${searchRadiusInMeters}m');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 회원 프로필 변경 API
  /// `POST /api/members/profile/update`
  Future<void> updateMemberProfile(String nickname, String profileUrl) async {
    const String url = '${AppUrls.baseUrl}/api/members/profile/update';

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'nickname': nickname.toString(), 'profileUrl': profileUrl.toString()},
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 프로필 변경 성공: $nickname');
      },
    );
  }

  /// 타인 프로필 조회 API
  /// `POST /api/members/get/profile`
  Future<MemberResponse> getMemberProfile(String memberId) async {
    const String url = '${AppUrls.baseUrl}/api/members/get/profile';
    late MemberResponse memberResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'memberId': memberId},
      isAuthRequired: true,
      onSuccess: (responseData) {
        memberResponse = MemberResponse.fromJson(responseData);
        debugPrint('타인 프로필 조회 성공: ${memberResponse.member?.nickname}');
      },
    );

    return memberResponse;
  }

  /// 차단 회원 목록 조회 API
  /// `POST /api/members/block/get`
  Future<MemberResponse> getBlockedMembers() async {
    const String url = '${AppUrls.baseUrl}/api/members/block/get';
    late MemberResponse memberResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (responseData) {
        memberResponse = MemberResponse.fromJson(responseData);
        debugPrint('차단 회원 목록 조회 성공');
      },
    );

    return memberResponse;
  }

  /// 회원 차단 API
  /// `POST /api/members/block/post`
  Future<bool> blockMember(String blockTargetMemberId) async {
    const String url = '${AppUrls.baseUrl}/api/members/block/post';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'blockTargetMemberId': blockTargetMemberId},
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 차단 성공: $blockTargetMemberId');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 회원 차단 해제 API
  /// `POST /api/members/block/delete`
  Future<bool> unblockMember(String blockTargetMemberId) async {
    const String url = '${AppUrls.baseUrl}/api/members/block/delete';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'blockTargetMemberId': blockTargetMemberId},
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 차단 해제 성공: $blockTargetMemberId');
        isSuccess = true;
      },
    );
    return isSuccess;
  }

  /// 알림 수신 설정 업데이트 API (개별 알림 타입별)
  /// `POST /api/members/notification/update`
  /// 변경하지 않는 필드는 null로 전달
  Future<MemberResponse> updateNotificationSetting({
    bool? isMarketingInfoAgreed,
    bool? isActivityNotificationAgreed,
    bool? isChatNotificationAgreed,
    bool? isContentNotificationAgreed,
    bool? isTradeNotificationAgreed,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/members/notification/update';
    late MemberResponse memberResponse;

    final Map<String, dynamic> fields = {
      if (isMarketingInfoAgreed != null) 'isMarketingInfoAgreed': isMarketingInfoAgreed.toString(),
      if (isActivityNotificationAgreed != null) 'isActivityNotificationAgreed': isActivityNotificationAgreed.toString(),
      if (isChatNotificationAgreed != null) 'isChatNotificationAgreed': isChatNotificationAgreed.toString(),
      if (isContentNotificationAgreed != null) 'isContentNotificationAgreed': isContentNotificationAgreed.toString(),
      if (isTradeNotificationAgreed != null) 'isTradeNotificationAgreed': isTradeNotificationAgreed.toString(),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        memberResponse = MemberResponse.fromJson(responseData);
        debugPrint('알림 수신 설정 업데이트 성공');
      },
    );

    return memberResponse;
  }
}
