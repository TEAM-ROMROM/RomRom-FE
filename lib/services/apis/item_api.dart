import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class ItemApi {
  // 싱글톤 구현
  static final ItemApi _instance = ItemApi._internal();

  factory ItemApi() => _instance;

  ItemApi._internal();

  /// 물품 등록 API
  /// `POST /api/item/post`
  Future<ItemResponse> postItem(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/post';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'itemName': request.itemName,
      'itemDescription': request.itemDescription,
      'itemCategory': request.itemCategory,
      'itemCondition': request.itemCondition,
      'itemTradeOptions': request.itemTradeOptions?.join(','),
      'itemPrice': request.itemPrice?.toString(),
      'itemCustomTags': request.itemCustomTags?.join(','),
    };

    // 타입 안전하게 파일 처리
    Map<String, List<File>>? fileMap;
    if (request.itemImages != null && request.itemImages!.isNotEmpty) {
      fileMap = {'itemImages': request.itemImages!};
    }

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      files: fileMap,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 등록 성공: ${itemResponse.item?.itemName}');
      },
    );

    return itemResponse;
  }

  /// 좋아요 등록/취소 API
  /// `POST /api/item/like/post`
  Future<ItemResponse> postLike(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/like/post';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'itemId': request.itemId,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('좋아요 상태 변경 성공: ${itemResponse.likeStatus}');
      },
    );

    return itemResponse;
  }

  /// 물품 목록 조회 API
  /// `POST /api/item/get`
  Future<ItemResponse> getItems(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/get';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint(
            '물품 목록 조회 성공: ${itemResponse.itemDetailPage?.content?.length}개');
      },
    );

    return itemResponse;
  }

  /// AI 가격 예측 API
  /// `POST /api/item/price/predict`
  Future<int> pricePredict(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/price/predict';
    int predictedPrice = 0;

    final Map<String, dynamic> fields = {
      'itemName': request.itemName,
      'itemDescription': request.itemDescription,
      'itemCondition': request.itemCondition,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        // 응답이 int형이거나 Map형일 수 있으므로 안전하게 처리
        if (responseData is int) {
          predictedPrice = responseData;
        } else if (responseData is Map<String, dynamic>) {
          predictedPrice = responseData['data'] ?? 0;
        } else {
          predictedPrice = 0;
        }
        debugPrint('AI 가격 예측 성공: $predictedPrice');
      },
    );

    return predictedPrice;
  }
}
