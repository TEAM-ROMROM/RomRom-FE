// lib/services/apis/member_api.dart
  import 'package:flutter/material.dart';
  import 'package:romrom_fe/main.dart';
  import 'package:romrom_fe/models/apis/responses/member_response.dart';
  import 'package:romrom_fe/services/api_client.dart';

  class MemberApi {
    // 싱글톤 구현
    static final MemberApi _instance = MemberApi._internal();
    factory MemberApi() => _instance;
    MemberApi._internal();

    /// 회원 선호 카테고리 저장 API
    /// `POST /api/members/post/category/preferences`
    Future<bool> savePreferredCategories(List<int> preferredCategories) async {
      const String url = '$baseUrl/api/members/post/category/preferences';
      bool isSuccess = false;

      await ApiClient.sendRequest(
        url: url,
        fields: {
          "preferredCategories": preferredCategories.map((e) => e.toString()).join(','),
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
      String? fullAddress,
      String? roadAddress,
    }) async {
      const String url = '$baseUrl/api/members/post/location';

      final Map<String, dynamic> fields = {
        'longitude': longitude.toString(),
        'latitude': latitude.toString(),
        'siDo': siDo,
        'siGunGu': siGunGu,
        'eupMyoenDong': eupMyoenDong,
      };

      // 선택적 필드 추가
      if (ri != null) fields['ri'] = ri;
      if (fullAddress != null) fields['fullAddress'] = fullAddress;
      if (roadAddress != null) fields['roadAddress'] = roadAddress;

      await ApiClient.sendRequest(
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
      const String url = '$baseUrl/api/members/get';
      late MemberResponse memberResponse;

      await ApiClient.sendRequest(
        url: url,
        isAuthRequired: true,
        onSuccess: (responseData) {
          memberResponse = MemberResponse.fromJson(responseData);
          debugPrint('회원 정보 조회 성공: ${memberResponse.member?.nickname}');
        },
      );

      return memberResponse;
    }
  }