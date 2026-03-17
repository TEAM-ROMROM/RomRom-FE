import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// @SecuredApi HMAC-SHA256 서명 생성 유틸리티
class SecuredApiUtils {
  /// Secret Key (.env에서 로드)
  static String get _secretKey => dotenv.get('SECURED_API_SECRET_KEY');

  /// 현재 타임스탬프 (밀리초) 생성
  static String generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// HMAC-SHA256 서명 생성 (Hex 인코딩)
  static String generateSignature(String timestamp) {
    final key = utf8.encode(_secretKey);
    final data = utf8.encode(timestamp);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(data);
    return digest.toString();
  }

  /// @SecuredApi 요청에 필요한 헤더 생성
  static Map<String, String> generateHeaders() {
    final timestamp = generateTimestamp();
    final signature = generateSignature(timestamp);
    return {'X-Timestamp': timestamp, 'X-Signature': signature};
  }
}
