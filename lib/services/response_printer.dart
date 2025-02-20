import 'package:flutter/material.dart';

/// api 요청 응답 프린터
void responsePrinter(String url, Map<String, dynamic> response) {
  debugPrint("👽----$url----👽");
  for (var entry in response.entries) {
    debugPrint('${entry.key} : ${entry.value}');
  }
}
