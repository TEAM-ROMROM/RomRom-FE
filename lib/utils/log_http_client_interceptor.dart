import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    // 요청 직전 로깅
    debugPrint("👽 Request: ${request.method} ${request.url} 👽");
    request.headers.forEach((key, value) {
      debugPrint("   $key: $value");
    });
    if (request is http.MultipartRequest) {
      debugPrint("   Fields: ${request.fields}");
      debugPrint("   Files: ${request.files.map((f) => f.filename).toList()}");
    }

    try {
      final response = await _inner.send(request);
      final duration = DateTime.now().difference(startTime);
      debugPrint("👽 Response from ${request.url} received in ${duration.inMilliseconds} ms 👽");
      return response;
    } catch (error) {
      debugPrint("👽 Error during request to ${request.url}: $error 👽");
      rethrow;
    }
  }
}
