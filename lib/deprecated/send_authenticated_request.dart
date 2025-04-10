// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:romrom_fe/services/apis/rom_auth_api.dart';
// import 'package:romrom_fe/services/token_manager.dart';
// import 'package:romrom_fe/utils/log_utils.dart';
//
// /// ### 헤더에 토큰 포함한 API 요청 함수
// Future<void> sendAuthenticatedRequest({
//   required String url,
//   String method = 'POST',
//   Map<String, dynamic>? fields,
//   required Function(Map<String, dynamic>) onSuccess,
// }) async {
//   try {
//     // 토큰 불러옴
//     String? accessToken = await TokenManager().getAccessToken();
//     String? refreshToken = await TokenManager().getRefreshToken();
//     // TODO : exception enum 처리
//     if (accessToken == null || refreshToken == null) {
//       throw Exception('토큰이 없습니다.');
//     }
//
//     // 요청 보내기
//     http.Response response = await _sendMultipartRequest(
//       url: url,
//       method: method,
//       accessToken: accessToken,
//       fields: fields,
//     );
//
//     // statusCode `200` 대일 때 (200-299)
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       await _handleResponse(response: response, url: url, onSuccess: onSuccess);
//       return;
//     }
//
//     // statusCode == `401` 일 때 토큰 갱신 후 재시도
//     else if (response.statusCode == 401) {
//       bool isRefreshed = await refreshAccessToken();
//
//       // 토큰 재발급 된 경우
//       if (isRefreshed) {
//         accessToken = await TokenManager().getAccessToken();
//         refreshToken = await TokenManager().getRefreshToken();
//
//         response = await _sendMultipartRequest(
//           url: url,
//           method: method,
//           accessToken: accessToken!,
//           fields: fields
//         );
//
//         // statusCode `200` 번대일 때 (200-299)
//         if (response.statusCode >= 200 && response.statusCode < 300) {
//           await _handleResponse(
//               response: response, url: url, onSuccess: onSuccess);
//           return;
//         } else {
//           throw Exception(
//               'API 요청 실패 (토큰 갱신 후에도 실패): ${response.statusCode}, ${response.body}');
//         }
//       } else {
//         debugPrint("토큰 갱신 실패: 다시 로그인 필요");
//         throw Exception('Failed due to token refresh failure.');
//       }
//     } else {
//       throw Exception('API 요청 실패: ${response.statusCode}, ${response.body}');
//     }
//   } catch (error) {
//     throw Exception('API 요청 중 오류 발생: $error');
//   }
// }
//
// /// ### 실제 api 요청을 처리하는 함수
// Future<http.Response> _sendMultipartRequest({
//   required String url,
//   required String method,
//   required String accessToken,
//   Map<String, dynamic>? fields,
//   Map<String, List<File>>? files,
// }) async {
//   var request = http.MultipartRequest(method, Uri.parse(url));
//   request.headers['Authorization'] = 'Bearer $accessToken';
//
//   // 일반 필드 추가
//   if (fields != null) {
//     fields.forEach((key, value) {
//       request.fields[key] = value.toString();
//     });
//   }
//
//   // 파일 추가
//   if (files != null) {
//     for (var entry in files.entries) {
//       for (var file in entry.value) {
//         var stream = http.ByteStream(file.openRead());
//         var length = await file.length();
//         var multipartFile = http.MultipartFile(
//           entry.key,
//           stream,
//           length,
//           filename: file.path.split('/').last,
//         );
//         request.files.add(multipartFile);
//       }
//     }
//   }
//
//   var streamedResponse = await request.send();
//   return await http.Response.fromStream(streamedResponse);
// }
//
// /// 응답 처리를 위한 헬퍼 함수
// Future<void> _handleResponse({
//   required http.Response response,
//   required String url,
//   required Function(Map<String, dynamic>) onSuccess,
// }) async {
//   // statusCode `200` 대일 때 (200-299)
//   if (response.statusCode >= 200 && response.statusCode < 300) {
//     // 응답 비어있으면 오류나서 따로 처리
//     if (response.body.isNotEmpty) {
//       final responseData = jsonDecode(response.body);
//       responsePrinter(url, responseData);
//       onSuccess(responseData);
//     } else {
//       responsePrinter(url, null);
//       debugPrint('서버 응답이 비어 있음. 빈 객체로 처리합니다.');
//       onSuccess({});
//     }
//     return;
//   }
//
//   throw Exception('API 요청 실패: ${response.statusCode}, ${response.body}');
// }
