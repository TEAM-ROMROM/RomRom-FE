import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 거래 관련 API
class TradeApi {
  // 싱글톤 구현
  static final TradeApi _instance = TradeApi._internal();

  factory TradeApi() => _instance;

  TradeApi._internal();

  /// 거래 요청 API
  /// `POST /api/trade/post`
  Future<void> requestTrade(TradeRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/trade/post';

    final Map<String, dynamic> fields = {
      'takeItemId': request.takeItemId,
      'giveItemId': request.giveItemId,
      if (request.tradeOptions != null && request.tradeOptions!.isNotEmpty)
        'tradeOptions': request.tradeOptions!.join(','),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('거래 요청 성공');
      },
    );
  }

  /// 거래 요청 취소 API
  /// `POST /api/trade/delete`
  Future<void> cancelTradeRequest(TradeRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/trade/delete';

    final Map<String, dynamic> fields = {
      'takeItemId': request.takeItemId,
      'giveItemId': request.giveItemId,
      if (request.tradeOptions != null && request.tradeOptions!.isNotEmpty)
        'tradeOptions': request.tradeOptions!.join(','),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('거래 요청 취소 성공');
      },
    );
  }

  /// 받은 거래 요청 목록 조회 API
  /// `POST /api/trade/get/received`
  Future<PageTradeResponse> getReceivedTradeRequests(
      TradeRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/trade/get/received';
    late PageTradeResponse tradeResponse;

    final Map<String, dynamic> fields = {
      'takeItemId': request.takeItemId,
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        // 여기서는 호출되지 않음 - 아래에서 직접 처리
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      tradeResponse = PageTradeResponse.fromJson(responseData);
      debugPrint('받은 거래 요청 목록 조회 성공');
    } else {
      throw Exception('받은 거래 요청 목록 조회 실패: ${response.statusCode}');
    }

    return tradeResponse;
  }

  /// 보낸 거래 요청 목록 조회 API
  /// `POST /api/trade/get/sent`
  Future<PageTradeResponse> getSentTradeRequests(TradeRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/trade/get/sent';
    late PageTradeResponse tradeResponse;

    final Map<String, dynamic> fields = {
      'giveItemId': request.giveItemId,
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        // 여기서는 호출되지 않음 - 아래에서 직접 처리
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      tradeResponse = PageTradeResponse.fromJson(responseData);
      debugPrint('보낸 거래 요청 목록 조회 성공');
    } else {
      throw Exception('보낸 거래 요청 목록 조회 실패: ${response.statusCode}');
    }

    return tradeResponse;
  }

  /// 거래율 기준 정렬된 목록 조회 API
  /// `POST /api/trade/get/rate`
  Future<TradeResponse> getSortedTradeRate(TradeRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/trade/get/rate';
    late TradeResponse tradeResponse;

    final Map<String, dynamic> fields = {
      'takeItemId': request.takeItemId,
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        // 여기서는 호출되지 않음 - 아래에서 직접 처리
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      tradeResponse = TradeResponse.fromJson(responseData);
      debugPrint('거래율 기준 정렬된 목록 조회 성공');
    } else {
      throw Exception('거래율 기준 정렬된 목록 조회 실패: ${response.statusCode}');
    }

    return tradeResponse;
  }
}
