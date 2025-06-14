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

  /// 이용약관 동의 API
  /// `POST /api/members/terms`
  Future<bool> saveTermsAgreement({
    required bool isMarketingInfoAgreed,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/members/terms';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {
        'isMarketingInfoAgreed': isMarketingInfoAgreed.toString(),
      },
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
    const String url =
        '${AppUrls.baseUrl}/api/members/post/category/preferences';
    bool isSuccess = false;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {
        "preferredCategories":
            preferredCategories.map((e) => e.toString()).join(','),
      },
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
}
