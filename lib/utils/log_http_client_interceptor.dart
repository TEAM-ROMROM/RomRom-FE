import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  /// 기본 HTTP 요청 타임아웃 (10초)
  /// 파일 업로드 등 장시간 작업은 별도 클라이언트 사용 권장
  static const Duration defaultTimeout = Duration(seconds: 10);

  LoggingHttpClient(this._inner);

  String _prettyJson(dynamic json) {
    if (json == null) return 'null';
    try {
      var encoder = const JsonEncoder.withIndent('  ');
      if (json is String) {
        try {
          var decoded = jsonDecode(json);
          return encoder.convert(decoded);
        } catch (_) {
          return json;
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
    debugPrint("====================================");
    debugPrint("[${_formatTime(startTime)}] [${request.method}] ${request.url} [uid: $requestId]");
    request.headers.forEach((key, value) {
      debugPrint("   $key: $value");
    });

    // 요청 본문 로깅
    if (request is http.MultipartRequest) {
      debugPrint("   [Form Fields]");
      debugPrint("   ${_prettyJson(request.fields)}");

      if (request.files.isNotEmpty) {
        debugPrint("   [Files] ${request.files.map((f) => f.filename).toList()}");
      }
    } else if (request is http.Request && request.body.isNotEmpty) {
      debugPrint("   [Body]");
      debugPrint("   ${_prettyJson(request.body)}");
    }

    try {
      // 실제 요청 전송 (타임아웃 적용)
      final streamedResponse = await _inner
          .send(request)
          .timeout(
            defaultTimeout,
            onTimeout: () {
              final duration = DateTime.now().difference(startTime).inMilliseconds;
              debugPrint("[${_formatTime(DateTime.now())}] [Timeout] ${request.url} [uid: $requestId]");
              debugPrint("   [Duration] ${duration}ms (${defaultTimeout.inSeconds}s 초과)");
              debugPrint("====================================");
              throw TimeoutException('HTTP 타임아웃: ${request.url}', defaultTimeout);
            },
          );
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // 전체 응답 본문 읽기
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes, allowMalformed: true);

      // 응답 본문 출력
      debugPrint("[${_formatTime(DateTime.now())}] [${streamedResponse.statusCode}] ${request.url} [uid: $requestId]");
      debugPrint("   [Duration] ${duration}ms");

      if (responseString.isNotEmpty) {
        try {
          debugPrint("   [Response]");
          debugPrint("   ${_prettyJson(responseString)}");
        } catch (e) {
          debugPrint("   [Response] $responseString");
        }
      }
      debugPrint("====================================");

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
      debugPrint("[${_formatTime(DateTime.now())}] [Error] ${request.url} [uid: $requestId]");
      debugPrint("   [Duration] ${duration}ms");
      debugPrint("   $error");
      debugPrint("====================================");
      rethrow;
    }
  }

  // 시간을 HH:mm:ss.SSS 형식으로 포맷팅
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}"
        ".${time.millisecond.toString().padLeft(3, '0')}";
  }
}
