import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_type.dart';
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/services/api/send_authenticated_request.dart';
import 'package:romrom_fe/utils/common_util.dart';

/// ### POST : `/api/members/post/category/preferences` 사용자 카테고리 api 요청
Future<void> postCategoryPreferences(
    BuildContext context, List<int> selectedCategory) async {
  const String url = '$baseUrl/api/members/post/category/preferences';
  try {
    await sendAuthenticatedRequest(
      url: url,
      body: {
        "preferredCategories":
            selectedCategory.map((e) => e.toString()).join(','),
      },
      onSuccess: (responseData) async {
        // home 화면으로 이동
        context.navigateTo(
            screen: const HomeScreen(), type: NavigationType.pushReplacement);
      },
    );
  } catch (error) {
    debugPrint("카테고리 post 실패: $error");
    throw Exception('Error during postCategory: $error');
  }
}
