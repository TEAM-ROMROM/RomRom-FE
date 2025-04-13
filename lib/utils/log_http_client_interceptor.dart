import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient(this._inner);

  String _prettyJson(dynamic json) {
    if (json == null) return 'null';
    try {
      var encoder = const JsonEncoder.withIndent('  ');
      if (json is String) {
        // 문자열이 JSON인지 확인
        try {
          var decoded = jsonDecode(json);
          return encoder.convert(decoded);
        } catch (_) {
          return json; // JSON이 아닌 문자열은 그대로 반환
        }
      } else {
        return encoder.convert(json);
      }
    } catch (e) {
      return json.toString();
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final requestId = request.hashCode.toRadixString(16).padLeft(8, '0');

    // 요청 로깅
    debugPrint("📤 [${request.method}] #$requestId ${request.url} 📤");
    request.headers.forEach((key, value) {
      debugPrint("   $key: $value");
    });

    // 요청 본문 로깅
    if (request is http.MultipartRequest) {
      debugPrint("   📋 Form Fields:");
      debugPrint("   ${_prettyJson(request.fields)}");
      
      if (request.files.isNotEmpty) {
        debugPrint("   📎 Files: ${request.files.map((f) => f.filename).toList()}");
      }
    } else if (request is http.Request && request.body.isNotEmpty) {
      debugPrint("   📋 Body:");
      debugPrint("   ${_prettyJson(request.body)}");
    }

    try {
      // 실제 요청 전송
      final streamedResponse = await _inner.send(request);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      // 전체 응답 본문 읽기 (StreamedResponse는 한 번만 읽을 수 있음)
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes, allowMalformed: true);
      
      // 응답 본문 출력
      debugPrint("📥 [${streamedResponse.statusCode}] #$requestId ${request.url} (${duration}ms) 📥");
      
      if (responseString.isNotEmpty) {
        try {
          debugPrint("   📋 Response:");
          debugPrint("   ${_prettyJson(responseString)}");
        } catch (e) {
          debugPrint("   📋 Response: $responseString");
        }
      }

      // 원본 StreamedResponse와 동일한 새 StreamedResponse 반환
      return http.StreamedResponse(
        Stream.value(responseBytes),
        streamedResponse.statusCode,
        contentLength: responseBytes.length,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
        request: streamedResponse.request,
      );
    } catch (error) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint("⚠️ Error #$requestId ${request.url} (${duration}ms): $error ⚠️");
      rethrow;
    }
  }
}
