import 'package:flutter/material.dart';
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/services/response_printer.dart';
import 'package:romrom_fe/services/send_authenticated_request.dart';

/// `POST /api/members/post/category/preferences` 사용자 카테고리 요청
Future<void> postCategoryPreferences(List selectedCategory) async {
  const String url = '$baseUrl/api/members/post/category/preferences';
  try {
    await sendAuthenticatedRequest(
      url: url,
      body: {
        "memberProductCategories": selectedCategory,
      },
      onSuccess: (responseData) async {
        responsePrinter(url, responseData);
        // TODO : 요청 후 로직
      },
    );
  } catch (error) {
    debugPrint("카테고리 post 실패: $error");
    throw Exception('Error during log-out: $error');
  }
}
