import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  /// 기본 HTTP 요청 타임아웃 (15초)
  static const Duration defaultTimeout = Duration(seconds: 15);

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

  /// 요청별 타임아웃을 지정해 전송한다.
  /// send(헤더 수신)와 stream.toBytes()(body 읽기) 전 구간에 동일 deadline을 적용한다.
  Future<http.StreamedResponse> sendWithTimeout(http.BaseRequest request, Duration timeout) async {
    final startTime = DateTime.now();
    final deadline = startTime.add(timeout);
    final requestId = request.hashCode.toRadixString(16).padLeft(8, '0');

    debugPrint("====================================");
    debugPrint("[${_formatTime(startTime)}] [${request.method}] ${request.url} [uid: $requestId]");
    request.headers.forEach((key, value) {
      debugPrint("   $key: $value");
    });

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
      final streamedResponse = await _inner
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              final duration = DateTime.now().difference(startTime).inMilliseconds;
              debugPrint("[${_formatTime(DateTime.now())}] [Timeout] ${request.url} [uid: $requestId]");
              debugPrint("   [Duration] ${duration}ms (${timeout.inSeconds}s 초과)");
              debugPrint("====================================");
              throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
            },
          );

      // body 읽기에 남은 deadline 시간만큼 타임아웃 적용
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        debugPrint("[${_formatTime(DateTime.now())}] [Timeout] ${request.url} [uid: $requestId]");
        debugPrint("   [Duration] ${duration}ms (${timeout.inSeconds}s 초과 — body read)");
        debugPrint("====================================");
        throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
      }
      final responseBytes = await streamedResponse.stream.toBytes().timeout(
        remaining,
        onTimeout: () {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          debugPrint("[${_formatTime(DateTime.now())}] [Timeout] ${request.url} [uid: $requestId]");
          debugPrint("   [Duration] ${duration}ms (${timeout.inSeconds}s 초과 — body read)");
          debugPrint("====================================");
          throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
        },
      );
      final responseString = utf8.decode(responseBytes, allowMalformed: true);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => sendWithTimeout(request, defaultTimeout);

  // 시간을 HH:mm:ss.SSS 형식으로 포맷팅
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}"
        ".${time.millisecond.toString().padLeft(3, '0')}";
  }
}
