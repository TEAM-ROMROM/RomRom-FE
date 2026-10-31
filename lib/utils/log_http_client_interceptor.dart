import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/utils/client_platform_header.dart';
import 'package:romrom_fe/utils/log_masking.dart';

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  /// 기본 HTTP 요청 타임아웃 (15초)
  static const Duration defaultTimeout = Duration(seconds: 15);

  LoggingHttpClient(this._inner);

  /// 요청별 타임아웃을 지정해 전송한다.
  /// send(헤더 수신)와 stream.toBytes()(body 읽기) 전 구간에 동일 deadline을 적용한다.
  Future<http.StreamedResponse> sendWithTimeout(http.BaseRequest request, Duration timeout) async {
    // 서버 API 요청 공통 헤더 (앱 플랫폼, #949)
    ClientPlatformHeader.addTo(request);
    final startTime = DateTime.now();
    final deadline = startTime.add(timeout);
    final requestId = request.hashCode.toRadixString(16).padLeft(8, '0');
    // 로그 출력 게이트 (릴리즈 빌드 차단)
    final isLoggingEnabled = LogMasking.isHttpLoggingEnabled;
    // 타임아웃 로그 3건 공통 (로깅 꺼짐이면 문자열 조립 생략)
    void logTimeout(String durationSuffix) {
      if (!isLoggingEnabled) return;
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint("[${_formatTime(DateTime.now())}] [Timeout] ${request.url} [uid: $requestId]");
      debugPrint("   [Duration] ${duration}ms (${timeout.inSeconds}s 초과$durationSuffix)");
      debugPrint("====================================");
    }

    // 요청 로그 (헤더·폼 필드 마스킹, 본문 길이 제한)
    if (isLoggingEnabled) {
      debugPrint("====================================");
      debugPrint("[${_formatTime(startTime)}] [${request.method}] ${request.url} [uid: $requestId]");
      LogMasking.maskHeaders(request.headers).forEach((key, value) {
        debugPrint("   $key: $value");
      });

      if (request is http.MultipartRequest) {
        debugPrint("   [Form Fields]");
        debugPrint("   ${LogMasking.formatBody(jsonEncode(request.fields))}");

        if (request.files.isNotEmpty) {
          debugPrint("   [Files] ${request.files.map((f) => f.filename).toList()}");
        }
      } else if (request is http.Request && request.body.isNotEmpty) {
        debugPrint("   [Body]");
        debugPrint("   ${LogMasking.formatBody(request.body)}");
      }
    }

    try {
      final streamedResponse = await _inner
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              logTimeout('');
              throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
            },
          );

      // body 읽기에 남은 deadline 시간만큼 타임아웃 적용
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        logTimeout(' — body read');
        throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
      }
      final responseBytes = await streamedResponse.stream.toBytes().timeout(
        remaining,
        onTimeout: () {
          logTimeout(' — body read');
          throw TimeoutException('HTTP 타임아웃: ${request.url}', timeout);
        },
      );
      // 로깅 꺼짐이면 응답 디코딩·로그 문자열 조립 생략
      if (isLoggingEnabled) {
        final responseString = utf8.decode(responseBytes, allowMalformed: true);
        final duration = DateTime.now().difference(startTime).inMilliseconds;

        debugPrint(
          "[${_formatTime(DateTime.now())}] [${streamedResponse.statusCode}] ${request.url} [uid: $requestId]",
        );
        debugPrint("   [Duration] ${duration}ms");

        if (responseString.isNotEmpty) {
          debugPrint("   [Response]");
          debugPrint("   ${LogMasking.formatBody(responseString)}");
        }
        debugPrint("====================================");
      }

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
      if (isLoggingEnabled) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        debugPrint("[${_formatTime(DateTime.now())}] [Error] ${request.url} [uid: $requestId]");
        debugPrint("   [Duration] ${duration}ms");
        debugPrint("   $error");
        debugPrint("====================================");
      }
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
