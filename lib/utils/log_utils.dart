import 'package:flutter/material.dart';

/// api 요청 응답 프린터
void responsePrinter(String url, Map<String, dynamic>? response) {
  debugPrint("👽----$url----👽"); // api 요청 주소 출력
  if (response != null) {
    // 응답 출력
    for (var entry in response.entries) {
      debugPrint('${entry.key} : ${entry.value}');
    }
  }
}

